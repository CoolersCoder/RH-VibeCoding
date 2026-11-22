# 05 · 强制执行：lint 规则与 hooks

> “CLAUDE.md 是上下文，不是强制配置。要无论 Claude 怎么想都拦住某个动作，用 hook。”（Claude Code memory 文档）
> “指令是症状，结构才是治疗。”（pstack Encode Lessons in Structure）

## 修复层级（`/correct`）

一个错误**发生过两次**才算“一类”。按这个顺序找能用的最高一层：

| 层 | 做法 | 例子 |
|---|---|---|
| 1. 架构 | 每份状态只有一个归属、每件事只有一种做法；删掉旧做法和会被照抄的死代码 | 两份重复的“取音源回退链”合并成一个 `Resolver`，其它地方根本没得调 |
| 2. 类型 | 让坏状态写不出来 | 用枚举代替字符串状态；`NonEmptyArray`；branded ID |
| 3. lint 规则 | `.vibe/lint-rules` 加一条，报错信息**直接写修法** | “`AsyncImage(` → use CachedArtworkImage — the one place artwork is fetched” |
| 4. 检查 | 纯逻辑配独立检查 / 单元测试 | 排序算法 17 个断言 |
| 5. 文字 | 写进 `.claude/rules/*.md`，附失败例子 | 只适用于需要判断、无法机械检查的事 |

做完要**证明**：新检查在真实的历史错误（或忠实复制品）上失败，在修好的代码上通过。然后更新根 `CLAUDE.md` 的“规则 → 强制”表。

## 结构优先：最好的规则在代码里

Lauren Tan（organic architecture）：靠 code review 执行风格指南的时代，被“无数只拿键盘的猴子”终结了。为 agent 设计的代码库需要**硬约束**：

- **目录即边界**：例如 `src/main/**` 和 `src/renderer/**`（Electron）、`domain/` 和 `infra/`、`server/` 和 `client/`。配一个 import 检查拒绝跨边界引用。可以用语言自带的工具：ESLint `no-restricted-imports` / `import/no-restricted-paths`、dependency-cruiser、Go 的 `internal/` 包、Rust 的模块可见性、Python 的 import-linter。也可以先用一条 vibe 规则：
  ```text
  rule: renderer-no-main-imports
  files: src/renderer/**/*.{ts,tsx}
  pattern: from ['"](\.\./)+main/|from ['"]@/main/
  message: renderer code must not import main-process code; expose it through the preload bridge (src/preload/api.ts)
  bad: import { db } from "../../main/db"
  ok: import { api } from "../preload/api"
  ```
- **强类型和编译器诊断**：让非法状态无法表示；外部数据在边界解析成类型，内部信任类型。这比任何文字规则都有效。
- **代码库是范例**：agent 会照抄最近的例子。坏模式（为绕开设计错配而加的定时器、“为什么需要这个”的注释）留着，就等于一条指令。用 `/vibe-core:garden` 定期清理。

## `.vibe/lint-rules` 格式

规则之间用空行分隔，`#` 开头是注释：

```text
rule: no-console-log
files: src/**/*.ts src/**/*.tsx
exclude: src/**/*.test.ts
pattern: \bconsole\.log\(
message: use the logger in src/lib/log.ts (structured, stripped in prod)
bad: console.log("user", user)
ok: logger.info("user", { id: user.id })

rule: file-too-long
files: src/**/*.ts src/**/*.tsx
max_lines: 1000
message: file over 1000 lines; split it before adding more
```

- `pattern` 是 Perl 正则，**逐行**匹配；`max_lines` 检查文件长度。
- `files` / `exclude` 是相对 `.vibe/` 所在目录的 glob，支持 `**`、`*`、`?`、`{a,b}`。不带 `/` 的 glob（例如 `*.ts`）匹配任意目录下的同名文件。只检查 git 跟踪的和未被忽略的文件。
- `bad:` / `ok:` 可以写多行。`vibe lint --self-test` 会证明每条规则抓住 bad、放过 ok。**没有 bad 例子的规则不允许存在。**
- 例外：在那一行写 `lint:allow <rule> <理由>`，理由不能为空。
- 写规则的经验：
  - 报错信息 = 问题 + 正确做法 + 去哪看。agent 会照着报错改。
  - 用 `exclude` 把规则文件本身、测试夹具、文档排除掉。
  - 如果模式已经在代码里大量存在：先把存量修掉，或给合理的那几处加 `lint:allow`，再上规则。别让规则一上线就是一片红。
  - grep 做不到的（跨行、需要语法树），用语言自己的 linter 写插件规则（ESLint、ruff、SwiftLint 自定义规则），在 verify.conf 的 `step_lint` 里跑。

## vibe-core 自带的 hooks（插件级，所有 repo 生效）

| Hook | 事件 | 作用 | 什么时候是空操作 |
|---|---|---|---|
| `guard-bash.sh` | PreToolUse（Bash） | **拒绝**：`rm -rf ~ / ..`、向 main/master force push、`--no-verify`、`curl … \| sh`、`chmod -R 777`。**要求确认**：`git reset --hard`、`git clean -f`、`git branch -D`、`DROP/TRUNCATE`、`terraform destroy`、`kubectl delete` 等 | 正常命令 |
| `lint-edited.sh` | PostToolUse（Edit/Write） | 编辑后立刻对该文件跑 `vibe lint`，有违规就 `decision: block` 把报错交给 Claude | 项目没有 `.vibe/lint-rules` |
| `verify-reminder.sh` | Stop | WATCH 范围有改动、且没有通过 `vibe verify` 时提醒一次（`stop_hook_active` 防死循环）；agent 可以一句话说明为什么不需要 | 没有 `.vibe/verify.conf`；或已验证；或没改动 |
| `session-start.sh` | SessionStart | 把 `vibe doctor --brief`（等级、验证是否新鲜、下一步）和当前分支注入上下文 | 项目没有 `.vibe/` |

**写 hook 的规矩**（Claude Code hooks 文档 + 实战）：
- stdout **只输出 JSON**，别的文本（包括 shell profile 的 echo）会让 JSON 失效。
- 一定要快：编辑后的 hook 应在 1 秒内完成。慢的检查放进 verify。
- 内部出错 → 静默 `exit 0`。hook 坏了不能把会话卡死。
- Stop hook 必须检查 `stop_hook_active`，否则 Claude 会被无限要求继续。
- 字段上限 1 万字符，lint 输出太长要截断。
- 测试 hook：把手写的 JSON 通过管道喂给脚本，用 `jq -e .` 校验输出。

## 确定性 vs 非确定性（Claude 官方）

- prompt、CLAUDE.md、skill 是模型**决定**要不要照做；hook、deny 规则、托管设置是 harness **必须执行**。
- 一条 CLAUDE.md 规则你越写越强调还是被漏掉，就把它变成 hook。反过来，只是偏好的事，别写成 hook。
- 不再需要用全大写 / IMPORTANT 来强调，那样反而会让模型过度应用这条规则。
- 收尾强制检查的标准写法：Stop hook 执行 `pnpm tsc --noEmit 1>&2 || exit 2`。exit 2 会把 stderr 交回给 Claude，让它继续修；连续 8 次拦截后 harness 会放行。vibe-core 的 `verify-reminder.sh` 是“只提醒一次”的温和版，需要硬性拦截就在项目 settings 里加上面这条。

## 项目级额外 hooks（按需加在 `.claude/settings.json`）

- **格式化**：PostToolUse 跑 `prettier --write` / `ruff format` / `gofmt -w` 处理刚编辑的文件，省掉一类无意义的 lint 来回。
- **保护文件**：PreToolUse 拒绝编辑 `generated/`、迁移历史、lock 文件，报错写明“改 X 然后跑 Y”。
- **会话结束提议更新记忆**：Stop hook 拿到 transcript 路径，按节奏（如每 10 轮且间隔 2 小时）提示 Claude 运行记忆更新流程（见 `08-memory.md`）。

## 权限（`.claude/settings.json`）

- `permissions.allow`：把 `vibe verify`、`vibe lint`、项目脚本放进白名单，减少审批打断。
- `permissions.deny`：`Read(./.env*)`、`Read(./**/*.pem)`、`Read(./**/secrets/**)`、生成物和依赖目录。
- 后台运行的 agent 拿不到审批，需要的命令必须提前放进 allow，否则全部被拒（实战踩过）。
