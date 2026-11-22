# 07 · 日常工作流与提示词

每个 playbook 都是：**目标 → 步骤 → 完成标准 → 可以直接用的提示词**。提示词故意写得口语化，实际使用时就是这样打的。

---

## 调查（只读）

> 怎么运作？为什么这么设计？我们确定吗？

1. 先查 how：从入口追到实现，列出关键文件和数据流。
2. 再查 why：`git log -L` / `git blame` / 相关 PR，找出当时的约束。
3. 答案注明依据：哪些是读代码确认的，哪些是推测。

```text
/vibe-core:investigate how does session restore work, and why does it skip podcasts? don't change code.
```

## Bug 修复（科学方法，来自 pstack Bug fix playbook）

1. **复述**：先用自己的话复述问题，不改代码。你先别说自己的猜测，免得把它引偏。
2. **在真实界面上亲自复现**：用验证 skill 驱动应用。复现不了就合成触发条件、收紧条件、加埋点，直到它出现。实在需要用户帮忙复现，必须说清楚具体原因。
3. **二分排除假设**：列出候选假设，每一轮选能砍掉最大问题空间的那个划分，拿运行时证据排除。程序状态不清楚就加日志、看实际运行。不猜。确认存活的那个**机制**之后才开始设计修复。
4. **修复**：只做证据支持的最小改动。“可能有帮助”的双保险不上线；证据否定了某个假设，就回滚它带来的改动。改动跨函数边界时先 `/vibe-core:architect`。
5. **在同一个界面上证明**：原复现现在通过了。“Inconclusive”或换了界面验证都不算通过。单元测试只证明分支行为，证明不了 bug 不存在。
6. **提交顺序**：失败的复现或测试先提交，修复在它之上（有便宜的测试路径才写测试）。
7. **防复发**：这类错以前出现过吗？出现过就记进 `.vibe/weeds.md` 或直接 `/vibe-core:correct`。

回复要包括：坏了什么、根因、修复、怎么验证的，并原样贴出“修复前失败 → 修复后通过”的输出。

```text
repro this first. if there's a cheap test path, write the failing test. then fix the root cause and show me
the same repro passing. no retries, no sleeps.
```

两次修复都失败时：
```text
attack the premise: write down what both failed fixes assumed, and test that assumption directly before trying a third fix.
```

## 需求还没想清楚时

```text
I want to add rate limiting to the public API but haven't thought it through yet. Interview me until you could write the spec, then write it to SPEC.md.
```
写好 SPEC.md 后，开一个新会话照着它实现。新会话里，用一个没参与实现的 subagent 对照 SPEC 审查，并写上 “skip style”。想要完整版本而不是最小版本时，直接说 `be ambitious: empty and error states, keyboard navigation…`（Claude 官方）。

## 新功能

0. **会话开头先跑测试**（Simon Willison “First run the tests”）：让 agent 知道测试在哪、怎么跑、当前是什么状态。
1. **数据形状先行**：先说清要加的数据结构、接口签名、状态流转。跨函数边界时用 `/vibe-core:architect`：画两种形状，用原型回答开放问题。设计定下来才写计划。
2. **小单元**：拆成可以各自验证的步骤，每步结束跑 `vibe verify --fast`。
3. **复用**：先找现有的工具函数和组件，不另起炉灶。
4. **收尾**：完整 `vibe verify` + 行为验证 + `/vibe-core:review` 自审 + 更新受影响的 rules / CLAUDE.md。

```text
before writing code, propose the data shape and the interface for this feature and list the files you'd
touch. wait for my ok. then build it in small verified steps.
```

## 重构（行为不变）

1. 先确认有能覆盖这块行为的检查，没有就先补。
2. 一次一种变化：搬家和改逻辑分开提交。
3. **迁移调用方后立刻删旧 API**，不留兼容层（Migrate callers then delete legacy APIs）。
4. 证明行为没变：同样的检查、同样的结果。

```text
refactor X so that <goal>. behaviour must not change: first show me which checks cover it (add one if none),
then migrate all callers and delete the old API in the same change.
```

## UI 改动

1. 先截基线（改动前，或设计稿）。
2. 改。
3. 用同样的启动参数截处理图，按 `04-verification.md` 的评分表逐项比。
4. 真实数据：真实图片、长文本、空状态、错误状态都截一遍。
5. 设备相关的（动效、触感、真机尺寸）写进 Not covered。

```text
capture a baseline screenshot first, then make the change, then capture the same screen with the same args
and compare them row by row against DESIGN.md. use real artwork and a long title.
```

## 性能

1. 先测基线（多次，记范围）。
2. 提出假设（瓶颈在哪），用 profile 证明。
3. 一次改一处，每处都测，留下有效的、回退无效的。
4. 报数字前过一遍 Explain the number。

```text
measure the baseline 5 times first and report the range. then profile, state the bottleneck with evidence,
and change one thing at a time with before/after numbers. keep only changes that move the number.
```

## 原型（做决定用，用完即弃）

```text
prototype 2-3 options for the settings layout behind a switcher and send me a screenshot of each. throwaway code, don't polish.
```

## 长时间自主（通宵）

```text
/vibe-core:overnight get every test in packages/api green. you may change test fixtures and api code;
you may not change the public schema. stop and leave a note if a fix needs a schema change.
done means every test in packages/api passes. log decisions with vibe log so I can audit decisions.tsv in the morning.
```

## 提交与 PR

- 一个主题一个提交，消息写“为什么”。标题格式 `type(scope): subject`。
- **不要把没审过的 agent 代码丢给同事**（Simon Willison）：PR 要你自己确认能工作、足够小、带上下文；agent 写的 PR 描述你也要审；附上手动测试记录、截图或视频。
- PR 正文 ≤ 40 行，固定标题顺序（pstack）：`## Why` / `## What changed` / `## Scope` / `## Tradeoffs`（只写 reviewer 会问到的被否决方案）/ `## Blast Radius` / `## Verification`。空的删掉；长日志放文件或评论里，正文里链接过去。
- 审查交给没写这段代码的人：`/code-review`、reviewer subagent，最好换一家模型。
- 改写历史前先给计划；改写后核对 tree 没变（`git rev-parse HEAD^{tree}`）。
- PR 太大、靠说明也救不了时，建议拆分。

```text
/vibe-core:review main...HEAD  — then fix the high-severity findings, run vibe verify, and draft the PR description with evidence.
```

---

## 引导中途跑偏的 agent（一句话就够）

```text
i said the goal is to repro. i did not ask for a fix yet.
apply prove it works. show me the real output, not the build log.
subtract before you add.
restate what you think i want in two sentences before continuing.
that's a symptom patch. find the root cause.
/vibe-core:deslop that
```

## 一个好提示词的 5 个要素（pstack guide）

1. **目标**：哪里不对，或者你想要什么。
2. **完成检查**：必须能 pass/fail。“做得更好”“干一小时”都不算。
3. **你想看的证据**：真实命令输出、流程视频、存下来的值、前后数字。
4. **你已经知道的**：症状、复现步骤、日志行、链接，省得它去搜。
5. **真实约束**：“repro first”“don't change any code yet”“zero behavior change”“let me review before proceeding”，这些都会改变 agent 的做法。

**别写的两样**：怎么做（给它找到更好路径的空间；也别在提示词里罗列一串 skill），以及**一开始就说出你对原因的猜测**。

```text
the csv export drops its last row since yesterday's deploy. failing job id is 4812. repro first, then fix. done means the 60k-row fixture exports every row. show me the row counts before and after.
```

换话题时说 “new task”，让它重新匹配流程，不要把新问题当成上一个功能的下一步。

## 用你囤的东西（Simon Willison “Hoard things you know how to do”）

每次弄明白“某件事能做到、怎么做”，都配一段能跑的代码存下来（TIL 笔记、小仓库、单文件 HTML 工具）。最有效的提示词之一是：“把这两个现成的例子组合起来做个新东西”，比如：
```text
add mocked HTTP tests to this project inspired by how ~/dev/other-project does it.
```

## 发出提示词之前

```text
/vibe-core:sharpen write the onboarding doc for the billing service
```
它会说出专家会补充哪些你没要求的东西、从什么原材料出发、用什么方法、怎样检查结果对不对，然后把你的提示词改写好交回来，**不执行任务**。

## 和 agent 协作的节奏

- 开头：给目标、约束、完成标准。不要只给“做个 X”。
- 中途：只在它跑偏时插话，用原则名。
- 结尾：要结论格式（VERIFIED…）和证据路径，自己看截图 / 日志，不只看它的总结。
- 每次纠正都问自己：这是第二次吗？是的话，进仓库（L3）。
