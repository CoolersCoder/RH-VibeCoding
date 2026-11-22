# 10 · 大佬们怎么说：Lauren Tan（poteto）与其他一线实践者

> 写这一章的原因：第一版框架只读了 `cursor/plugins` 的一部分，包括 pstack 的 README、原则索引和 recipes，以及 continual-learning、thermos、advisor 等。pstack 核心的 `poteto-mode`、22 个 playbook、指南第 1–7、9 章，还有作者本人的文章，第一版都没读。补读之后，框架里有几处重心放错了，本章记录这些修正。

## Lauren Tan 是谁

- GitHub `@poteto`。现任 SpaceXAI Principal Engineer，负责 Grok Bot 和 Cursor（随 Cursor 被收购加入）。2026 年 3–8 月在 Cursor，参与 Cursor 3 的 Agents Window。之前在 Meta 做 React Compiler 核心、React Server Components 原型，更早在 Netflix 做工程经理。
- `cursor/plugins` 里的 **pstack** 是她写的。按她的说法，团队每周用这些 skills 上万次，她本人每月往生产环境合并 2000–2500 个 PR，而且代码质量保持在高位。
- 一手资料：《How I Use Cursor》（2026-05）、《Loops You Can Trust》（2026-06）、"organic architecture"（2026-07）、"every team needs a gardener"（2026-08）、《The Complete Guide to pstack》Pt.1（验证）和 Pt.2（研究、规划、架构），以及 AI Engineer 大会演讲《All Code Is Slop (Except Mine)》。

## 她的核心观点（按“对框架影响多大”排序）

### 1. 验证是限速步骤（The three-minute egg）
她借用 Andy Grove《High Output Management》里的早餐工厂：煮蛋要三分钟，整盘早餐只能围着蛋排期，把吐司做快没有用。写代码的 agent 已经很快了，**复现和验证才是长杆**，因为它们一直要等人。

- 在搭任何循环之前，先教会 agent 验证自己的工作。没有验证，并行和循环只会更快地产出“复利式的垃圾”。
- **验证 skill 要当关键基础设施来维护**，她甚至建议给它排值班。好的验证 skill 由三部分组成：
  1. **验证 skill 本身**：包含 Launch（从空数据启动到“可用”）、Doctor（这个实例值不值得驱动）、Drive（用真实选择器 / 命令驱动）、Evidence（截什么证据、放哪、证明标准）、Cleanup（只杀自己启动的进程，证据保留）。
  2. **一个小 CLI**：`doctor`、`snapshot`、`screenshot`、`send`、`trace`… 机械的部分交给代码，agent 只做判断，不必每次“重建世界”。
  3. **Feature Map**：每个功能一页，写清它是什么、用户怎么到达、怎么用 CLI 驱动、有哪些坑。她称之为“物化的记忆”，需要每天维护（`/maintain-verification-skill`）。
- 技术栈本身就是 skill 的一部分：Web / Electron 用 Chrome DevTools Protocol，iOS 用模拟器。运行时太“薄”就自己造调试工具，甚至换一个更容易调试的技术栈，“这是不公平的优势”。
- 有人问：“验证 skill 说绿了，产品还是错的怎么办？”她答：“observe, diagnose, fix the skill.”

### 2. 想快，先深（Go deep first），信任阶梯
- 并行编排的价值来自“深”，不是“广”：在一两个问题上做 best-of-N、对抗式审查、多个 agent 同时复现同一个问题、按任务类型选模型。同时管 10 个问题的 agent，瓶颈是人自己的上下文。
- **信任阶梯**：先亲手管一个 agent → 发现自己在当“肉身代理”（手动在浏览器和 agent 之间搬运 trace）→ 有了验证 → 有了预备好的环境（类型、lint、约束，让简单的做法就是正确的做法）→ agent 自己合并代码，她第二天早上读提交记录。信任来自你对自己工具的信任。
- 把循环交给 agent 自主运行之前，四个条件必须先成立：
  1. 你自己亲手做过一次，知道好结果长什么样。
  2. agent 拥有和你一样的工具和信号。
  3. 每个阶段都能证明自己的工作，达不到标准就能叫停整条线。
  4. 你读过 transcript，并把反复出现的失败变成了工具、skill 或检查。

### 3. 最好的规则在代码里（organic architecture）
> “refactoring your codebase and choosing a tech stack with strong type systems/compiler diagnostics has far greater impact than AGENTS.md and tweaking your skills… the best rules are in your code.”

- 以前代码库靠“迁就最低水平的开发者”或者“code review 执行风格指南”来维持。现在“无数只拿键盘的猴子”让后者失效了。**为 agent 设计的代码库需要硬约束**，让最笨的 agent（和最笨的驾驶员）也能做出有意义的贡献。
- 例子：她团队的 Electron 框架 Dune 用目录结构区分主进程和渲染进程代码，再用**依赖检查拒绝跨边界 import**。agent 在 reviewer 看到之前就拿到一条可执行的报错。
- 纠正的价值排序：架构 / 数据结构消除 > lint 或测试让 CI 抓住 > skill 或规则 > 人在 diff 里抓。最后这一档她标的是 “ngmi”（没戏）。
- 反面例子：Cursor 桌面端里，agent 为了绕过 VS Code 命令式更新和 React 声明式渲染之间的错配，到处加定时器，每个定时器都配了一段“为什么需要”的注释。后来的 agent 照抄这个模式，界面越来越卡。**代码库给下一个 agent 树立的“范例”就是指令**，注释解释不了坏模式。

### 4. 园丁（The Gardener）
> “every team needs a gardener… the third isRecord this week, the lint suppressions creeping like ivy… every weed you pull becomes a rule, so it can't grow back.”

她每月 2500 个 PR 里，大部分是“园艺”：重构、新 lint 规则、新检查。流程如下：
1. agent 持续扫描代码里的禁用模式。
2. 发现的问题先记进队列，**不立刻修**，这样能看到单个修复会掩盖的模式。
3. 每隔几天读一遍队列，归并到共同的根因。
4. 每天细读一部分已合并的 PR（量太大，没法每道菜都尝）。
5. 多个 agent 走了同一条捷径，就“改苗床”：改 skills、约束、lint、类型。一次性的错误不用管。

### 5. 用代码做规划，而不是写长计划
- 两个最常见的错误：**接受 agent 的第一个设计**，以及**打磨一份没有任何代码检验过的计划**。“抽象计划只给你进展的错觉。”
- 规划的做法：
  - 原型：2–3 个方案放在一个切换器后面，用验证 skill 逐个驱动、截图、测时。
  - `/architect`：先把涉及的系统都追一遍，画出两种形状（类型、签名、模块边界），选“每份状态只有一个归属、每件事只有一种做法、调用方需要知道得最少”的那个。实现过程中如果同一个 workaround 反复出现、或者需要 `any` / 强转，说明设计错了，推倒重来。
  - 共享代码先写 README / 教程（README-driven）。
  - 多阶段计划**在设计定下来之后**才写，每一项都写明它的证明方式，工作落地后删掉。
- **不要对抽象计划做对抗式审查**：agent 会臆想出理论风险。对抗式审查（`/interrogate`）只保留“重跑命令能复现失败”的发现。

### 6. 先理解，再动手（监督一个比你聪明的人）
- 失败的两大根源：意图描述不足，以及缺乏做对这件事的上下文。
- **间接提示**：让 agent 读完原始材料（Slack 线程、issue），“用你自己的话、用大白话复述根本问题”，并且**先别说出你自己的猜测**，免得把它引偏。
- `/how` 查运行机制，`/why` 查历史原因（git、PR 评论、工单、文档、聊天、监控），`/teach` 把结论讲到你能质疑为止（“convince me”）。讲解本身也逼 agent 去读代码、拿证据。
- 过去的 transcript 是金矿：用 `/recall` 把上下文载入新会话。

### 7. Bug 修复要科学
- 先在真实界面上亲自复现，即使调试协议说“让用户复现”也不例外。复现不了就合成触发条件、收紧条件、加埋点。
- **二分排除假设**：每一轮选能砍掉最大问题空间的那个划分，拿运行时证据，排除。不猜。
- 每一行上线的代码都要能追溯到运行时证据。“可能有帮助”的双保险只是假设，不上线。证据否定了某个假设，就把它带来的改动回滚。
- git 历史里，失败的复现提交在修复之前。
- 验证要在**同一个界面**上做。单元测试只证明分支行为，证明不了 bug 不存在。

### 8. 评审者不能是作者
- “评判一个改动的 agent，绝不是写它的那个。”合并前派新的 verifier；队列模式下，每个 PR 有一个 owner，但 owner 不能凭自己的结论合并。
- 第二意见 = 同一份提示词交给另一家厂商的模型。
- 新任务默认交给**新的 subagent**，带上原始简报、所有后续指令和上一个 agent 的报告。只有在必要状态还活在旧 agent 里时才复用它。
- 删注释也交给没写这些注释的人（Comment Sicko）。作者会为自己的注释辩护。

### 9. 能叫停的流水线（外循环）
- 软件维护可以拆成几个阶段：分诊 → 复现（必须两次命中、带截图和视频）→ 修复（能写测试就写，最小修复，前后对比）→ 验证。**每个阶段都可以叫停整条线**：分诊判断是预期行为、复现不了、修复风险太大，都是有用的结果。**每个阶段都要交出证据。**
- 在最低价值的阶段抓缺陷：一个小组件上检查失败很便宜，一次巨型迁移落地后才发现回归就很贵。她的例子是 StyleX 迁移：先做了一个 40 万行的巨型 PR，吃了亏，之后改成自动化每天迁移一个叶子组件，覆盖三套主题、各种状态，做 computed style 前后对比。
- 时长不是完成条件：“工作 4 小时”什么都检查不了。要给 `/loop` 一个能通过或失败的谓词。平台期要换方法，不是停下，也绝不能悄悄放宽完成条件。

### 10. 从零开始，skill 会变短
> “start with nothing. don't download any plugins or skills. no AGENTS.md either. just prompt and observe the failure modes. codify them into skills when they repeat. even better, write lint rules or structure your codebase so certain mistakes are impossible. every chef has their own set of knives.”

- 先观察失败，重复了才固化。每个厨师都该有自己的刀。
- 模型变强之后，skill 应该**变短**：删掉具体命令（挪进 CLI），只保留流程和“什么时候做哪一步”的判断。
- 改 skill 要像做实验：盲测 eval（候选 agent 不知道自己在被评估，判官用中性标签评分）。不要在任务进行中顺手修 skill，单独开一个 PR。
- `/reflect`：会话结束后只保留“6 个月后仍然成立、会改变未来 agent 行为”的教训，按 Accepted / Rejected / Backlog 提议，等你批准再改。能用检查强制的进 Backlog，不写成文字。

### 11. 其他细节
- **坦率胜过附和**：“No is an acceptable answer.”被问要不要做某事时给出真实判断，该拒绝就拒绝。
- 回复：短的陈述句；每个断言附证据，或者标注“测得 / 推断 / 猜测”；**能自己跑的检查，绝不交给人去跑。**
- 量化数字的 7 个问题（`/benchmark-checklist`）：
  1. 什么在限制这个数字，为什么不是两倍？
  2. 每一侧都按生产方式调优了吗？
  3. 有没有突破物理极限？
  4. 有没有出错或返回错误输出？
  5. 交替运行能复现吗？给中位数和范围。
  6. 端到端重要吗？
  7. 工作真的发生在计时区间里吗？
- 影响范围（`/blast-radius`）：列调用方没用（grep 一秒就有）。要找出“这个改动之所以安全”所依赖的那一个事实，并**用跑真实代码的方式证明它**。
- PR 正文 ≤ 40 行，固定标题顺序：Why / What changed / Scope / Tradeoffs / Blast Radius / Verification。证据日志放文件或评论里，正文里链接过去。
- 决策日志是 TSV，每个决策一行（ts、phase、decision、why、evidence 指针、result），只追加不修改。结束时对照 transcript 审计一遍，再让另一家厂商的模型审阅，回复末尾附 “Attention” 一节。
- Dylan Gattey（dyl-stack）补了一条 “The Algorithm”（马斯克五步法）：先让需求不那么蠢 → 删除 → 优化 → 加速 → 自动化。设计前跑一遍，加 flag / 层 / 重试前再跑一遍。

---

## 其他一线实践者

### Anthropic 官方《Best practices for Claude Code》（2026）
- **确定性和非确定性要分清**：prompt、CLAUDE.md、skill 是模型“决定”的；hook、deny 规则、托管设置是 harness “必须执行”的。CLAUDE.md 里一条规则你越写越强调还是被漏掉，说明它该变成 hook。反过来，只是偏好的事就别写 hook。
- **只写它看不到的**：会议上的决定、只在某人脑子里的部署流程、集成测试要的环境变量。判断标准：“它能从代码里找到吗？它会去找吗？”两个都是“会”，就别写。
- **给它一个能跑出 pass/fail 的检查**：CLAUDE.md 里最有用的一行，就是运行这个检查的命令。严格程度可以逐级提高：写在 prompt 里 → `/goal`（另一个模型每轮检查条件）→ Stop hook（exit 2 把 Claude 送回去继续干）→ 没参与写代码的人审（`/code-review` 在一个新的 subagent 里审）。不管哪种，都要它给证据。
- 审查提示词里写上 “skip style”：被要求找问题的审查者总能找到点什么，全改的话代码会多出不必要的抽象和测试。
- `be ambitious` 仍然有用：Claude 默认按最小范围理解需求。
- 想不清楚需求时：“Interview me until you could write the spec, then write it to SPEC.md.”然后在新会话里照着 SPEC 实现。
- 无人值守前问五个问题：
  1. 它知道什么算完成吗？
  2. 能检查自己的工作吗？
  3. 允许碰什么？（权限、沙箱、worktree、能推送的分支）
  4. 什么能让它停下？（`--max-turns`、`--max-budget-usd`）
  5. 结果去哪、谁签字？
- **可以不再做的事**：
  - 用全大写 / IMPORTANT 强调。
  - 写 “think harder”（努力程度由 effort 设置控制）。
  - 写 “keep going / don't be lazy”（反而导致过度工作，改用 `/goal` 或 Stop hook）。
  - **在 CLAUDE.md 里描述架构和文件布局**（它自己会读仓库）。
  - 把“保护上下文窗口”当成用 subagent 的主要理由（现在多是 1M 上下文 + 自动压缩）。subagent 的价值在并行、隔离噪音、独立审查。
- 并行用 `claude -w <name>` 开 worktree，`.worktreeinclude` 复制 `.env` 这类被忽略的小文件。大规模机械改动用 `/batch` 拆成 5–30 个单元，每个单元一个 worktree。定时 / 事件触发用 `/loop`（会话内）或 `/schedule`（云端 routines）。这样跑之前先用分支保护规则护住 main。

### Simon Willison《Agentic Engineering Patterns》
- **Agentic engineering 和 vibe coding 是两件事**：vibe coding 是完全不看代码，agentic engineering 是专业工程师用 agent 放大自己已有的专长。
- **写代码现在很便宜**：旧的直觉（“这个太费事不值得写”）要重新校准。
- **囤积你会的东西**：每一个“这件事能做到”的结论，都配一段能跑的代码存下来。让 agent“把这两个现成的例子组合起来做个新东西”，是最有效的提示词之一。
- **反模式：把没审过的代码丢给同事**。PR 要你自己确认能工作、足够小、带上下文；agent 写的 PR 描述你也要审；附上手动测试记录、截图或视频，证明 reviewer 的时间不会被浪费。
- 红 / 绿 TDD；“First run the tests”：会话一开始先跑一遍测试，让 agent 知道测试在哪、怎么跑、当前什么状态。还有 agentic manual testing 和 linear walkthroughs（让 agent 逐行讲解一段代码）。

### Andrej Karpathy（2026 Sequoia Ascent）
- vibe coding 抬高了“地板”，人人都能做软件；agentic engineering 守住“天花板”，不降低专业软件原有的质量标准，你对软件的责任和以前一样，只是更快。
- 模型是“参差不齐的智能”（jagged），很强也会犯低级错误，所以需要工程纪律来协调。
- 2025 年 12 月是拐点：编程的单位从“敲代码”变成了委派更大的“宏操作”。

---

## 框架据此做了哪些修正

| 之前 | 现在 | 依据 |
|---|---|---|
| L1 只是“把 lint / test / build 串起来” | L1 的核心是**项目验证 skill**（Launch / Doctor / Drive / Evidence / Cleanup + Feature Map + 小 CLI），门禁只是其中一部分；新增 `create-verification` 和 `maintain-verification` 两个 skill | Lauren Pt.1、Loops You Can Trust |
| CLAUDE.md 模板有“架构一屏” | 改成“仓库里看不到的东西”：决定、流程、环境、外部约束、坑 | Claude Code best practices |
| 原则里强调“守护上下文窗口” | subagent 的价值改为并行、隔离噪音、**独立审查**；作者不能评审自己 | Claude 官方 + Lauren |
| 规划靠写计划 | 用代码规划：原型 → architect（两种形状）→ README-first → 设计定了才写多阶段计划；不对抽象计划做对抗式审查 | Lauren Pt.2 |
| “最好的规则”放在 rules 里 | 架构、类型、目录边界 + import 边界检查优先，rules 文字最后；新增园丁流程和 `.vibe/weeds.md` | organic architecture、gardener |
| 通宵约定是 markdown 日志 | TSV 决策日志 + transcript 审计 + 另一模型审阅 + “先赢得信任的 4 个条件” + `/goal` / Stop hook + 无人值守 5 问 | show-me-your-work、Claude 官方 |
| 插件预装一堆 skill | **从零开始**：自动可调用的 skill 只留最少几个，其余手动调用（不占上下文）；skill 用 eval 检验、随模型变强而变短 | Lauren “start with nothing” |
| 没有外循环 | 新增：分诊 → 复现 → 修复 → 验证流水线，每个阶段都能叫停整条线、都交出证据 | Loops You Can Trust、benny |
