# Implementation Plan: 概览页面数据表格

**Feature Branch**: `002-overview-data-tables`

**Created**: 2026-10-19

**Spec**: [spec.md](./spec.md)

---

## Technical Context

### Technology Stack

| Layer | Technology | Version | Notes |
|-------|-----------|---------|-------|
| Frontend | React + TypeScript | 19.x | 妙搭脚手架预装 |
| UI Library | shadcn/ui + Tailwind CSS | Latest | 妙搭脚手架预装 |
| Backend | NestJS | Latest | MVCS 架构 |
| ORM | Drizzle ORM | Latest | 妙搭脚手架预装 |
| Database | PostgreSQL | Latest | 妙搭应用库 |
| Platform | 飞书妙搭 (Miaoda) | app_17g5uw7qhs7 | 工作分支 sprint/default |

### Data Sources

**ADS 同步表**（数仓 → 妙搭库，每日同步）：
- `ads_category_daily` — 日 × 四级类目
- `ads_merchant_category_daily` — 日 × 类目 × 商家
- `ads_sku_daily` — 日 × SKU（每日全量快照）
- `ads_mall_daily` — 日 × 商城（商城登录店铺数、商城曝光店铺数）
- `ads_mall_cat1_daily` — 日 × 商城 × 一级类目（日活覆盖率分母）

**目标表**（飞书多维表格 → 妙搭库，插件同步）：
- `biz_category_target` — 四级类目目标
- `biz_merchant_category_target` — 商家×品类目标
- `biz_sku_target` — 商品目标

**Top 榜单表**（暂缺数据，表头需呈现）：
- `ads_top_stat_daily` — 多类型 Top 榜单（长表）

### Key Dependencies

- 数据需求与表设计 v0.5（ADS 表结构）
- 计算口径与业务规则 v0.1（计算公式）
- 001-frontend-mvp（前端基础设施：筛选器、表格组件、PageSection、TOC）

---

## Constitution Check

### I. Data Accuracy Gate (数据准确性门禁)

✅ **通过**
- 数据门禁：后端 API 层计算所有指标（曝光转化率、达成率、客均件数等），确保前后端口径一致
- 数据溯源：每个数值可追溯到具体 ADS 表字段和计算公式（见 spec.md FR-017 ~ FR-023）
- 人工校验：数据上线前需经过人工校验（由业务方执行）

### II. Diagnostic Flow Alignment (诊断流程对齐)

✅ **通过**
- 页面层级：概览页是诊断起点，展示全局数据
- 下钻路径：品类 → 商家 → SKU（通过筛选器联动实现）
- URL 参数：使用 `categoryLevel4Id` / `merchantId` / `skuId` 命名（符合宪章要求）

### III. Design System Fidelity (设计系统一致性)

✅ **通过**
- 色彩：使用 Fresh Produce BI 设计系统 token
- 字体：Plus Jakarta Sans（标题）+ Inter（正文）
- 组件：使用 shadcn/ui + Tailwind CSS

### IV. Platform-First Development (妙搭平台优先)

✅ **通过**
- 数据库：使用妙搭应用库（PostgreSQL）
- 插件：飞书多维表格同步使用 `@official-plugins/feishu-bitable` 插件
- 依赖：优先使用妙搭脚手架预装依赖

### V. Dev-Verify-Publish Workflow (开发-验证-发布)

✅ **通过**
- 开发分支：`sprint/default`
- 发布流程：`git push` → `lark-cli +release-create --environment dev` → dev 验证 → 手动发布 online
- AI 助手不自动执行 `git commit` 或 `git push`

### VI. Phased Iteration (分阶段迭代)

✅ **通过**
- MVP 范围：三个表格的基础功能（分页、排序、筛选器联动、全屏放大）
- Top 相关数据暂缺，表头需呈现（后续迭代填充）
- 验证计划：第 1-2 周原型验证（加载 < 10s）→ 第 3-4 周试运行（复盘 < 1h）

---

## Phase 0: Outline & Research

### Research Tasks

#### R1: 数据库表结构设计

**Decision**: 创建 ADS 同步表和目标表的镜像表，遵循镜像原则（应用表 = ADS 全部列 + 系统列）

**Rationale**: 
- 镜像原则确保数据同步的幂等性和可重跑性
- 系统列（`_synced_at`, `_sync_batch_id`）用于同步日志和排障
- 唯一索引 = ADS 唯一键，支撑 upsert 操作

**Alternatives considered**: 
- 方案 A：应用侧重新设计表结构（拒绝：增加同步复杂度）
- 方案 B：直接查询数仓（拒绝：性能和网络可达性风险）

**Output**: `data-model.md`

---

#### R2: 后端 API 设计

**Decision**: 提供概览页面数据 API，支持按日期范围、四级类目、商家、商品筛选，返回三个表格的数据

**Rationale**:
- 单一 API 返回三个表格数据，减少前端往返
- 后端负责计算逻辑（曝光转化率、达成率等），前端只负责展示
- 支持日期窗口聚合（近 7/15/30 天），按指标类型区分聚合方式

**Alternatives considered**:
- 方案 A：三个独立 API（拒绝：增加前端复杂度）
- 方案 B：前端计算指标（拒绝：前后端口径不一致风险）

**Output**: `contracts/overview-api.md`

---

#### R3: 前端组件设计

**Decision**: 复用 001-frontend-mvp 的基础设施（DataTable、PageSection、TOC、FilterBar），新增三个表格组件

**Rationale**:
- 复用已有组件，降低开发成本
- 保持全局一致性（分页、排序、全屏放大交互）
- 垂直堆叠布局 + TOC 跳转，符合 BI 看板标准做法

**Alternatives considered**:
- 方案 A：Tab 切换（拒绝：无法同时对比不同维度）
- 方案 B：左侧导航 + 右侧内容（拒绝：增加交互复杂度）

**Output**: `contracts/frontend-components.md`

---

## Phase 1: Design & Contracts

### 1.1 Data Model

**Output**: `data-model.md`

**Entities**:
- `ads_category_daily` — 日 × 四级类目（35 个指标字段）
- `ads_merchant_category_daily` — 日 × 类目 × 商家（38 个指标字段）
- `ads_sku_daily` — 日 × SKU（77 个指标字段）
- `biz_category_target` — 四级类目目标
- `biz_merchant_category_target` — 商家×品类目标
- `biz_sku_target` — 商品目标

**Relationships**:
- `ads_category_daily` JOIN `biz_category_target` ON (dt, mall_id, category_level4_id)
- `ads_merchant_category_daily` JOIN `biz_merchant_category_target` ON (dt, mall_id, category_level4_id, merchant_name)
- `ads_sku_daily` JOIN `biz_sku_target` ON (dt, sku_id)

---

### 1.2 Interface Contracts

**Output**: `contracts/overview-api.md`

**API Endpoint**:
```
GET /api/overview
```

**Query Parameters**:
- `dateStart` — 开始日期（YYYY-MM-DD）
- `dateEnd` — 结束日期（YYYY-MM-DD）
- `dateWindow` — 日期窗口（7/15/30）
- `categoryLevel4Id` — 四级类目 ID（可选）
- `merchantId` — 商家 ID（可选）
- `skuId` — 商品 ID（可选）
- `page` — 页码（默认 1）
- `pageSize` — 每页条数（默认 20）
- `sortBy` — 排序字段
- `sortOrder` — 排序方向（asc/desc）

**Response**:
```json
{
  "categoryTable": {
    "data": [...],
    "total": 100,
    "page": 1,
    "pageSize": 20
  },
  "merchantCategoryTable": {
    "data": [...],
    "total": 200,
    "page": 1,
    "pageSize": 20
  },
  "productTable": {
    "data": [...],
    "total": 300,
    "page": 1,
    "pageSize": 20
  }
}
```

---

### 1.3 Quickstart Validation Guide

**Output**: `quickstart.md`

**Prerequisites**:
- 数据库已创建 ADS 同步表和目标表
- 后端 API 已启动
- 前端开发服务器已启动

**Validation Scenarios**:

**Scenario 1: 四级类目表格加载**
1. 打开概览页面
2. 验证四级类目表格显示第一页数据
3. 验证表头包含所有定义的列（包括 Top 相关列）
4. 验证表格支持分页、排序

**Scenario 2: 筛选器联动**
1. 在筛选器中选择四级类目"红富士苹果"
2. 验证三个表格同步刷新
3. 验证 URL 参数更新为 `?categoryLevel4Id=1001`

**Scenario 3: 全屏放大**
1. 点击四级类目表格的全屏按钮
2. 验证弹窗居中显示
3. 验证弹窗支持缩放
4. 验证弹窗内表格保留分页

**Scenario 4: TOC 跳转**
1. 查看右侧 TOC
2. 点击"商家四级类目"
3. 验证页面平滑滚动到商家四级类目表格

---

### 1.4 Agent Context Update

**Output**: 更新 `CLAUDE.md` 中的 plan reference

---

## Implementation Phases

### Phase 1: Database Setup (1-2 days)

**Tasks**:
1. 创建 ADS 同步表的镜像表（ads_category_daily, ads_merchant_category_daily, ads_sku_daily）
2. 创建目标表的镜像表（biz_category_target, biz_merchant_category_target, biz_sku_target）
3. 创建必要的索引
4. 验证表结构和索引

**Deliverables**:
- Drizzle schema 文件
- 数据库迁移脚本
- 表结构验证文档

---

### Phase 2: Backend API Development (2-3 days)

**Tasks**:
1. 实现概览页面数据 API（GET /api/overview）
2. 实现日期窗口聚合逻辑（按指标类型区分）
3. 实现计算逻辑（曝光转化率、达成率、客均件数等）
4. 实现分页和排序
5. 编写单元测试

**Deliverables**:
- NestJS Controller 和 Service
- 计算逻辑工具函数
- API 测试用例

---

### Phase 3: Frontend Development (2-3 days)

**Tasks**:
1. 修改概览页面布局（垂直堆叠三个 PageSection）
2. 实现三个表格组件（四级类目、商家四级类目、商品）
3. 实现固定列策略（品类表固定第一列，商家表固定第二列，商品表固定第三列）
4. 实现 TOC 跳转
5. 实现全屏放大功能
6. 实现独立加载状态和错误处理
7. 对接后端 API

**Deliverables**:
- 概览页面组件
- 三个表格组件
- 全屏弹窗组件
- API 对接代码

---

### Phase 4: Integration & Testing (1-2 days)

**Tasks**:
1. 端到端测试（筛选器联动、分页、排序、全屏放大、TOC 跳转）
2. 性能测试（加载时间 < 10s）
3. 边界场景测试（空数据、无效 ID、网络错误）
4. 修复 bug

**Deliverables**:
- 测试报告
- Bug 修复记录

---

### Phase 5: Deployment & Validation (1 day)

**Tasks**:
1. 发布到 dev 环境
2. 业务方验证数据准确性
3. 修复问题
4. 手动发布到 online

**Deliverables**:
- 发布记录
- 验证报告

---

## Risk & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Top 相关数据暂缺 | 中 | 表头正常显示，单元格显示占位符，不影响其他列 |
| 数据同步延迟 | 高 | 使用 sys_sync_log 监控同步状态，异常时告警 |
| 性能问题（加载 > 10s） | 高 | 优化 SQL 查询，添加索引，必要时引入缓存 |
| 前后端口径不一致 | 高 | 所有计算逻辑由后端实现，前端只负责展示 |

---

## Success Metrics

- **SC-001**: 用户打开概览页面后，三个表格在 10 秒内完成加载
- **SC-002**: 用户通过筛选器切换条件后，三个表格在 3 秒内完成刷新
- **SC-003**: 用户刷新页面后，筛选条件 100% 保留
- **SC-004**: 表格分页、排序、全屏放大等交互功能 100% 可用
- **SC-005**: Top 相关字段暂无数据时，表头正常显示，单元格显示占位符

---

## Next Steps

1. 执行 Phase 1: Database Setup
2. 执行 Phase 2: Backend API Development
3. 执行 Phase 3: Frontend Development
4. 执行 Phase 4: Integration & Testing
5. 执行 Phase 5: Deployment & Validation
