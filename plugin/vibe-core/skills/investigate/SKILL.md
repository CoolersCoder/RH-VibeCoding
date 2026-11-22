---
name: investigate
description: Read-only investigation of how something works and why it was built that way, with every claim tied to evidence. Use for "how does X work", "why is Y like this", "are we sure", "where is Z handled", or "read this thread and tell me the real issue".
argument-hint: "<question>"
disable-model-invocation: true
---

# Investigate

Read-only. Don't edit code. Answer `$ARGUMENTS`.

1. **Restate** the question in your own words and plain language, and what would count as an answer. For a noisy source (a long thread, a vague report), compress it into the underlying problem first and stop there if the user asked only for that — misreadings are cheapest to fix here. Don't adopt the user's hypothesis as a premise; test it like any other.
2. **How** — trace from the entry point (route, command, UI action, job) to the implementation. Name files and functions with `path:line`. For broad searches, delegate to an Explore subagent and keep only the findings.
3. **Why** — when the question is about intent or a regression: `git log -L :<func>:<file>`, `git log -S '<string>'`, `git blame -w`, linked PRs/issues. Name the commit and the constraint it was responding to.
4. **Verify the claim that matters** — if the answer hinges on runtime behaviour, run the smallest command that shows it (a test, a script, a log line) instead of inferring.
5. **Answer** first, then the evidence.

```text
Answer: <2–5 sentences>
Evidence:
- path:line — what it shows
- commit abc123 — why
Confidence: confirmed by <reading/running> | inferred (and the check that would confirm it)
```

Never present a hypothesis as a finding. If two explanations fit, say which evidence would tell them apart.
