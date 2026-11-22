# 06 · Skills、Subagents、插件

## 放哪里？一张表决定（Claude Code features-overview）

| 内容 | 放 | 加载时机 |
|---|---|---|
| 每个会话都要的事实和“永远这样做” | `CLAUDE.md`（≤200 行） | 每次启动 |
| 只在某些文件相关的知识或陷阱 | `.claude/rules/*.md` + `paths:` | 碰到匹配文件时 |
| 多步流程、清单、参考资料 | skill | 被调用或被判定相关时（只有名字和描述常驻） |
| 会刷屏的旁支任务、并行工作、专门角色 | subagent | 被委派时，在独立上下文里跑 |
| 每次都必须发生的事 | hook | 事件触发 |
| 外部系统（数据库、工单、浏览器） | MCP | 连接时 |
| 跨 repo / 跨人复用以上内容 | 插件 + marketplace | 启用时（描述常驻） |

## 写好一个 skill

```markdown
---
name: deploy-staging
description: Deploy the current branch to staging and smoke-test it. Use when asked to deploy, ship to staging, or test on staging.
argument-hint: "[service]"
disable-model-invocation: true      # 有副作用 → 只能手动 /deploy-staging
allowed-tools: Bash(make deploy-staging:*) Bash(curl:*)
---

# Deploy to staging
1. …（编号步骤，每步有可检查的结果）
## Done when
- …（完成标准）
## Never
- …（红线）
```

要点：
- **description 决定会不会被用上**：开头就写请求里会出现的词。`description` + `when_to_use` 合计在列表里截断到 1536 字符。skill 一多，有的描述会被整段截掉，所以越短越好。
- **有副作用的**（部署、发消息、改数据）加 `disable-model-invocation: true`。
- **参考资料型**（API 文档、协议说明）保持可自动调用，正文写清“这份资料来自哪、可能过期、用前先验证”。
- **项目里的 `verify` skill 名字别改**：Claude Code 会在每次提交前自动运行项目里名为 `verify` 或 `simplify` 的 skill（插件里的同名 skill 不算）。
- 用 `paths:` 让某个 skill 只在相关文件上自动出现，例如迁移 skill 只匹配 `**/migrations/**`。
- 用 `context: fork` 让一个重活在 subagent 里跑，主对话只收结论。
- 正文可用 `$ARGUMENTS`。`` !`git diff HEAD` `` 这类动态注入会在加载时执行命令并内联输出。
- 正文 ≤ ~150 行。参考资料放同目录的其它文件，正文里写“需要时读 `reference.md`”。

### vibe-core 自带的 skills

全部 `disable-model-invocation: true`：只能手动调用，所以**不占上下文**（Lauren 的“从零开始”）。只有项目自己的 `verify` skill 可以被自动调用。

| Skill | 调用 | 用途 |
|---|---|---|
| `vibe-setup` | `/vibe-core:vibe-setup` | 跑 `vibe doctor`，把项目升到下一级 |
| `create-verification` | `/vibe-core:create-verification` | 生成项目验证 skill（启动 / 体检 / 驱动 / 证据 / 清理）+ 小控制 CLI + 功能地图，并端到端证明一次 |
| `maintain-verification` | `/vibe-core:maintain-verification` | 对照代码和实际运行审计验证 skill，结果为 clean / changed / blocked；发现产品回归只报告，不改地图掩盖 |
| `investigate` | `/vibe-core:investigate <问题>` | 只读调查：先复述，再查 how 和 why，每个结论注明依据 |
| `architect` | `/vibe-core:architect <要做的事>` | 用代码规划：画两种形状、用原型回答开放问题、选一个；设计错了就推倒 |
| `blast-radius` | `/vibe-core:blast-radius` | 找出 diff 之外会坏的地方，用跑代码的方式证明“它为什么安全” |
| `review` | `/vibe-core:review [base]` | 两遍严格审查：正确性 + 结构；作者不评审自己；PR 适合人审吗 |
| `deslop` | `/vibe-core:deslop` | 清理 diff 里的 AI 冗余，不改行为 |
| `correct` | `/vibe-core:correct <错误>` | 把重复纠正变成强制规则（架构 > 类型 > lint > 测试 > 文字） |
| `garden` | `/vibe-core:garden [时间范围]` | 园丁：抽读最近合并的代码 → 写进 weeds 队列 → 归并根因 → 改苗床 |
| `reflect` | `/vibe-core:reflect` | 从本次会话提炼教训，提议修改 skill / 规则，批准后才改 |
| `sharpen` | `/vibe-core:sharpen <任务>` | 不做任务，只把你的提示词改写成专家会怎么提的版本 |
| `overnight` | `/vibe-core:overnight <目标>` | 无人值守约定：先赢得信任、完成谓词、TSV 决策日志、审计后交接 |

项目级模板（`vibe init` 生成）：`verify`（L1）、`run-app`（L2）。

## 写好一个 subagent

```markdown
---
name: reviewer
description: Strict read-only reviewer. Use before declaring a non-trivial change done.
tools: Read, Grep, Glob, Bash
model: inherit
---
You are … （系统提示词：角色、步骤、输出格式、不做什么）
```

- subagent **看不到你的对话**：委派时把需求原文、约束、已经排除的东西、要它交回什么，全部写进任务里。
- 只读角色就只给只读工具。
- description 要短：所有 subagent 描述合计超过 15k token 会告警。
- 适合交给 subagent 的：大范围搜索、读几十个文件找规律、跑长日志分析、并行检查多个包、独立审查。
- 不适合的：需要和你来回确认的设计决策（它不能问你）。

### vibe-core 自带的 subagents

- **reviewer**：只读严格审查，输出按严重度排序的发现，每条带 `path:line`。
- **advisor**：更强模型的第二意见（`model: opus`），读你的简报给出 verdict + 理由，不改文件。只在三个节点用：重大决定前、同一问题修两次仍失败时、宣布完成前。

## 插件：把一套做法带到所有 repo

```
my-plugin/
├── .claude-plugin/plugin.json     # {"name": "...", "version": "...", "description": "..."}
├── skills/<name>/SKILL.md         # 调用时带命名空间：/my-plugin:<name>
├── agents/<name>.md
├── hooks/hooks.json               # 命令里用 "${CLAUDE_PLUGIN_ROOT}/hooks/x.sh"
├── bin/                           # 插件启用时加进 Claude 的 PATH
└── .mcp.json
```

- 本地开发：`claude --plugin-dir ./my-plugin`，改完 `/reload-plugins`；用 `claude plugin validate .` 校验。
- 分发：一个含 `.claude-plugin/marketplace.json` 的 git 仓库就是 marketplace，`claude plugin marketplace add <git-url 或本地路径>`。
- 成本：启用的插件每一轮都占“名字 + 描述”的上下文，不用的就禁用。
- 本工具包就是这个结构：`plugin/vibe-core/` + 根目录的 `.claude-plugin/marketplace.json`。

## 新任务用新的 subagent（pstack）

修复轮、后续任务、重试，默认都交给**新的** subagent，带上原始简报、之后的所有指令、上一个 agent 的报告和分支。只有在需要的状态还活在旧 agent 里（它的 checkout、未提交的改动、它还在跑的进程）时才复用旧的。你对每个 subagent 的产出负责：自己看 diff，用自己的话写总结。

## skill 本身也要被验证

- skill 改动影响以后的每个会话，要当实验对待：拿同一个任务，跑改动前和改动后的版本盲测比较，然后自己读输出。不同意判官的结论时，先怀疑评分标准。
- 不要在任务进行中顺手修 skill，单独提交。
- 模型变强后要删行：具体命令挪进 CLI，只留步骤和判断。

## 多模型

- 日常执行用主力模型；advisor 用更强的模型；大量机械性阅读（Explore）可以用更便宜的模型（自定义一个名叫 `Explore` 的 subagent 并设 `model: haiku`，会覆盖内置的）。
- 重要设计可以让不同模型各给一版方案，再综合（pstack `/arena` 的做法）。
