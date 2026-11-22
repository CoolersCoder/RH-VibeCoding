#!/usr/bin/env perl
# vibe lint engine. Usage:
#   lint.pl --rules <file> --base <dir> [--self-test] [--list <file-with-paths>] [-- files...]
# Paths are relative to --base (absolute paths under it are relativised). Exit 0 clean, 1 violations,
# 2 malformed rules file.
use strict;
use warnings;
use Getopt::Long qw(GetOptions);

my ($rules_file, $base, $self_test, $list);
GetOptions('rules=s' => \$rules_file, 'base=s' => \$base, 'self-test' => \$self_test, 'list=s' => \$list)
    or exit 2;
my @files = @ARGV;

sub malformed {
    print STDERR "vibe lint: malformed rules file $rules_file: $_[0]\n";
    exit 2;
}

sub glob2re {
    my ($g) = @_;
    my $has_slash = index($g, '/') >= 0;
    my $re = '';
    my $depth = 0;
    my @c = split //, $g;
    for (my $i = 0; $i < @c; $i++) {
        my $ch = $c[$i];
        if ($ch eq '*') {
            if ($i + 1 < @c && $c[$i + 1] eq '*') {
                if ($i + 2 < @c && $c[$i + 2] eq '/') { $re .= '(?:.*/)?'; $i += 2; }
                else { $re .= '.*'; $i += 1; }
            } else { $re .= '[^/]*'; }
        } elsif ($ch eq '?') { $re .= '[^/]';
        } elsif ($ch eq '{') { $re .= '(?:'; $depth++;
        } elsif ($ch eq '}' && $depth > 0) { $re .= ')'; $depth--;
        } elsif ($ch eq ',' && $depth > 0) { $re .= '|';
        } else { $re .= quotemeta($ch); }
    }
    $re .= ')' x $depth;
    $re = '(?:.*/)?' . $re unless $has_slash;
    return "(?:$re)";
}

sub globs_re {
    my @g = grep { length } split /\s+/, ($_[0] // '');
    return undef unless @g;
    my $alt = join('|', map { glob2re($_) } @g);
    return qr/^(?:$alt)$/;
}

sub allowed {
    my ($line, $id) = @_;
    return $line =~ /lint:allow\s+\Q$id\E\s+\S/ ? 1 : 0;
}

sub parse_rules {
    open my $fh, '<:raw', $rules_file or malformed("cannot read file");
    my @lines = <$fh>;
    close $fh;
    my (@blocks, $cur);
    my $n = 0;
    my $lineno = 0;
    my %single = map { $_ => 1 } qw(rule files exclude pattern message max_lines);
    for my $raw (@lines) {
        $lineno++;
        my $l = $raw;
        $l =~ s/\r?\n\z//;
        if ($l =~ /^\s*$/) { $cur = undef; next; }
        next if $l =~ /^\s*#/;
        if (!defined $cur) {
            $n++;
            $cur = { n => $n, line => $lineno, bad => [], ok => [] };
            push @blocks, $cur;
        }
        my ($key, $val);
        if ($l =~ /^\s*(bad|ok):( ?)(.*)$/) {
            push @{ $cur->{$1} }, $3;
            next;
        } elsif ($l =~ /^\s*([a-z_]+)\s*:\s*(.*?)\s*$/) {
            ($key, $val) = ($1, $2);
        } else {
            malformed("block $n (line $lineno): expected 'key: value', got '$l'");
        }
        malformed("block $n (line $lineno): unknown field '$key'") unless $single{$key};
        malformed("block $n (line $lineno): duplicate field '$key'") if exists $cur->{$key};
        $cur->{$key} = $val;
    }
    my %seen;
    for my $b (@blocks) {
        my $label = "block $b->{n}" . (defined $b->{rule} ? " (rule: $b->{rule})" : " (line $b->{line})");
        malformed("$label: missing 'rule'") unless defined $b->{rule} && length $b->{rule};
        malformed("$label: invalid rule id") unless $b->{rule} =~ /^[A-Za-z0-9_.-]+$/;
        malformed("$label: duplicate rule id") if $seen{ $b->{rule} }++;
        malformed("$label: missing 'files'") unless defined $b->{files} && length $b->{files};
        malformed("$label: missing 'message'") unless defined $b->{message} && length $b->{message};
        my $has_p = defined $b->{pattern} && length $b->{pattern};
        my $has_m = defined $b->{max_lines};
        malformed("$label: needs either 'pattern' or 'max_lines'") unless $has_p || $has_m;
        malformed("$label: 'pattern' and 'max_lines' are mutually exclusive") if $has_p && $has_m;
        if ($has_m) {
            malformed("$label: max_lines must be a positive integer") unless $b->{max_lines} =~ /^[1-9][0-9]*$/;
        } else {
            my $re = eval { qr/$b->{pattern}/ };
            malformed("$label: bad pattern: $@") unless defined $re;
            $b->{re} = $re;
            malformed("$label: pattern rules need at least one 'bad:' example") unless @{ $b->{bad} };
        }
        $b->{inc} = globs_re($b->{files});
        malformed("$label: 'files' has no globs") unless defined $b->{inc};
        $b->{exc} = globs_re($b->{exclude});
    }
    return \@blocks;
}

my $rules = parse_rules();

if ($self_test) {
    my $failed = 0;
    for my $r (@$rules) {
        my @problems;
        if (defined $r->{re}) {
            for my $b (@{ $r->{bad} }) {
                push @problems, "bad example does not match: '$b'" unless $b =~ $r->{re};
                my $s = "$b // lint:allow $r->{rule} self-test";
                push @problems, "allow comment does not suppress: '$b'"
                    unless allowed($s, $r->{rule});
            }
            for my $o (@{ $r->{ok} }) {
                push @problems, "ok example matches: '$o'" if $o =~ $r->{re};
            }
        }
        if (@problems) { print "FAIL $r->{rule}: " . join('; ', @problems) . "\n"; $failed = 1; }
        else { print "ok $r->{rule}\n"; }
    }
    exit($failed ? 1 : 0);
}

my @paths;
if (defined $list) {
    open my $lf, '<', $list or exit 0;
    while (my $p = <$lf>) { chomp $p; push @paths, $p if length $p; }
    close $lf;
}
push @paths, @files;

my %seen_path;
my @viol;
for my $p (@paths) {
    my $rel = $p;
    if ($rel =~ m{^/}) {
        next unless index($rel, "$base/") == 0;
        $rel = substr($rel, length($base) + 1);
    }
    $rel =~ s{^\./}{};
    next if $seen_path{$rel}++;
    my @apply = grep { $rel =~ $_->{inc} && !(defined $_->{exc} && $rel =~ $_->{exc}) } @$rules;
    next unless @apply;
    my $full = "$base/$rel";
    next unless -f $full;
    open my $fh, '<:raw', $full or next;
    my @lines = <$fh>;
    close $fh;
    for my $ri (0 .. $#apply) {
        my $r = $apply[$ri];
        if (defined $r->{re}) {
            my $ln = 0;
            for my $line (@lines) {
                $ln++;
                next unless $line =~ $r->{re};
                next if allowed($line, $r->{rule});
                push @viol, [$rel, $ln, $r->{n}, $r->{rule}, $r->{message}];
            }
        } else {
            my $max = $r->{max_lines};
            if (@lines > $max) {
                my $line = $lines[$max];
                next if allowed($line, $r->{rule});
                push @viol, [$rel, $max + 1, $r->{n}, $r->{rule}, $r->{message}];
            }
        }
    }
}

@viol = sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] || $a->[2] <=> $b->[2] } @viol;
for my $v (@viol) { print "$v->[0]:$v->[1]: [$v->[3]] $v->[4]\n"; }
exit(@viol ? 1 : 0);
