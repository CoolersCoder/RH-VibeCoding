# 02 · 渐进式设置手册（L0 → L5）

**规则：不要跳级，也不要提前配置。** 每一级都有触发条件，碰到了再升。

> Lauren Tan 的原话：“start with nothing. don't download any plugins or skills. no AGENTS.md either. just prompt and observe the failure modes. codify them into skills when they repeat.”
> 所以 vibe-core 的 skill 全部是手动调用（`disable-model-invocation`），不占上下文。L0 的 CLAUDE.md 也应该尽量短，失败重复了才往里加。

`vibe doctor` 会告诉你现在在哪一级、下一步做什么。每一级都写了：

- **触发**：什么时候该做
- **步骤**：具体做什么（命令 + 文件）
- **完成标准**：做到什么算完成（可检查）
- **对 Claude 说**：可以直接粘贴的提示词

只想在某台机器上一次性装好：见 README 的“五分钟上手”。下面假设 `vibe-core` 插件已安装，`vibe` 在 PATH 里。

---

## L0 · 起步：agent 知道项目是什么、怎么跑

**触发**：新项目第一天，或第一次把一个老项目交给 agent。

**步骤**

1. `vibe init --level 0`，会创建：
   - `CLAUDE.md`：从模板生成，**必须手工填**。
   - `.claude/settings.json`：默认禁止读取 `.env*`、密钥、生成物和依赖目录。
   - `.gitignore`：追加 `.vibe/state/`、`.claude/settings.local.json`、`CLAUDE.local.md`。
2. 在 Claude Code 里运行 `/init`，让它分析代码库提出补充，你**删掉一切能从代码推出来的内容**。
3. 填 `CLAUDE.md` 的这几块（模板里都有占位）。判断每一行该不该写：“它能从代码里找到吗？它会去找吗？”两个都是“会”就删掉：
   - 一两句话：这是什么、给谁用、不是什么。
   - **检查命令**：门禁、单个测试，每条都要真能跑。这是最有价值的一节。agent-compatibility 插件的教训：文档写的命令跑不通，比没写更糟。
   - **仓库里看不到的东西**：不在仓库里的环境准备、会议上做的决定（“选 X 不选 Y，别再提 Y”）、外部约束、坑。
   - **不要写架构和文件布局**：Claude 自己会读仓库（Claude 官方“可以不再做的事”）。
   - **去哪找细节**：这一级先留空，L2 再填。
4. 个人偏好（本地地址、测试账号）写进 `CLAUDE.local.md`，它不会被提交。

**完成标准**
- `CLAUDE.md` ≤ 200 行、≤ 25 KB，命令逐条复制都能跑通。
- 新开一个会话问“怎么跑测试”“入口在哪”，agent 不用搜索就能答对。
- `vibe doctor` 显示 `level: 0`。

**对 Claude 说**
```text
Read the codebase and fill CLAUDE.md from the template. Only write what can't be derived from the code:
commands (verify each one actually runs), hard constraints, a one-screen architecture, and gotchas.
Keep it under 200 lines. Don't list files that a glob would find.
```

---

## L1 · 验证闭环：“做完了”要有证据

**触发**：第一次让 agent 改代码之前。这一级的回报最大，永远不要跳过。

**步骤**

1. `vibe init --level 1`，会创建：
   - `.vibe/verify.conf`：从 `stacks/<技术栈>/verify.conf` 复制。
   - `.claude/skills/verify/SKILL.md`：**这个名字很关键**。Claude Code 会在每次提交前自动运行项目里名为 `verify` 的 skill。
2. 编辑 `.vibe/verify.conf`：让每个 step 对应项目里真实的命令。最少要有 lint/格式、类型检查（如果有）、单元测试、构建。
   ```bash
   STEPS='rules lint types test build'
   FAST_STEPS='rules lint types'
   step_lint='npx --no-install eslint . --max-warnings=0'
   ...
   ```
3. 跑 `vibe verify`，修到全绿；再跑 `vibe verify --fast`，确认它在 10 秒内完成。内循环要快，agent 才愿意频繁跑。
4. **把验证 skill 当关键基础设施来建**（这是 L1 的核心，门禁只是其中一部分）：运行 `/vibe-core:create-verification`，它会做三件事：
   - 让 `.claude/skills/verify/SKILL.md` 填满真实的启动、体检、驱动、证据、清理步骤。
   - 在 `scripts/` 下写一个小控制 CLI（`doctor` / `snapshot` / `screenshot` / `click` / `send` / `cleanup`…）。
   - 给 3–5 个核心功能写功能地图（`features/`）。

   写完后，它要按自己写的步骤端到端跑通一次，才算交付。各技术栈的驱动方式：
   - Web / Electron：Playwright 或 Chrome DevTools Protocol。
   - 后端：起服务，curl 健康检查和一个真实接口。
   - CLI：tmux / PTY。
   - iOS：simctl。Android：adb。

   之后定期跑 `/vibe-core:maintain-verification`，可以用 `/schedule` 每天跑一次。Claude Code 内置的 `/run-skill-generator` 和 `/verify` 也能帮忙录制启动配方。
5. 没有单元测试的纯逻辑（算法、排序、计费、解析），把它拆成不依赖框架的纯函数，配一个最小的独立检查。RH-Music 的做法：一个 `main.swift` 用 `swiftc` 单独编译运行，`verify` 自动跑全部。

**完成标准**
- `vibe verify` 在干净的工作区上全绿，并写入 `.vibe/state/verified`。
- `vibe verify --fast` < 10 s。
- 新会话里说“改一下 X，然后用 verify 证明给我看”，agent 能自己启动应用、驱动到那个功能、交回截图 / 日志，全程不需要问你。
- agent 汇报完成时带 `VERIFIED / NOT VERIFIED / INCONCLUSIVE` 和证据。

**对 Claude 说**
```text
Make `vibe verify` real for this project: map every step in .vibe/verify.conf to the project's actual
lint/typecheck/test/build commands, run it until green, and fill the "exercise the behaviour" section of
.claude/skills/verify/SKILL.md with the concrete way to see a change working (dev server + screenshot,
curl, CLI run, simulator...). Show me the passing output.
```

---

## L2 · 按需知识：上下文只装当前任务需要的

**触发**（任一）：
- `CLAUDE.md` 超过 200 行。
- 某个目录有自己的规矩，比如数据库迁移、支付、设计系统。
- 同一段流程说明你粘贴了第三次。
- agent 每次都要大范围搜索才能找到东西。

**步骤**

1. `vibe init --level 2`，会创建：
   - `.claude/rules/area-example.md`：路径规则的样板。
   - `.claude/skills/run-app/SKILL.md`：启动 / 驱动应用的配方样板。
2. **拆分 CLAUDE.md**：只在某块代码里才需要的内容，挪进 `.claude/rules/area-<模块>.md`，开头写：
   ```markdown
   ---
   paths:
     - "src/billing/**"
     - "src/api/routes/payments*.ts"
   ---
   ```
   Claude 处理匹配的文件时才加载它。一条规则可以跨多个目录，这一点比“每个目录放一个 CLAUDE.md”灵活。
3. **陷阱规则**：把“已知 bug 模式”按影响范围写成规则，比如所有 `*.ts` 的并发陷阱、所有组件的布局陷阱。每条写清三件事：现象、原因、正确写法。
4. **流程写成 skill**：部署清单、发版、迁移步骤、某个外部 API 的参考资料，各放进 `.claude/skills/<name>/SKILL.md`。
   - 有副作用的（部署、发消息）加 `disable-model-invocation: true`，只能你手动调用。
   - 纯参考资料让 Claude 自动加载，`description` 里放请求中会出现的关键词。
5. **挡住噪音**：在 `.claude/settings.json` 的 `permissions.deny` 里加上生成物、依赖、构建产物，例如 `Read(./**/dist/**)`。
6. 根 `CLAUDE.md` 里加一张“去哪找细节”的表，写明每块知识在哪个 rule / skill 文件里。

**完成标准**
- 根 `CLAUDE.md` ≤ 200 行；每个 rule 文件 ≤ 200 行，有 `paths:`。
- 新会话改某个模块时，`/context all` 的 Memory files 里出现对应的 rule，其它模块的 rule 不出现。
- `/doctor prompt-audit` 没有冲突或指向不存在文件的指令。

**对 Claude 说**
```text
Our CLAUDE.md is too big. Keep only what every session needs (<200 lines). Move area-specific facts into
.claude/rules/area-*.md with `paths:` frontmatter, procedures into .claude/skills/, and delete anything
derivable from code or stale (line counts, history). Fix contradictions you find. Add a "where things are
documented" table to CLAUDE.md. Don't put any markdown inside directories that get bundled into the build.
```

---

## L3 · 强制执行：同样的错不再犯第二次

**触发**：同一个纠正你说了第二遍，或者 code review 第二次指出同一类问题。

**步骤**

0. **优先改结构，不优先写文字**（Lauren：“the best rules are in your code”）：用目录边界划清谁能 import 谁，配一个 import 检查；用更强的类型；打开编译器诊断。这些都比 CLAUDE.md 和 skill 的措辞有效得多。
1. `vibe init --level 3`，会创建 `.vibe/weeds.md`（园丁队列）和 `.vibe/lint-rules`。lint-rules 从技术栈模板复制，里面有几条通用起步规则，例如合并冲突标记、私钥 / AK、文件超过 1000 行，以及该技术栈常见的调试残留。
2. 每遇到一个反复出现的错误，按 `/correct` 的优先级处理：
   1. **架构**：能不能让它根本写不出来？例如只留一个入口函数、删掉旧接口。
   2. **类型**：能不能让编译器拒绝？
   3. **lint 规则**：在 `.vibe/lint-rules` 里加一条。报错信息要**直接写修法**，并附 `bad:` / `ok:` 例子。
   4. **测试**：纯逻辑配独立检查。
   5. **文字**：最后才写进 rule。
3. `vibe lint --self-test` 证明每条规则会抓住 `bad`、放过 `ok`。
4. 编辑后 lint hook 和收尾验证提醒由 vibe-core 插件**自动生效**：只要项目里有 `.vibe/lint-rules` 和 `.vibe/verify.conf`，不用额外配置。团队里有人没装插件时，用 `vibe init --vendor` 把 hooks 复制进项目并注册到 `.claude/settings.json`。
5. 在根 `CLAUDE.md` 维护“规则 → 由什么强制”表。只靠文字维持的规则如果又被违反，就升级到更高的层级。

**完成标准**
- `vibe lint` 在当前代码上干净；`vibe lint --self-test` 全过。
- 故意写一行违规代码，Claude 编辑后立刻收到 lint 反馈。
- 改了代码不跑 verify 就想结束，会被提醒一次。

**对 Claude 说**
```text
/vibe-core:correct agents keep <mistake>. Prove the new check fails on the real past mistake.
```

---

## L4 · 自主与规模：长任务、并行、少盯着

**触发**：想让 agent 连续工作几个小时，同时开多个任务，或者任务大到一个上下文装不下。

**步骤**

1. **杠杆脚本**：截图 / 驱动 UI、造种子数据、重置本地环境、打一组 API 请求，都写成 `scripts/` 下的命令，在 verify skill 里引用。原则：脚本做固定的事，agent 做判断。
2. **独立审查与第二意见**（插件已带）：
   - 作者永远不评审自己的改动。用 `reviewer` subagent，或 Claude Code 的 `/code-review`（新的上下文），最好再换一家模型。审查提示词里写上 “skip style”。
   - `advisor`：用更强的模型做第二意见。只在三个节点用：重大决定前、同一问题修两次仍失败时、宣布完成前。
   - 设计用 `/vibe-core:architect`：画两种形状，用原型回答开放问题。不放心的小改动用 `/vibe-core:blast-radius`：证明它“之所以安全”所依赖的那一个事实。
3. **长任务约定**（`/vibe-core:overnight`）。前提是满足“先赢得信任”的 4 个条件。然后：
   - 写一个能 pass/fail 的完成谓词，同时设成 `/goal`。
   - 写清可以改什么、不能改什么、什么情况下停下。
   - 每个决策用 `vibe log` 记进 `decisions.tsv`。
   - 收尾时对照实际过程审计这份日志，再让另一个模型过目。

   出发前过一遍 Claude 官方的“无人值守 5 问”：知道什么算完成吗？能检查自己吗？能碰什么？什么让它停（`--max-turns` / `--max-budget-usd`）？结果去哪、谁签字？
4. **并行**：每个并行任务用独立的 git worktree（`claude --worktree`），互不踩。monorepo 配 `worktree.sparsePaths` 只检出需要的目录。
5. **PR 流程**：小 PR、每个 PR 自带证据；用 `/vibe-core:review` 自审后再交给人。

**完成标准**
- 给一个带完成条件的任务，离开一小时，回来能看到证据和决策日志，而不是半成品。
- 并行的两个任务没有互相覆盖文件。

---

## L5 · 团队与多仓：一套做法覆盖所有 repo

**触发**：第二个 repo 要用同一套配置；多人协作；前后端分仓需要一起改。

**步骤**

1. **个人全局层**：`~/.claude/CLAUDE.md` 只放你个人的通用偏好，例如沟通语言、提交风格、绝不做的事。`~/.claude/rules/` 放跨项目的个人规则。
2. **插件化**：把你验证过的 skills、agents、hooks 放进自己的插件（就是本工具包的 `vibe-core`），通过 marketplace 分发：
   - 团队用一个 git 仓库托管 marketplace，`claude plugin marketplace add <git-url>`。
   - 插件的 skill 带命名空间（`/vibe-core:review`），不会和项目 skill 冲突。
3. **多 repo 工作区**：见 `03-topologies.md`。建一个 hub 目录，用 `vibe init --topology workspace`，hub 的 `CLAUDE.md` 写跨 repo 契约。
4. **园丁**：定期跑 `/vibe-core:garden`，比如用 `/schedule` 每周一次。它抽读最近合并的代码，把发现的问题写进 `.vibe/weeds.md`，归并根因，重复出现的就“改苗床”（`/vibe-core:correct`）。你自己每天细读一部分合并的 PR，量大时不可能每道菜都尝。
5. **持续学习**：有收获的会话结束时跑 `/vibe-core:reflect`，它提议对 skill / 规则的修改，你批准后才改。每周跑一次 `/doctor prompt-audit`。skill 要越改越短：具体命令挪进 CLI，只留流程和判断。重要的 skill 改动，拿同一个任务做前后对比。
6. **外循环（报告自动处理）**：如果 bug 报告从 Slack / issue 流进来，按“分诊 → 复现（命中两次，带截图或视频）→ 修复（最小改动，前后对比）→ 验证”拆成定时 / 事件触发的任务（Claude Code `/schedule` routines、GitHub 触发）。每个阶段都能叫停整条线，每个阶段都交出证据，main 分支用保护规则护住。
7. **度量**：记下哪些 skill 从来没被用过，删掉；可自动调用的 skill 描述太长就缩短（它们的描述常驻上下文）。

**完成标准**
- 新 repo：`vibe init` + 填 CLAUDE.md，30 分钟内到 L1。
- 一个跨 repo 的改动（例如接口加字段），在 hub 里一个会话完成两边改动和两边的 verify。

---

## 速查：触发条件 → 加什么

| 你遇到了 | 加 |
|---|---|
| agent 不知道怎么跑 / 测试 | L0：CLAUDE.md 命令 |
| agent 说“应该可以了” | L1：verify 闭环 |
| CLAUDE.md > 200 行 | L2：rules 拆分 |
| 第三次粘贴同一段流程 | L2：skill |
| 同一个纠正第二次 | L3：lint 规则 / `/correct` |
| 每次都要发生的事 | L3：hook |
| 旁支任务刷屏 | L4：subagent |
| 想离开几个小时 | L4：overnight 约定 |
| 第二个 repo 要同一套 | L5：插件 |
| 前后端分仓一起改 | L5：工作区 hub |
