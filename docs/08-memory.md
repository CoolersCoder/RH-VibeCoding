# 08 · 记忆维护：让 CLAUDE.md 不腐烂

## 四种记忆，各管各的

| | 谁写 | 放什么 | 加载 |
|---|---|---|---|
| `CLAUDE.md`（项目，提交） | 你 + agent（经你审） | 命令、硬约束、架构一屏、去哪找细节、规则→强制表 | 每次启动 |
| `.claude/rules/*.md`（提交） | 同上 | 区域事实、陷阱、设计规范 | 碰到匹配路径时 |
| `CLAUDE.local.md`（个人，不提交） | 你 | 本地地址、测试账号、个人习惯 | 每次启动（在项目 CLAUDE.md 之后） |
| `~/.claude/CLAUDE.md`（全局个人） | 你 | 跨项目偏好：语言、提交风格、红线 | 每个项目 |
| auto memory（`MEMORY.md`） | Claude 自己 | 它从纠正中学到的东西 | 前 200 行 / 25 KB |

## 写什么、不写什么

**写**：
- 代码里看不出来的东西：为什么这么做、外部约束、契约。
- 陷阱：现象 → 原因 → 正确写法。
- 真能跑的命令。
- 已验证的事实，并注明验证日期（例如“只有 X 后端可用，2026-09 验证”）。

**不写**：
- 能从代码推出来的东西：文件列表、函数签名。
- 行数、“以前是 X 现在是 Y”的历史（git 里有）。
- 一次性的细节、秘密、个人数据。
- 给旧模型打的补丁：新模型发布后回头删掉。

## 什么时候更新

- 改了某个 rule / CLAUDE.md 描述的行为 → **同一个提交里**更新那段文字。
- 同一个纠正第二次 → 写进去，更好的是写成检查（`05-enforcement.md`）。
- code review 发现 agent 本该知道的事 → 写进对应的 area rule。
- 每周或每个大版本 → `/doctor prompt-audit` 找过时、冲突、引用不存在文件的指令。
- 新模型发布后 → 删掉为旧模型限制写的规则。

## 持续学习流程（借鉴 continual-learning）

可以手动，也可以挂在 Stop hook 上按节奏触发：比如每 10 轮且距上次至少 2 小时，并且 transcript 有更新。

1. 先读现有的 CLAUDE.md 和 rules。
2. 只看**新增或更新过**的会话记录（维护一个“已处理”索引）。
3. 只抽两类：
   - **反复出现的用户纠正 / 偏好** → 写进 `~/.claude/CLAUDE.md` 或项目的 `CLAUDE.md`。
   - **稳定的项目事实** → 写进对应的 area rule。
4. **原地更新**相同含义的条目，语义重复的合并，**每节最多 12 条**。
5. 不写证据和置信度标签，不写过程说明，不写秘密。
6. 没有值得写的就明确说“没有高价值的记忆更新”。

置信度（借鉴 workflow-from-chats）：
- 强：用户明确说了偏好，或在多个会话里重复。→ 写。
- 中：被接受了的做法，没有反对。→ 考虑写。
- 弱：agent 自己的选择，用户没反馈。→ 不写。
- 矛盾：证据互相冲突。→ 问用户。

```text
mine our last week of sessions for recurring corrections and durable project facts. update CLAUDE.md /
the area rules in place (max 12 bullets per section, dedupe, no one-offs, no secrets). show me the diff.
if nothing is high-signal, say so.
```

## 园丁：让代码库本身成为好记忆

Lauren Tan：“every team needs a gardener… every weed you pull becomes a rule, so it can't grow back.”代码库是下一个 agent 照抄的范例，它本身就是最重要的“记忆”。

1. 持续发现：自己读 diff、review 时，或者用 `/vibe-core:garden`。
2. **先记进 `.vibe/weeds.md`，不立刻修**。单个修复会掩盖模式。
3. 每隔几天按根因归并。同一个根因出现两次以上，就“改苗床”（`/vibe-core:correct`）。一次性的错不用管。
4. 每天细读一部分已合并的 PR。

## 过去的会话是金矿

- 开始一个老话题的新工作时，先让 agent 读相关的旧会话。Claude Code 的会话记录在 `~/.claude/projects/` 下，也可以用 `claude --resume` 继续旧会话。把关键上下文载入后，再给它新的输入。
- 接手别人（或自己上周）做到一半的分支：先读决策日志和 git log，把之前的记录当作权威输入，只验证继承下来的结论，不从头重做。
- 暂停时（要下线、要重启），写一个恢复笔记：意图、进度、已验证的部分、下一步、关键文件、坑。未提交的改动打成一个 `wip:` 提交。

## 体检清单

- [ ] 根 `CLAUDE.md` ≤ 200 行、≤ 25 KB
- [ ] 每条命令复制就能跑
- [ ] 没有行数、没有“以前怎样”
- [ ] 每个 rule 都有 `paths:`，且路径真实存在
- [ ] “规则 → 强制”表里没有只靠文字、却被反复违反的规则
- [ ] `/doctor prompt-audit` 干净
- [ ] 没有 Markdown 放在会被打进产物的目录里
