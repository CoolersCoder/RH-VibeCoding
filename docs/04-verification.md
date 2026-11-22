# 04 · 验证闭环

> “验证不是复述，它要用可重复的证据证明或否定一个具体说法。”（cursor-team-kit `verify-this`）

## 三层验证

| 层 | 回答 | 手段 | 由谁跑 |
|---|---|---|---|
| **1. 门禁**（gate） | 代码健康吗？ | lint、格式、类型、单元测试、构建、`vibe lint` 规则 | `vibe verify`（每次） |
| **2. 行为** | 改动真的生效了吗？ | 启动应用并驱动它：截图、HTTP 请求、CLI 输出、日志行 | verify skill 第 3 步（改了行为时） |
| **3. 对比** | 比之前更好 / 没变坏吗？ | 同一命令、同一数据，在改动前（基线）和改动后（处理）各跑一次 | 修 bug、性能、UI 改版时 |

只有门禁全绿不算 VERIFIED。行为层验证不了的（需要真机、生产数据、第三方回调），在结论里写进“未覆盖”。

## 结论格式（强制）

```text
VERIFIED | NOT VERIFIED | INCONCLUSIVE
Claim: <可证伪的一句话：条件 → 可观察的结果>
Evidence: <命令> → <结果>；<产物路径> → <它显示了什么>
Not covered: <验证不了的部分及原因>
```

- `VERIFIED`：证据在预期方向上显示出了声称的结果，没有明显干扰因素。
- `NOT VERIFIED`：行为没变、变错了，或者有检查失败。**直说，不软化。**
- `INCONCLUSIVE`：拿不到有效证据，比如没有基线、信号噪声太大、环境不同、网络或外部依赖挂了（要附上日志行）。

## `.vibe/verify.conf` 合约

```bash
STEPS='rules lint types test build smoke'   # 按顺序执行；非 0 即失败
FAST_STEPS='rules lint types'               # 内循环用：vibe verify --fast，目标 < 10 s
WATCH='src tests package.json'              # 这些路径变了才需要重新验证（用于状态戳与收尾提醒）
step_rules='"$VIBE" lint'                   # 项目自定义规则（.vibe/lint-rules）
step_lint='…'
step_types='…'
step_test='…'
step_build='…'
step_smoke='skip'                           # 写 skip 就跳过；之后补上
```

- 完整通过会写入 `.vibe/state/verified`，内容是 WATCH 范围内改动的哈希。收尾 hook 用它判断“当前代码是否已经验证过”。
- `--fast` 不写状态戳，只用于内循环。

## 各技术栈对照（`stacks/` 里有现成的 conf，按项目改）

| 栈 | 格式 / lint | 类型 | 单元测试 | 构建 | 行为层（smoke） |
|---|---|---|---|---|---|
| **Web 前端**（React/Vue/Svelte + TS） | `eslint . --max-warnings=0`、`prettier --check .` | `tsc --noEmit` | `vitest run` / `jest` | `vite build` / `next build` | Playwright：起 dev server → 截关键页 → 看控制台报错；`npx playwright test --project=smoke` |
| **Node 后端** | 同上 | `tsc --noEmit` | `vitest` / `jest` + supertest | `tsc -p .` | 起服务 → `curl -fsS localhost:PORT/health` → 打一个真实接口，比对响应 |
| **Python** | `ruff check .`、`ruff format --check .` | `mypy .` / `pyright` | `pytest -q` | （打包）`python -m build` | `uvicorn app:app &` → curl；或 CLI 跑一遍 |
| **Go** | `gofmt -l .` 为空、`go vet ./...` | （编译即类型） | `go test ./...` | `go build ./...` | 起二进制 → curl |
| **Rust** | `cargo fmt --check`、`cargo clippy -- -D warnings` | （编译） | `cargo test` | `cargo build` | 同上 |
| **JVM**（Kotlin/Java） | `./gradlew ktlintCheck` / spotless | （编译） | `./gradlew test` | `./gradlew build -x test` | 起服务 → curl |
| **iOS / Swift** | swiftlint（如有）+ `vibe lint` | （编译） | 纯逻辑：`swiftc` 独立检查；SPM：`swift test` | `xcodebuild … -destination 'generic/platform=iOS Simulator' build` | `simctl` 安装 + 带调试启动参数 + 截图 + 日志 |
| **Android** | `./gradlew lint ktlintCheck` | （编译） | `./gradlew testDebugUnitTest` | `./gradlew assembleDebug` | `adb install` + `adb shell am start` + `screencap` + `logcat` |
| **全栈 / 容器** | 各子项目各自 | | | `docker compose build` | `docker compose up -d` → 等健康检查 → 跑一组端到端请求 → `docker compose down` |

## 项目验证 skill：关键基础设施

Lauren Tan 称它为工具箱里“最重要的 skill”，建议像维护关键基础设施一样维护它，甚至给它排值班。一个合格的 `.claude/skills/verify/` 包括：

| 部分 | 内容 | 要点 |
|---|---|---|
| Launch | 从空数据启动到**可用**（迁移、种子数据、测试账号），以及“就绪”的信号 | “就绪”是可用，不是进程有响应 |
| Doctor | 一个只读检查：这个实例值不值得驱动 | 出现任何异常先跑它 |
| Drive | 用真实的稳定句柄驱动：ARIA label、data 属性、路由、提示字符串 | 不用坐标、不用 tab 顺序 |
| Evidence | 走真实用户路径，捕获动作、结果状态和副作用；产物位置 | 不调内部 setter，不走测试专用接口 |
| Cleanup | 只杀自己启动的进程，证据保留 | 不按进程名杀 |
| 小 CLI（`scripts/<app>ctl`） | `doctor` / `snapshot` / `screenshot` / `click` / `type` / `send` / `trace` / `wait-settle` / `cleanup` | 机械部分交给代码，agent 只做判断；带示例的 `--help`，可操作的报错 |
| Feature Map（`features/`） | 每个功能一页：子功能、用户怎么到达、怎么驱动、坑 | “物化的记忆”，要定期维护 |

- 生成：`/vibe-core:create-verification`。必须按它写的步骤端到端跑通一次才算交付。
- 维护：`/vibe-core:maintain-verification`。结果只有 clean / changed / blocked 三种；发现产品回归要报告出来，绝不靠改地图掩盖。
- 一个 agent 在 PR 里改了某个功能，就在同一个 PR 里更新这个功能的地图。
- 技术栈本身是验证能力的一部分：Web / Electron 有 CDP，iOS 有模拟器。运行时太薄就自己造调试工具，或者选更容易调试的技术栈。
- 验证 skill 说绿了、产品还是错的：观察，诊断，**修 skill**。

## 行为层的“杠杆”（Build the lever）

agent 没法点击屏幕，所以要给它**能脚本化的入口**：

1. **调试启动参数 / 环境变量**：直接跳到某个页面、某个状态，比如跳过登录、打开某个弹窗、播放一个演示条目。只在 Debug 构建里生效；Release 里编译掉。
   - 坑：千万别拿 Release 构建做测量，开关在 Release 里不存在。
   - 坑：演示数据要真实，比如真实图片 URL。假数据会掩盖布局 bug。
2. **截图 / 驱动脚本**：`scripts/shot.sh <name> [args]` → `/tmp/<project>-qa/<name>.png` 和 `.log`。agent 能直接读图片，必须亲眼看截图再下结论。
3. **结构化日志行**：关键路径打印带前缀的行，例如 `QA-PLAY first audio after 3.4s`、`QA-CACHE hit`。agent 用 grep 拿证据，比“看起来正常”可靠得多。
4. **种子 / 重置脚本**：一条命令把本地数据库或模拟器恢复到已知状态。

## UI 改动的评分表（来自 dyl-stack visual judge）

基线（设计稿或改动前截图）对处理（改动后截图），逐项比，**任意一项不过就是 NOT VERIFIED**：

0. 明暗主题一致
1. 结构：区域一样，没有多出或缺少的 chrome
2. 组件：用的是设计系统里的组件，没有自造的
3. 字体：字号、行高误差 ~1px 以内
4. 间距：padding、间隙、控件高度
5. 素材：尺寸由布局决定，没有被原图尺寸撑大
6. 控件：按钮、勾选框、关闭按钮和设计一致

## 性能数字（Explain the number）

报一个数字之前，用 pstack `/benchmark-checklist` 的 7 个问题逐一拿运行证据回答：

1. 什么在限制这个数字，为什么不是两倍？
2. 每一侧都按生产方式调优了吗？（Debug 对 Release、缓存冷热）
3. 结果有没有突破物理极限（磁盘带宽、核数）？
4. 有没有出错或返回错误输出？
5. 交替多次运行能复现吗？给出中位数和范围。
6. 端到端重要吗，是不是在用户等待的路径上？
7. 工作真的发生在计时区间里吗？

答不上来，或者有一侧没调优，结论就是 `INCONCLUSIVE`。

## 不放心的小改动：证明“它为什么安全”

`/vibe-core:blast-radius`：列调用方没用。要找出“这个改动之所以安全”所依赖的那一个事实，按“断言 → 指到 `file:line` → 推演失败路径 → 写脚本跑真实代码证明 → 在运行的应用里复现”的阶梯，尽量往下推，并说明停在了哪一级。

## 用代码证明看不到的路径（进阶）

并发、重试、状态机、协议类的 bug 常在测试想不到的顺序里出现。pstack 的做法是：对一个高代价的性质，比如“一个任务永远不会同时跑两次”，用模型检查器（默认 TLA+）检查范围内所有可达状态，并且先在一个故意改坏的版本上证明这个检查确实会失败。

## 只有真机 / 线上才能验证的

明确列出，例如推送、支付回调、相机、蓝牙、语音识别、车机、真实网络环境。结论里写进 “Not covered”，请人去验，**绝不从模拟器或 mock 推断**。
