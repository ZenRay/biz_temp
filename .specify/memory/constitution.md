<!--
  Sync Impact Report
  ==================
  Version change: (none) → 1.0.0 (initial ratification)

  Added principles:
    - I. Data Accuracy Gate (数据准确性门禁)
    - II. Diagnostic Flow Alignment (诊断流程对齐)
    - III. Design System Fidelity (设计系统一致性)
    - IV. Platform-First Development (妙搭平台优先)
    - V. Dev-Verify-Publish Workflow (开发-验证-发布)
    - VI. Phased Iteration (分阶段迭代)

  Added sections:
    - Technology Stack Constraints
    - Development Workflow

  Removed sections: (none)

  Templates requiring updates:
    - .specify/templates/plan-template.md      ✅ aligned (Constitution Check section present)
    - .specify/templates/spec-template.md      ✅ aligned (no constitution-specific refs)
    - .specify/templates/tasks-template.md     ✅ aligned (no constitution-specific refs)
    - .specify/templates/checklist-template.md ✅ aligned

  Follow-up TODOs:
    - TODO(CONSTITUTION_REVIEW): schedule 30-day review after first production release
-->

# BIDashboard Constitution

> 商家复盘可视化看板项目宪章 — 治理所有设计、开发、发布决策的最高准则。

## Core Principles

### I. Data Accuracy Gate (数据准确性门禁)

数据准确性是项目的基线，不可妥协。

- 数据门禁 MUST 通过后才允许进入业务归因流程；门禁未通过时 MUST 停止并明确告知用户。
- 所有指标口径 MUST 与数仓团队对齐，前后端计算逻辑 MUST 保持一致。
- 数据展示 MUST 可溯源：每个数值 MUST 能追溯到具体数据源与计算逻辑。
- 数据上线前 MUST 经过至少一轮人工校验，确认与飞书多维表格现有数据一致。

**理由**：复盘决策依赖数据结论，错误数据直接导致错误运营动作，损失不可逆。

### II. Diagnostic Flow Alignment (诊断流程对齐)

页面布局与交互 MUST 对齐诊断框架的「全局 → 下钻 → 异常 → 原因 → 动作」流程。

- 页面层级 MUST 反映诊断路径：概览（全局）→ 品类/商家/商品分析（下钻）→ 诊断页（异常与原因）。
- 下钻路径 MUST 支持：品类 → 商家 → SKU → 区县 → 门店，点击即跳转。
- URL 参数 MUST 使用 `categoryLevel4Id` / `merchantId` / `skuId` 命名，保持语义一致。
- 筛选器顺序 MUST 遵循从大到小的维度层级：日期窗口 > 日期 > 四级类目 > 商家 > 商品。
- PageSection 划分 MUST 统一为：指标概览 / 趋势分析 / 数据明细。

**理由**：将资深人员的诊断经验工具化，让运营人员获得系统化引导，是缩短复盘时间的核心手段。

### III. Design System Fidelity (设计系统一致性)

所有前端组件 MUST 使用 Fresh Produce BI 设计系统 token，禁止随意定义颜色、字号、阴影。

- 色彩：Primary `#FF6B00`、Secondary `#16b3d3`、Tertiary `#F43F5E`、Success `#10B981`。
- 字体：标题用 Plus Jakarta Sans，正文用 Inter，中文回退 PingFang SC / Microsoft YaHei。
- 字号：`display` 32px / `heading` 20px / `subheading` 16px / `body` 14px / `caption` 12px。
- 语义色：`text-primary` / `text-secondary` / `text-muted` / `canvas` / `surface` / `border` MUST 按用途使用。
- 圆角、阴影 MUST 使用 token 定义值（`xl`/`lg`/`md`/`sm`/`pill`，`card`/`card-hover`/`popover`）。
- 图表库统一使用 ECharts（`echarts-for-react` 封装），数据标签使用 dark black（`#1a1a1a`）。

**理由**：统一视觉语言降低用户认知成本，token 化便于后续主题扩展与暗色模式适配。

### IV. Platform-First Development (妙搭平台优先)

MUST 优先使用飞书妙搭（Miaoda）平台提供的能力，避免重复造轮子。

- 妙搭脚手架已预装的依赖（ECharts、Recharts、React Query 等）MUST 直接使用，不额外安装。
- 插件能力（权限、触发器、MCP、OpenAPI）MUST 参考 `.agents/` 下的官方指引。
- 数据库操作 MUST 通过 `+db-env-migrate` 从 dev 同步到 online，禁止直接操作线上。
- 资源文件（图片、字体）MUST 通过 `+file-upload` 上传到应用存储，不提交到 git。
- 共享代码 MUST 放在 `shared/` 目录，前后端通过共享类型保持契约一致。

**理由**：妙搭平台提供了经过验证的基础设施，遵循平台规范降低维护成本并保证兼容性。

### V. Dev-Verify-Publish Workflow (开发-验证-发布)

所有代码变更 MUST 经过 dev 环境验证后才允许发布到 online。

- 开发分支：`sprint/default`，所有日常开发在此进行。
- 发布流程：`git push origin sprint/default` → `lark-cli +release-create --environment dev` → dev 验证 → 手动发布 online。
- AI 助手 MUST NOT 自动执行 `git commit` 或 `git push`，仅在用户明确要求时执行。
- `main` 分支为发布态快照，由 `+release-create` 成功后服务端自动推进，禁止直接推送。
- 发布前 MUST 确认：所有改动已 commit、dev 环境验证通过、数据库变更已同步。
- Commit 信息 MUST 遵循 Conventional Commits 规范，scope 使用 `client` / `server` / `shared` / `db` / `config`。

**理由**：线上环境影响真实用户，dev-verify 流程是质量兜底；禁止自动提交防止误操作。

### VI. Phased Iteration (分阶段迭代)

MVP 范围 MUST 严格受控，复杂功能先占位后填充，避免过度设计。

- MVP 包含：性能优化、诊断检查清单、快速数据迭代、交互式下钻。
- MVP 不包含：异常触发流程、决策树配置、数据门禁自动化、品类差异化配置、高代码系统。
- 数据诊断页等复杂功能 MUST 先以 placeholder 占位，后续迭代填充。
- 品类差异化配置 MUST 待 MVP 验证后再评估。
- 验证计划 MUST 遵循：第 1-2 周原型验证（加载 < 10s）→ 第 3-4 周试运行（复盘 < 1h）→ 第 5 周+品类扩展。

**理由**：10 人规模的用户场景下，快速验证核心流程比完善所有细节更重要。

## Technology Stack Constraints

技术栈 MUST 遵循以下约束，变更需经宪章修订流程：

| 层级 | 技术选型 | 版本要求 |
|------|---------|---------|
| 前端框架 | React + TypeScript | React 19 |
| UI 库 | shadcn/ui + Tailwind CSS | 妙搭脚手架预装 |
| 路由 | react-router-dom | 嵌套路由，已配置 |
| 图表库 | ECharts + echarts-for-react | ^6.1.0 / ~3.0.2 |
| 数据缓存 | @tanstack/react-query | 已预装 |
| UI 状态 | Zustand | 轻量，仅用于 UI 状态 |
| 后端框架 | NestJS | MVCS 架构 |
| ORM | Drizzle ORM | 妙搭脚手架预装 |
| 平台 | 飞书妙搭（Miaoda） | 应用 ID: `app_17g5uw7qhs7` |

**状态管理分工**：
- 筛选器状态 → URL query params（可分享、可后退）
- 数据缓存 → React Query cache（stale-while-revalidate）
- UI 状态 → Zustand（导航栏收起、全屏弹窗）

**禁止引入**：
- 未经评估的新依赖（优先使用妙搭预装）
- Redux / MobX 等重型状态管理（Zustand 已足够）
- 其他图表库（ECharts 已覆盖所有需求）

## Development Workflow

### 本地开发

```bash
cd merchant-review
make dev-start       # 启动开发环境（推荐）
# 或
npm run dev
```

### 发布流程

```bash
git push origin sprint/default
lark-cli apps +release-create \
  --app-id app_17g5uw7qhs7 \
  --branch sprint/default \
  --environment dev \
  --apply-reason "发布说明"
# dev 验证通过后，手动在妙搭后台发布到 online
```

### 代码审查

- 所有 PR MUST 通过 CI（lint + type-check + build）。
- pre-commit hook 自动执行 lint 检查。
- AI 助手参与代码审查时 MUST 验证是否符合本宪章六项原则。

### 数据库变更

- 开发环境：`lark-cli apps +db-execute --environment dev --sql "..."`
- 同步到线上：`+db-env-migrate` 从 dev 同步到 online
- 禁止直接操作线上数据库

## Governance

本宪章是 BIDashboard 项目的最高准则，所有设计、开发、发布决策 MUST 遵循。

**修订流程**：
1. 提出修订提案（说明变更原因、影响范围、迁移计划）
2. 用户审批（MUST 经用户明确同意）
3. 更新本宪章版本号（遵循语义化版本）
4. 同步更新所有依赖模板（plan/spec/tasks/checklist）
5. 提交 commit：`docs: amend constitution to vX.Y.Z`

**版本策略**：
- MAJOR：原则删除或不兼容重定义
- MINOR：新增原则或实质性扩展
- PATCH：措辞澄清、非语义优化

**合规审查**：
- 所有 PR / 代码审查 MUST 验证是否符合宪章原则
- 复杂性 MUST 有正当理由（YAGNI 原则）
- 开发过程中的运行时指导参考 `merchant-review/CLAUDE.md`

**Version**: 1.0.0 | **Ratified**: 2026-10-18 | **Last Amended**: 2026-10-18
