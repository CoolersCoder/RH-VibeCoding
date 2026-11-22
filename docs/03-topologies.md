# 03 · 三种项目形态：单体 / monorepo / 多 repo

核心思路都一样：**常驻的东西放在 agent 启动的那一层，越往下越具体，按需加载**。差别只在“启动在哪”和“验证跑哪些”。

## 总览

| | 单体 repo | monorepo | 多 repo 工作区 |
|---|---|---|---|
| 在哪启动 `claude` | repo 根 | 跨包任务在根；单包任务在包目录 | hub 目录（用 `launch.sh`） |
| 常驻上下文 | 根 `CLAUDE.md` | 根 `CLAUDE.md`（+ 从包目录启动时，该包的 `CLAUDE.md`） | hub `CLAUDE.md` + 各 repo 的 `CLAUDE.md`（需环境变量） |
| 区域知识 | `.claude/rules/area-*.md` | 每个包的 `CLAUDE.md` / 包内 `.claude/skills/`，或根部 rules 加 `paths:` | 各 repo 自己的 rules |
| 验证 | `vibe verify` | `vibe verify`（只跑受影响的包）/ `--all` | `vibe verify -C hub`（逐个 repo） |
| 初始化 | `vibe init` | `vibe init --topology monorepo` | `vibe init <hub> --topology workspace --repos "../a ../b"` |

---

## 单体 repo

```
app/
├── CLAUDE.md                     # ≤200 行：命令、硬约束、架构一屏、去哪找细节、规则→强制表
├── CLAUDE.local.md               # 个人，不提交
├── .claude/
│   ├── settings.json             # 权限：禁止读取密钥 / 生成物
│   ├── rules/
│   │   ├── area-api.md           # paths: src/api/**
│   │   ├── area-ui.md            # paths: src/components/**, src/pages/**
│   │   └── traps-concurrency.md  # paths: src/**/*.ts
│   └── skills/
│       ├── verify/SKILL.md       # 提交前自动运行
│       └── run-app/SKILL.md
└── .vibe/
    ├── verify.conf
    ├── lint-rules
    └── state/                    # 不提交
```

**注意**：如果某些目录会被整体打包进产物（例如 Xcode 的同步目录、Android 的 `assets/`、被 bundler 当静态资源处理的 `public/`），**不要在里面放 `CLAUDE.md` 或任何文档**，改用根部 `.claude/rules/` 加 `paths:`。

---

## monorepo

```
mono/
├── CLAUDE.md                       # 全局：包管理器、提交规范（"api: …"）、禁止手改 generated/
├── .claude/
│   ├── settings.json               # permissions.deny: Read(./**/dist/**) 等；worktree.sparsePaths
│   ├── rules/                      # 跨包的陷阱 / 规范（用 paths: 跨多个包）
│   └── skills/verify/SKILL.md
├── .vibe/verify.conf               # PACKAGES='apps/web services/api packages/shared'  (+ 可选的根级 STEPS)
├── apps/web/
│   ├── CLAUDE.md                   # 该包的栈、命令、约定（从包目录启动时常驻；从根启动时按需加载）
│   ├── .claude/skills/…            # 该包专属 skill（例如组件模式、测试写法）
│   └── .vibe/verify.conf           # 该包自己的 steps
└── services/api/
    ├── CLAUDE.md
    └── .vibe/verify.conf
```

要点（来自 Claude Code 的 large-codebases 文档）：

- **启动位置决定加载内容**：
  - 从根启动：加载根 `CLAUDE.md`；子目录的 `CLAUDE.md` 在碰到该目录文件时才加载。
  - 从 `apps/web/` 启动：加载该目录及所有上级目录的 `CLAUDE.md`，文件访问也限定在这个子树里。
- **`.claude/settings.json` 不会从父目录继承**：在包目录启动时，这个包的 settings 必须自成一体。hooks 和权限要么放根部并从根启动，要么每个包都写全。vibe-core 的 hooks 来自用户级插件，不受这个影响，这是插件化的好处之一。
- **排除无关包**：`claudeMdExcludes` 可以跳过你从来不碰的包的 `CLAUDE.md`。
- **挡住生成物**：`permissions.deny` 加 `Read(./**/dist/**)`、`Read(./**/generated/**)`、`Read(./**/node_modules/**)`。
- **跨包访问**：从包目录启动时，需要用 `--add-dir ../shared` 或 `additionalDirectories` 访问兄弟包。
- **受影响验证**：`vibe verify` 在根部只验证有改动的包（对比 HEAD 和 `origin/main` 的 merge-base），`--all` 全量。共享包改了，要在根 conf 的 STEPS 里加一个跨包集成步骤，或者直接用 `--all`。根 conf 自己的 STEPS 的 `WATCH` 默认是 `.`，所以任何改动都会让根级步骤变成“待验证”。这是有意的：根级规则扫的是全仓。
- **规模大了**：包的 `CLAUDE.md` 太多、没人维护时，把通用约定收进插件，每个包只留真正特有的东西。

---

## 多 repo 工作区（前后端分仓、微服务）

多个独立 git 仓库，没有共同的根。做法是建一个 **hub 目录**：它本身可以是一个小 git 仓库，用来版本化工作区说明。

```
~/work/shop/                  # 你自己的工作目录
├── shop-hub/                 # hub（vibe init --topology workspace）
│   ├── CLAUDE.md             # 工作区地图 + 跨 repo 契约 + 改动顺序
│   ├── .vibe/verify.conf     # REPOS='../shop-api ../shop-web ../shop-mobile'
│   └── launch.sh             # 用 --add-dir 打开所有 repo，并加载它们的 CLAUDE.md
├── shop-api/                 # 各自 vibe init，各自 L0–L3
├── shop-web/
└── shop-mobile/
```

**hub `CLAUDE.md` 写什么**（模板已给出结构）：
- **地图**：每个 repo 是什么、技术栈、负责什么、怎么本地启动。
- **契约**：接口定义在哪（OpenAPI / protobuf / GraphQL schema 的路径），谁是来源，谁在消费。
- **跨 repo 改动顺序**：例如“先改 schema 和 api，并保持向后兼容 → 发布 → 再改 web/mobile → 最后删旧字段”。
- **本地联调**：怎么让 web 指向本地 api。
- **验证**：每个 repo 各自 `vibe verify`；契约变了要跑哪个跨 repo 检查。例如在 web 里用最新 schema 生成类型后跑 typecheck。

**启动**：`./launch.sh`，相当于：
```bash
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ../shop-api --add-dir ../shop-web --add-dir ../shop-mobile
```
- `--add-dir` 给文件访问权，并加载对方的 skills。
- 环境变量让对方的 `CLAUDE.md` 和 `.claude/rules/` 也加载进来。
- 写在 settings 的 `additionalDirectories` 里**只给文件访问权，不加载**对方的 CLAUDE.md 和 skills。

**单 repo 任务**仍然直接在那个 repo 里启动，上下文最干净。只有跨 repo 的任务才从 hub 启动。

**每个 repo 的提交和 PR 是分开的**：让 agent 按 hub 里写的顺序，在每个 repo 分别建分支、分别提交，并在 PR 描述里互相链接。

---

## 选哪种？

- 一个可部署单元 → 单体。
- 多个包共享依赖和版本、需要原子提交 → monorepo。
- 不同团队、不同发布节奏、已经分仓 → 工作区 hub。**不要为了方便 agent 去合仓**，hub 已经够用。
