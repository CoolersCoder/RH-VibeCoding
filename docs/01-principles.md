# 01 · 核心原则

这些原则跟技术栈无关。引导 agent 时**直接说原则名**（“apply prove it works”），比写一段话更准。每条原则都写了“违反时的信号”，方便你在对话里及时喊停。

## 一、分工

**1. 人负责判断，agent 负责执行，仓库负责记忆和强制。**
你决定做什么、取舍、验收；agent 写代码、跑命令、拿证据；所有“下次还要记得”的东西进仓库，不留在聊天里。
*违反信号*：同一件事你在两个会话里各解释一遍。

**2. Never block on the human（可逆的就先做）。**
可逆的事 agent 直接做完再给你看。不可逆的事（删数据、force push、发消息、花钱）必须先停下确认。
*违反信号*：agent 为一个可以随时撤销的小选择反复问你；或者反过来，它没问就删了东西。

## 二、先深后快

**3. Go deep first（想快，先深）。**
先读懂现有代码、数据结构和约束，再动手。一个深入理解后写出的改动，胜过五个浅改动加返工。
*违反信号*：没读调用方就改函数签名；没看现有工具函数就自己再写一个。

**4. Foundational thinking（先定数据结构）。**
先确定核心数据形状和接口，逻辑自然跟着走。
*违反信号*：一堆 if 在补一个没想清楚的数据模型。

**5. Restate before you act（先复述）。**
复杂或模糊的需求，先让 agent 用自己的话复述，并说出“我打算改哪里”。误解在复述阶段只花一条消息。

**6. Exhaust the design space（没有先例时做 2–3 个原型）。**
从能跑的东西里挑，而不是从描述里挑。

## 三、少即是多

**7. Subtract before you add / Laziness protocol。**
先删再加。优先删除、复用、最小改动。死代码会被 agent 当作范例照抄，必须删。
*违反信号*：在三个旧适配器旁边加第四个；“为了兼容”留着没人用的路径。

**8. Minimize reader load。**
少层级、少隐藏状态、少间接。文件过大（> 1000 行）先拆。
*违反信号*：只做转发的 wrapper；为一次调用抽象出一个“通用机制”。

**9. Model the domain / Type-system discipline。**
重复出现的规则收进一个结构，不要散落在各处的条件判断里；让非法状态无法表示；在边界做校验，内部信任类型。

## 四、证据

**10. Prove it works（验证真实产物，不验证替身）。**
“编译通过”“测试绿了”不等于行为对了。要看真实输出：截图、HTTP 响应、日志行、数字。
*违反信号*：agent 说“应该可以了”。

**11. Fix root causes。**
先复现，追到原因，再改。不打补丁、不加 sleep、不吞异常、不跳过测试。
*违反信号*：重试循环、`try/catch` 包一切、`sleep(2)`、`skip`。

**12. Attack the premise（连续两次修不好就攻击前提）。**
把前两次修复共享的假设写下来，直接测试它。

**13. Explain the number。**
一个性能数字在被信任之前，要说清它受什么限制、跑了几次、波动多大、确实没测错对象。

**14. Test behavior, not implementation。**
断言使用者能观察到的行为：行为坏了测试必挂，内部重构测试不挂。用脆弱 mock 硬凑的测试，证明力不如真跑一遍命令。

**15. Sequence verifiable units。**
把工作拆成小单元，每个单元以一次检查结束，再开始下一个。

## 五、让错误不可能

**16. Encode lessons in structure。**
同一句提醒写了第二遍，就把它变成 lint、类型、检查或脚本。“指令是症状，结构才是治疗。”

**17. Build the lever。**
agent 反复手工做的事，让它写成脚本（`vibe verify`、截图脚本、种子数据脚本）。脚本做固定的事，agent 做判断。

**18. Make operations idempotent。**
重试应该收敛到同一个终态。init 不覆盖、迁移可重跑、同步按并集合并。

## 六、上下文是稀缺资源

**19. Guard the context window（2026 版的理解）。**
常驻的（`CLAUDE.md`）越短越好；区域知识按路径加载（rules）；流程按需加载（skills）。现在多数模型有 1M 上下文和自动压缩，“省上下文”已经不是用 subagent 的主要理由（Claude 官方）。subagent 真正的价值在三件事：并行、隔离噪音输出、**独立审查**。另外，换任务时 `/clear`，上下文聚焦，答案更好、更便宜。

**20. Docs rot, code doesn't。**
文档里不写行数、不写“以前怎样”。能从代码推出来的不写，只写代码里看不出来的：为什么、陷阱、契约、外部约束。

## 七、诚实

**21. Honest state。**
UI 和报告都不能假装成功：不能播的就说不能播，没验证的就说没验证，模拟器验证不了的就说要真机。
负面结论（`NOT VERIFIED`）同样有价值，不许软化。

## 八、补读 pstack 作者文章后补上的（见 `10-masters.md`）

**22. 验证是限速步骤（three-minute egg）。**
写代码已经很快，复现和验证才是长杆。先让 agent 能自己验证，再谈并行和循环；否则只是更快地产出垃圾。验证 skill（启动 / 体检 / 驱动 / 证据 / 清理 + 功能地图 + 小 CLI）是关键基础设施。

**23. 作者不评审自己。**
评判一个改动的，永远不是写它的那个：用新的上下文（`/code-review`、reviewer subagent），最好换一家模型。删注释也交给没写这些注释的人。

**24. 最好的规则在代码里。**
目录边界 + import 检查、强类型、编译器诊断，比 CLAUDE.md 和 skill 措辞有效得多。代码库本身就是下一个 agent 照抄的范例，坏模式留着就等于一条指令。

**25. 从零开始，重复了才固化。**
不要预装一堆 skill 和规则：先直接提示，观察失败，重复了再固化成 skill，更好的是写成 lint 或改结构。模型变强之后，skill 应该变短。

**26. 先赢得信任，再放手（信任阶梯）。**
自主运行的前提：亲手做过一次、agent 有和你一样的工具、每个阶段都能叫停整条线、反复出现的失败已经变成了检查。“工作 4 小时”不是完成条件，必须是能 pass/fail 的谓词。

**27. 用代码规划。**
不接受第一个设计，也不打磨没被代码检验过的计划。用原型回答开放问题，画两种形状挑一个；设计定下来才写计划。不对抽象计划做对抗式审查。

**28. The Algorithm（马斯克五步法，dyl-stack）。**
先让需求不那么蠢 → 删除 → 优化 → 加速 → 自动化。顺序不能反：别去优化一个本该删掉的东西。

**29. 坦率胜过附和。**
“No is an acceptable answer.”被问到时给真实判断。每个断言附证据，或者标注“测得 / 推断 / 猜测”；能自己跑的检查不交给人。

---

## 用原则名引导：常用短语

```text
apply prove it works. show me the real output, not the build log.
subtract before you add. delete the obsolete adapters first, then design what's left.
fix root causes. repro first, no retries or sleeps.
attack the premise — two fixes failed, write down what they both assumed and test it.
restate the issue in your own words. don't change any code yet.
encode this lesson in structure — this is the second time.
guard the context window — do the search in a subagent and bring back only the findings.
```
