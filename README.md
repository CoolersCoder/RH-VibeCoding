# RH-VibeCoding（Claude Code 版）

一套**跟技术栈无关、按需逐级升级**的 AI 编程工作框架。前端、后端、全栈、移动端都能用；单体 repo、monorepo、多 repo 工作区都能用。

它由两部分组成：

1. **准则**（`docs/`）：为什么这么做、什么时候加什么、怎么跟 agent 协作。
2. **工具包**（`plugin/vibe-core/`）：一个 Claude Code 插件。每台机器装一次，之后任何 repo 都可以用 `vibe init` 逐级接入：
   - `vibe` 命令行工具
   - 通用 skills / subagents
   - 全局 hooks
   - 各技术栈的模板

> 重点参考：pstack 作者 **Lauren Tan（@poteto，SpaceXAI Principal Engineer，前 Cursor，React Compiler 核心成员）** 的方法论，见 `docs/10-masters.md`；以及 Anthropic 官方《Best practices for Claude Code》、Simon Willison、Karpathy。
>
> 来源：`cursor/plugins` 官方插件仓库（pstack、cursor-team-kit、thermos、continual-learning、advisor、agent-compatibility、orchestrate 等），加上 Claude Code 官方文档（memory、skills、hooks、sub-agents、plugins、large-codebases、features-overview）。另有在 RH-Music（iOS）项目上落地时踩过的坑。出处见 `docs/00-sources.md`。

---

## 一句话理念

> **人负责判断，agent 负责执行，仓库负责记忆和强制。**
>
> 1. **验证是限速步骤**：先让 agent 能自己启动、驱动、看到结果，再谈并行和自主。
> 2. **最好的规则在代码里**：架构和类型 > lint > 测试 > 文字。每纠正两次同样的错，就改“苗床”，让它再也长不出来。
> 3. **从零开始**：不预装，观察失败，重复了才固化。信任是一级一级挣来的。

---

## 五分钟上手

```bash
# 1. 每台机器做一次：注册插件市场，安装 vibe-core
claude plugin marketplace add CoolersCoder/RH-VibeCoding
claude plugin install vibe-core@rh-vibecoding
#    （也可以在 Claude Code 会话里用 /plugin 操作。改框架本身时，用本地 clone 注册：
#     claude plugin marketplace add ~/Desktop/RH-VibeCoding；调试可用 claude --plugin-dir ~/Desktop/RH-VibeCoding/plugin/vibe-core）

# 2. 想在终端里直接用 vibe 命令（Claude 会话里插件会自动把它加进 PATH）：
git clone https://github.com/CoolersCoder/RH-VibeCoding.git ~/Desktop/RH-VibeCoding   # 已有本地 clone 可跳过
export PATH="$HOME/Desktop/RH-VibeCoding/plugin/vibe-core/bin:$PATH"   # 写进 ~/.zshrc

# 3. 在任意项目里
cd your-project
vibe init --level 1          # 自动识别技术栈；不会覆盖已有文件
vibe doctor                  # 看当前等级和“下一步做什么”
vibe verify                  # 跑验证闭环
```

然后在 Claude Code 里打开项目，说一句：`/vibe-core:vibe-setup` 帮我把这个项目升到下一级。

---

## 渐进等级（详见 `docs/02-levels.md`）

不要一上来就全配。每一级都有明确的**触发条件**，碰到了再升。

| 等级 | 名称 | 解决什么 | 什么时候升 | 核心产物 |
|---|---|---|---|---|
| **L0** | 起步 | agent 知道项目是什么、怎么跑 | 新项目第一天 | `CLAUDE.md`（≤200 行）、`.claude/settings.json`、`.gitignore` |
| **L1** | 验证闭环 | agent 能自己启动、驱动、拿证据；“做完了”要有证据 | 第一次需要 agent 改代码之前 | `.vibe/verify.conf` + `vibe verify`；`verify` skill（启动 / 体检 / 驱动 / 证据 / 清理 + 小 CLI + 功能地图，由 `/vibe-core:create-verification` 生成） |
| **L2** | 按需知识 | 上下文不被无关内容挤占 | CLAUDE.md 超过 200 行，或某块代码有专属规矩 | `.claude/rules/*.md`（`paths:` 按路径加载）、领域 skills、`run-app` 配方 |
| **L3** | 强制执行 | 同样的错不再犯第二次 | 同一个纠正说了两遍 | `.vibe/lint-rules`（带正反例自测）、编辑后 lint hook、收尾 verify 提醒 |
| **L4** | 自主与规模 | 长任务、并行、少盯着 | 想让 agent 连续工作数小时 / 多个并行 | reviewer/advisor subagent、截图/驱动 app 的工具、通宵跑的约定、worktree |
| **L5** | 团队与多仓 | 多个 repo / 多人共享一套做法 | 第二个 repo 要同一套配置 | 工作区 hub、插件分发、持续学习、定期审计 |

---

## 三种项目形态（详见 `docs/03-topologies.md`）

| 形态 | 怎么接入 | 要点 |
|---|---|---|
| **单体 repo** | `vibe init` | 根 `CLAUDE.md` + `.claude/rules/area-*.md` 按路径加载 |
| **monorepo** | `vibe init --topology monorepo` | 根放全局规则，每个包有自己的 `CLAUDE.md` 和 `.vibe/verify.conf`；`vibe verify` 只验证受影响的包 |
| **多 repo 工作区** | 在一个新的 hub 目录里 `vibe init --topology workspace --repos "../api ../web"` | hub 的 `CLAUDE.md` 写清跨 repo 契约；`launch.sh` 用 `--add-dir` 一次打开所有 repo；`vibe verify` 逐个 repo 验证 |

---

## 目录

```
RH-VibeCoding/
├── README.md                 ← 你在这里
├── docs/
│   ├── 00-sources.md         学到了什么、出自哪里
│   ├── 01-principles.md      核心原则（为什么）
│   ├── 02-levels.md          L0–L5 逐级设置手册（做什么、做到什么算完成）
│   ├── 03-topologies.md      单体 / monorepo / 多 repo
│   ├── 04-verification.md    验证闭环与各技术栈对照表
│   ├── 05-enforcement.md     lint 规则与 hooks
│   ├── 06-skills-agents.md   skills、subagents、插件怎么写
│   ├── 07-playbooks.md       日常工作流与提示词
│   ├── 08-memory.md          记忆维护（CLAUDE.md 不腐烂）
│   ├── 09-pitfalls.md        踩过的坑
│   └── 10-masters.md         Lauren Tan / Anthropic / Simon Willison / Karpathy 的做法，以及框架据此做的修正
├── plugin/vibe-core/         Claude Code 插件（装一次，所有 repo 可用）
│   ├── bin/vibe              CLI：init / verify / lint / state / doctor
│   ├── lib/                  lint 引擎等
│   ├── hooks/                Bash 危险命令守卫、编辑后 lint、收尾验证提醒、会话开场状态
│   ├── skills/               13 个手动调用的 skill：vibe-setup、create-/maintain-verification、investigate、architect、
│   │                         blast-radius、review、deslop、correct、garden、reflect、sharpen、overnight
│   ├── agents/               reviewer、advisor
│   ├── templates/            CLAUDE.md、verify skill、rules、工作区等模板
│   └── stacks/               node-ts / python / go / rust / swift / jvm / generic 的 verify.conf + lint-rules
├── .claude-plugin/marketplace.json   让本仓库成为插件市场（rh-vibecoding）
└── tests/run.sh              工具包自测
```

agent 读的文件（模板、skills）用英文写，模型遵循得最稳；给人看的准则用中文。想全中文也可以，`CLAUDE.md` 可以直接用中文写。
