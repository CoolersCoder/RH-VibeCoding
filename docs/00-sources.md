# 00 · 学到了什么、出自哪里

这份框架是三类来源合起来的。这里只记“学到的东西 → 落在框架哪里”。细节见后续各章。

> **说明**：第一版只读了 `cursor/plugins` 的一部分。后来补读了 pstack 的 `poteto-mode`、全部 playbook 和指南，pstack 作者 Lauren Tan 本人的文章（《Loops You Can Trust》《The Complete Guide to pstack》Pt.1 / Pt.2、organic architecture、gardener），Anthropic 官方的《Best practices for Claude Code》，以及 Simon Willison、Karpathy 的观点，并据此修正了框架。补读的内容和修正清单见 **`10-masters.md`**。

## A. `github.com/cursor/plugins`（Cursor 官方插件仓库）

这个仓库约 90% 是第三方 SaaS 连接器（Gmail、Salesforce 等），与工程方法无关。真正有价值的是 Cursor 团队自己写的十几个工程流程插件。

| 插件 | 学到的 | 落在 |
|---|---|---|
| **pstack**（React 核心成员 poteto） | “想快，先深。”写得更少、质量更高，才能放心并行。用**原则名**来引导 agent，一个短语胜过一段话：“prove it works”“subtract before you add”。24 条原则每条一个 skill，执行时要说明“哪条原则改变了哪个决定” | `01-principles.md`、`07-playbooks.md` |
| pstack `/correct` + “Encode Lessons in Structure” | 重复犯的错按优先级修：**架构消除 > 类型约束 > 报错里直接写明修法的 lint > 测试 > 文档最后**。新检查必须证明它在真实的历史错误上会失败。维护“规则 → 由什么强制”表 | `05-enforcement.md`、`skills/correct` |
| pstack “Guard the Context Window” | 大量阅读交给 subagent，主对话只留结论；常驻上下文越少越好 | `02-levels.md` L2、`06-skills-agents.md` |
| pstack 的 playbook 路由 | 一个入口 skill 读懂需求后选 playbook：调查 / bug 修复 / 性能 / 功能 / 重构 / 原型 / 通宵 | `07-playbooks.md` |
| pstack `/sharpen`、`/in-your-own-words`、`/how`、`/why` | 先让 agent 用自己的话复述问题（误解在复述里暴露，只花一条消息）；先查“怎么运作”，再查“为什么变成这样” | `skills/sharpen`、`skills/investigate` |
| **cursor-team-kit** `verify-this` | 验证不是复述 diff：把说法改写成**可证伪**的形式，用同一环境采集**改动前 / 改动后**，比较原始产物，只给一个结论 `VERIFIED / NOT VERIFIED / INCONCLUSIVE`，不软化负面结果 | `04-verification.md`、`templates/.../verify` |
| cursor-team-kit `control-ui` / `control-cli` | 用脚本驱动真实界面拿证据（截图、可访问性快照、日志），优先复用项目已有的工具 | `04-verification.md` “杠杆” |
| cursor-team-kit `deslop` | 删掉 AI 生成的冗余：多余注释、不该有的防御性 try/catch、为绕过类型的强转、深层嵌套 | `skills/deslop` |
| cursor-team-kit `make-pr-easy-to-review`、`new-branch-and-pr`、`loop-on-ci` | PR 可审：TL;DR 与真实 diff 一致，机械改动与逻辑改动分开，改写历史前先确认，并核对 tree 未变 | `07-playbooks.md` |
| cursor-team-kit `workflow-from-chats` | 从聊天记录里抽出可复用偏好，按置信度（强 / 中 / 弱 / 矛盾）决定写成 skill、规则、文档或不写 | `08-memory.md` |
| **thermos**（极严代码审查） | 一个 PR 不能把文件从 1000 行以下推到 1000 行以上；不接受散落在无关流程里的特例 if；找“code judo”：能让整块分支消失的重构 | `skills/review`、lint `max_lines` |
| **continual-learning** | Stop hook 按节奏（N 轮 + M 分钟 + transcript 有更新）触发记忆更新；只处理新增的 transcript；**每节最多 12 条**、原地更新、去重；不写一次性细节和秘密 | `08-memory.md` |
| **advisor** | 关键节点咨询更强（或不同）的模型：重大决定前、同一错误修了两次还不行时、宣布完成前。每个节点最多一次，一个任务超过约 4 次说明该拆了 | `agents/advisor.md`、`07-playbooks.md` |
| **agent-compatibility** | 评估一个 repo 对 agent 友不友好：能不能启动、能不能用轻量方式验证小改动、文档写的命令是否真能跑 | `vibe doctor`、`02-levels.md` |
| **orchestrate** | 大任务拆成 planner / worker / verifier，结构化交接（handoff），失败要有交接说明 | `07-playbooks.md` L4 |
| **ralph-loop** | 自我迭代循环需要明确的完成条件和停止机制 | `skills/overnight` |
| **dyl-stack** visual judge | UI 对齐用评分表逐项比（结构 / 字体 / 间距 / 素材 / 控件），任意一项不过就算没过 | `04-verification.md` |
| **cli-for-agent** | 给 agent 用的 CLI：有示例的 help、可管道、错误信息可操作、幂等、支持 dry-run | `bin/vibe` 的设计 |

## B. Claude Code 官方文档（code.claude.com/docs，2026-11 版）

| 主题 | 要点 | 落在 |
|---|---|---|
| **memory** | 启动时加载工作目录及其所有上级目录的 `CLAUDE.md`；**子目录里的 `CLAUDE.md` 按需加载**（读写该目录文件时才加载）。每个文件目标 **< 200 行**。`@import` 只是方便组织，不省上下文。`.claude/rules/*.md` 加 `paths:` 前置信息后按路径加载。`CLAUDE.local.md` 是个人的、不提交。auto memory（`MEMORY.md`）只加载前 200 行 / 25 KB。CLAUDE.md 只是上下文，不是强制配置，要强制就用 hook | `02-levels.md`、`08-memory.md` |
| `/init`、`/doctor`、`/doctor prompt-audit` | `/init` 生成初版 CLAUDE.md；`/doctor` 检查安装、扩展的上下文开销，并提议把常驻指导迁成 skills；`prompt-audit` 找过时 / 冲突 / 引用不存在文件的指令 | `08-memory.md` |
| **skills** | `.claude/skills/<name>/SKILL.md`，正文只在被使用时加载。前置信息：`description`（与 `when_to_use` 合计在列表里截断到 1536 字符）、`disable-model-invocation`（只能手动 `/name` 调用）、`allowed-tools`、`context: fork`（在 subagent 里跑）、`agent`、`paths`（按文件触发）、`argument-hint`；正文可用 `$ARGUMENTS` 和 `` !`cmd` ``（动态注入命令输出）。**项目里名为 `verify` 或 `simplify` 的 skill，Claude 在每次提交前会自动运行**（插件里的同名 skill 不算） | `06-skills-agents.md`、`templates/.../verify` |
| 内置 `/run`、`/verify`、`/run-skill-generator` | 让 agent 启动并驱动应用来确认改动，而不是只看测试；配方可以录成项目 skill | `04-verification.md` |
| **hooks** | 事件：`SessionStart`、`UserPromptSubmit`、`PreToolUse`（可拦截）、`PostToolUse`、`Stop`、`SubagentStop`、`PreCompact` 等。`PostToolUse`/`Stop` 用 `{"decision":"block","reason":…}` 把反馈交给 Claude；`PreToolUse` 用 `permissionDecision: allow/deny/ask`。`Stop` 输入里的 `stop_hook_active` 用来防死循环。stdout 只能输出 JSON；单个字段上限 1 万字符 | `05-enforcement.md`、`plugin/vibe-core/hooks` |
| **sub-agents** | `.claude/agents/*.md`（name / description / tools / model + 系统提示词）。独立上下文，只回传摘要。内置 Explore / Plan（只读）。description 要短，所有描述合计超 15k token 会告警 | `06-skills-agents.md` |
| **plugins** | `.claude-plugin/plugin.json` + `skills/`、`agents/`、`hooks/hooks.json`（用 `${CLAUDE_PLUGIN_ROOT}`）、`.mcp.json`、`bin/`（启用时加入 PATH）。marketplace = 一个含 `.claude-plugin/marketplace.json` 的目录或仓库。启用的插件每轮都占名字 + 描述的上下文 | 本工具包的形态 |
| **large-codebases** | monorepo：根 CLAUDE.md 放全局规则，每个包放自己的；用 `claudeMdExcludes` 排除无关包；用 `permissions.deny` 的 `Read(./**/dist/**)` 挡住生成物；`worktree.sparsePaths`；跨包或跨 repo 用 `--add-dir`，要加载对方的 CLAUDE.md 需设置 `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`（`additionalDirectories` 设置只给文件访问权）；包内放 `.claude/skills/`；规模大了用插件集中管理 | `03-topologies.md` |
| **features-overview** | 按触发条件逐步加功能：同一错误犯两次 → CLAUDE.md；同一提示词反复输入 → skill；同一流程第三次粘贴 → skill；旁支任务刷屏 → subagent；每次都要自动发生 → hook；第二个 repo 要同一套 → 插件 | `02-levels.md` 的“触发条件”列 |

## C. 实战教训（RH-Music，iOS / SwiftUI）

- 59 KB 的 CLAUDE.md 被截断，最重要的“已知 bug 模式”在后半段，新会话根本读不到。
- 把文档放进会被打包进产物的源码目录（Xcode 同步目录会把 `.md` 拷进 app 包，导致构建失败）。
- 文档里写行数、“以前是 X 现在是 Y”，很快就过期。
- demo 数据里没有真实图片，把一个布局 bug 藏住了三轮。
- 用 Release 构建做性能测量，而测试开关在 Release 里被编译掉了，第一轮数据全部作废。
- 测试 target 是空的，`xcodebuild test` 必失败，却没人写下来。
- 后台 agent 拿不到权限审批，所有命令被拒。

全部写进了 `09-pitfalls.md`。
