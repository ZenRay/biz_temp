# Research: 概览页面数据表格

**Feature**: 002-overview-data-tables
**Created**: 2026-10-19
**Status**: Complete

---

## R1: 数据库表结构设计

### Decision

创建 ADS 同步表和目标表的镜像表，遵循镜像原则（应用表 = ADS 全部列 + 系统列）。

### Rationale

1. **镜像原则**确保数据同步的幂等性和可重跑性
2. **系统列**（`_synced_at`, `_sync_batch_id`）用于同步日志和排障
3. **唯一索引 = ADS 唯一键**，支撑 upsert 操作
4. **查询索引**按页面查询模式建，支撑高性能查询

### Alternatives Considered

**方案 A: 应用侧重新设计表结构**
- ❌ 拒绝原因：增加同步复杂度，违反镜像原则
- ❌ 需要维护两套表结构映射关系

**方案 B: 直接查询数仓**
- ❌ 拒绝原因：性能和网络可达性风险
- ❌ 飞书云 → 内网数仓网络不稳定
- ❌ 无法实现目标表与 ADS 表的同库 join

**方案 C: 使用视图或物化视图**
- ❌ 拒绝原因：妙搭平台不支持复杂的视图定义
- ❌ 物化视图刷新机制与同步策略冲突

### Implementation Details

**ADS 同步表**（3 张）：

1. **ads_category_daily** — 日 × 四级类目
   - 唯一键：(dt, mall_id, category_level4_id)
   - 索引：(dt), (mall_id, dt), (category_level4_id, dt)
   - 指标字段：35 个（见《数据需求与表设计 v0.5》2.2）

2. **ads_merchant_category_daily** — 日 × 类目 × 商家
   - 唯一键：(dt, mall_id, category_level4_id, merchant_id)
   - 索引：(dt), (mall_id, dt), (category_level4_id, dt), (merchant_id, dt)
   - 指标字段：38 个（见《数据需求与表设计 v0.5》2.3）

3. **ads_sku_daily** — 日 × SKU（每日全量快照）
   - 唯一键：(dt, mall_id, sku_id)
   - 索引：(dt), (mall_id, dt), (category_level4_id, dt), (merchant_id, dt), (sku_id, dt)
   - 指标字段：77 个（见《数据需求与表设计 v0.5》2.4）

**目标表**（3 张）：

1. **biz_category_target** — 四级类目目标
   - 唯一键：(dt, mall_id, category_level4_id)
   - 索引：(dt), (mall_id, dt), (category_level4_id, dt)
   - 字段：10 个（见《数据需求与表设计 v0.5》4.1）

2. **biz_merchant_category_target** — 商家×品类目标
   - 唯一键：(dt, mall_id, category_level4_id, merchant_name)
   - 索引：(dt), (mall_id, dt), (category_level4_id, dt), (merchant_name, dt)
   - 字段：10 个（见《数据需求与表设计 v0.5》4.3）

3. **biz_sku_target** — 商品目标
   - 唯一键：(dt, sku_id)
   - 索引：(dt), (sku_id, dt)
   - 字段：待确认（见《数据需求与表设计 v0.5》4.2）

**系统列**（每张表附加）：
- `_synced_at timestamptz` — 本行写入时间
- `_sync_batch_id varchar` — 批次号（排障、回滚定位）

**数据保留策略**：
- 应用库滚动 90 天（定时清理）
- 长期历史留数仓

---

## R2: 后端 API 设计

### Decision

提供概览页面数据 API，支持按日期范围、四级类目、商家、商品筛选，返回三个表格的数据。

### Rationale

1. **单一 API** 返回三个表格数据，减少前端往返
2. **后端负责计算逻辑**（曝光转化率、达成率等），前端只负责展示
3. **支持日期窗口聚合**（近 7/15/30 天），按指标类型区分聚合方式
4. **支持分页和排序**，满足大数据量场景

### Alternatives Considered

**方案 A: 三个独立 API**
- ❌ 拒绝原因：增加前端复杂度，需要三次网络请求
- ❌ 无法保证三个表格数据的一致性（可能跨日期）

**方案 B: 前端计算指标**
- ❌ 拒绝原因：前后端口径不一致风险
- ❌ 违反宪章 I. Data Accuracy Gate（数据准确性门禁）

**方案 C: GraphQL API**
- ❌ 拒绝原因：妙搭脚手架预装 REST，引入 GraphQL 增加复杂度
- ❌ 违反宪章 IV. Platform-First Development（妙搭平台优先）

### Implementation Details

**API Endpoint**:
```
GET /api/overview
```

**Query Parameters**:
- `dateStart` — 开始日期（YYYY-MM-DD，必填）
- `dateEnd` — 结束日期（YYYY-MM-DD，必填）
- `dateWindow` — 日期窗口（7/15/30，可选，用于聚合）
- `categoryLevel4Id` — 四级类目 ID（可选）
- `merchantId` — 商家 ID（可选）
- `skuId` — 商品 ID（可选）
- `page` — 页码（默认 1）
- `pageSize` — 每页条数（默认 20）
- `sortBy` — 排序字段（可选）
- `sortOrder` — 排序方向（asc/desc，默认 asc）

**Response Structure**:
```typescript
interface OverviewResponse {
  categoryTable: {
    data: CategoryTableRow[];
    total: number;
    page: number;
    pageSize: number;
  };
  merchantCategoryTable: {
    data: MerchantCategoryTableRow[];
    total: number;
    page: number;
    pageSize: number;
  };
  productTable: {
    data: ProductTableRow[];
    total: number;
    page: number;
    pageSize: number;
  };
}
```

**聚合逻辑**（按指标类型区分）：

1. **存量指标**（显示窗口内最新一天的值）：
   - 曝光门店数（exposed_store_num）
   - 登录店铺数（logon_store_num）
   - 曝光店铺数（exposed_store_num）

2. **流量指标**（求和）：
   - 货值（delivered_goods_amt）
   - 下单件数（ordered_goods_num）
   - 平台盈余金额（platform_surplus_amt）
   - 平台抽佣金额（platform_commission_amt）
   - 平台承担赔付金额（platform_refund_amt）
   - 平台补贴金额（platform_subsidy_amt）

3. **比率指标**（基于聚合后的流量指标重新计算）：
   - 曝光转化率 = 下单店铺数 / 曝光店铺数
   - 货值目标达成率 = 货值 / 货值目标
   - 客均件数 = 下单件数 / 下单店铺数
   - 平台毛利率 = 平台盈余金额 / 货值
   - 日活覆盖率 = 下单店铺数 / 一级类目下单店铺数
   - 货值占比 = 当前粒度货值 / 上级粒度货值

**计算逻辑**（见《计算口径与业务规则 v0.1》）：
- 曝光转化率：2.1
- 平台盈余金额：2.2
- 平台毛利率：2.3
- 日活覆盖率：2.5
- 货值目标达成率：2.10
- 客均件数：2.11
- 货值占比：3.1

**错误处理**：
- 400: 参数错误（日期格式不正确、必填参数缺失）
- 404: 数据不存在（指定日期范围无数据）
- 500: 服务器内部错误（数据库查询失败）

---

## R3: 前端组件设计

### Decision

复用 001-frontend-mvp 的基础设施（DataTable、PageSection、TOC、FilterBar），新增三个表格组件。

### Rationale

1. **复用已有组件**，降低开发成本
2. **保持全局一致性**（分页、排序、全屏放大交互）
3. **垂直堆叠布局 + TOC 跳转**，符合 BI 看板标准做法
4. **固定列策略**提升宽表格的可读性

### Alternatives Considered

**方案 A: Tab 切换**
- ❌ 拒绝原因：无法同时对比不同维度
- ❌ 用户需要频繁切换，降低复盘效率

**方案 B: 左侧导航 + 右侧内容**
- ❌ 拒绝原因：增加交互复杂度
- ❌ 与现有 001-frontend-mvp 的布局不一致

**方案 C: 自定义表格组件**
- ❌ 拒绝原因：重复造轮子，违反宪章 IV. Platform-First Development
- ❌ 无法复用 001-frontend-mvp 的全屏放大、排序等交互

### Implementation Details

**页面布局**：
```
概览页面
├── PageSection: 四级类目
│   ├── 标题: "四级类目"
│   ├── 说明: "品类维度的核心指标概览"
│   └── DataTable: CategoryTable
│       ├── 固定列: 第一列（四级类目名称）
│       ├── 分页: 默认 20 条/页
│       ├── 排序: 支持所有列
│       └── 全屏: 支持放大弹窗
├── PageSection: 商家四级类目
│   ├── 标题: "商家四级类目"
│   ├── 说明: "商家×品类维度的核心指标概览"
│   └── DataTable: MerchantCategoryTable
│       ├── 固定列: 第二列（商家名称）
│       ├── 可隐藏列: 第一列（四级类目名称）
│       ├── 默认排序: 四级类目
│       ├── 分页: 默认 20 条/页
│       ├── 排序: 支持所有列
│       └── 全屏: 支持放大弹窗
└── PageSection: 商品
    ├── 标题: "商品"
    ├── 说明: "商品维度的核心指标概览"
    └── DataTable: ProductTable
        ├── 固定列: 第三列（商品名称）
        ├── 可隐藏列: 第一列（四级类目名称）、第二列（商家名称）
        ├── 默认排序: 四级类目、商家
        ├── 分页: 默认 20 条/页
        ├── 排序: 支持所有列
        └── 全屏: 支持放大弹窗
```

**固定列策略**：

1. **四级类目表**：
   - 固定第一列（四级类目名称）
   - 其余列可水平滚动

2. **商家四级类目表**：
   - 固定第二列（商家名称）
   - 第一列（四级类目名称）可隐藏（水平滚动时自动隐藏）
   - 默认排序为四级类目

3. **商品表**：
   - 固定第三列（商品名称）
   - 前两列（四级类目名称、商家名称）可隐藏（水平滚动时自动隐藏）
   - 默认排序为四级类目、商家

**TOC 跳转**：
- 右侧 TOC 自动生成，显示三个 section 标题
- 点击后平滑滚动到对应表格
- 使用 `scrollIntoView({ behavior: 'smooth' })` 实现

**全屏放大**：
- 复用 001-frontend-mvp 的全屏弹窗组件
- 支持缩放（最小初始大小，最大填满页面 100%）
- 支持三种关闭方式（ESC 键、点击弹窗外部、关闭按钮）
- 弹窗内表格保留分页和独立滚动功能

**加载状态与错误处理**：
- 每个表格独立显示加载状态（loading spinner）
- 某个表格加载失败时，仅该表格显示错误提示和重试按钮
- 重试按钮点击后，仅重新加载失败的表格数据

**组件复用**：
- `DataTable` — 来自 001-frontend-mvp
- `PageSection` — 来自 001-frontend-mvp
- `TOC` — 来自 001-frontend-mvp
- `FilterBar` — 来自 001-frontend-mvp
- `FullscreenModal` — 来自 001-frontend-mvp

---

## Summary

所有研究任务已完成，决策已确定：

1. **数据库表结构**：遵循镜像原则，创建 ADS 同步表和目标表的镜像表
2. **后端 API**：单一 API 返回三个表格数据，后端负责计算逻辑
3. **前端组件**：复用 001-frontend-mvp 基础设施，垂直堆叠布局 + TOC 跳转

所有决策符合宪章要求，无 NEEDS CLARIFICATION 标记。

**下一步**：进入 Phase 1，生成 data-model.md、contracts/、quickstart.md。
