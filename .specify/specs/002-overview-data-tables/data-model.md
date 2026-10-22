# Data Model: 概览页面数据表格

**Feature**: 002-overview-data-tables
**Created**: 2026-10-19
**Status**: Draft

---

## Overview

本文档定义概览页面三个数据表格（四级类目、商家四级类目、商品）的数据模型，包括 ADS 同步表、目标表、实体关系和验证规则。

---

## Entities

### 1. ADS 同步表

#### 1.1 ads_category_daily（日 × 四级类目）

**Description**: 四级类目维度的日粒度数据，支撑品类分析页和概览页的四级类目表。

**Fields**:
```typescript
interface AdsCategoryDaily {
  // 维度字段
  dt: Date;                          // 统计日期
  mall_id: string;                   // 商城 ID
  mall_name: string;                 // 商城名称
  category_level4_id: string;        // 四级类目 ID
  category_level4_name: string;      // 四级类目名称
  category_level1_id: string;        // 一级类目 ID
  category_level1_name: string;      // 一级类目名称
  
  // 漏斗指标
  exposed_store_num: number;         // 曝光门店数
  clicked_store_num: number;         // 点击门店数
  added_store_num: number;           // 加购门店数
  ordered_store_num: number;         // 下单门店数
  
  // 交易指标
  ordered_goods_num: number;         // 下单件数
  ordered_goods_num_ps: number;      // 客均件数
  delivered_goods_amt: number;       // 货值
  delivered_goods_amt_ps: number;    // 客均货值
  delivered_goods_num: number;       // 送达件数
  commission_amt: number;            // 平台抽佣金额
  subsidy_amt_plat: number;          // 平台补贴金额
  refund_amt_by_asdt_plat: number;   // 平台承担赔付金额
  
  // 售后指标
  refund_amt: number;                // 赔付金额
  applied_after_sale_goods_num: number; // 售后商品数量
  
  // T-7 售后复购指标
  applied_store_num_by_asdt: number; // 提交日售后门店数
  
  // BD 分享指标
  shared_links_cnt: number;          // 分享链接次数
  shared_links_store_num: number;    // 分享触达门店数
  exposed_store_num_by_share_links: number; // 分享链接曝光门店数
  clicked_store_num_by_share_links: number; // 分享链接点击门店数
  ordered_store_num_by_share_links: number; // 分享链接下单门店数
  
  // 客池指标
  ordered_store_num_old_store: number; // 老客户下单门店数
  ordered_store_num_new_store: number; // 新客户下单门店数
  ordered_store_num_loss_store: number; // 流失客户下单门店数
  exposed_store_num_old_store: number; // 老客户曝光门店数
  exposed_store_num_new_store: number; // 新客户曝光门店数
  exposed_store_num_loss_store: number; // 流失客户曝光门店数
  
  // 上架状态指标
  onshelved_mall_num: number;        // 上架中心仓数量
  
  // 30 日曝光频次分布（JSON）
  store_num_by_exposed_30d_info: string;
  logon_store_num_by_exposed_30d_info: string;
  exposed_store_num_by_exposed_30d_info: string;
  ordered_store_num_by_exposed_30d_info: string;
  
  // 30 日下单频次分布（JSON）
  store_num_by_ordered_30d_info: string;
  logon_store_num_by_ordered_30d_info: string;
  exposed_store_num_by_ordered_30d_info: string;
  ordered_store_num_by_ordered_30d_info: string;
  
  // 系统列
  _synced_at: Date;                  // 同步时间
  _sync_batch_id: string;            // 批次号
}
```

**Validation**:
- 唯一键：(dt, mall_id, category_level4_id)
- 索引：(dt), (mall_id, dt), (category_level4_id, dt)
- dt: 必填，日期格式
- mall_id: 必填，非空字符串
- category_level4_id: 必填，非空字符串
- 所有指标字段：可为 0 或 NULL，不能为负数

**Relationships**:
- JOIN biz_category_target ON (dt, mall_id, category_level4_id) → 获取目标数据
- JOIN ads_mall_cat1_daily ON (dt, mall_id, category_level1_id) → 获取一级类目数据（日活覆盖率分母）

---

#### 1.2 ads_merchant_category_daily（日 × 类目 × 商家）

**Description**: 商家×四级类目维度的日粒度数据，支撑商家品类分析页和概览页的商家四级类目表。

**Fields**:
```typescript
interface AdsMerchantCategoryDaily {
  // 维度字段
  dt: Date;
  mall_id: string;
  mall_name: string;
  category_level4_id: string;
  category_level4_name: string;
  category_level1_id: string;
  category_level1_name: string;
  merchant_id: string;             // 商家 ID
  merchant_name: string;           // 商家名称
  merchant_type: string;           // 商家类型
  
  // 漏斗指标（同 ads_category_daily）
  exposed_store_num: number;
  clicked_store_num: number;
  added_store_num: number;
  ordered_store_num: number;
  
  // 交易指标（同 ads_category_daily）
  ordered_goods_num: number;
  ordered_goods_num_ps: number;
  delivered_goods_amt: number;
  delivered_goods_amt_ps: number;
  delivered_goods_num: number;
  commission_amt: number;
  subsidy_amt_plat: number;
  refund_amt_by_asdt_plat: number;
  
  // 售后指标（同 ads_category_daily）
  refund_amt: number;
  refund_amt_by_mct: number;       // 商家承担赔付金额（商家特有）
  applied_after_sale_goods_num: number;
  
  // T-7 售后复购指标
  applied_store_num_by_asdt: number;
  rebuy_store_num_cdta26d_applied_asdt: number; // 售后七日复购门店数
  rebuy_store_num_cdta2d_applied_asdt: number;  // 售后三日复购门店数
  
  // BD 分享指标（同 ads_category_daily）
  shared_links_cnt: number;
  shared_links_store_num: number;
  exposed_store_num_by_share_links: number;
  clicked_store_num_by_share_links: number;
  ordered_store_num_by_share_links: number;
  
  // 客池指标（同 ads_category_daily + 客池总数）
  pool_num_old_store: number;      // 老客户池门店数
  pool_num_new_store: number;      // 新客户池门店数
  pool_num_loss_store: number;     // 流失客户池门店数
  ordered_store_num_old_store: number;
  ordered_store_num_new_store: number;
  ordered_store_num_loss_store: number;
  exposed_store_num_old_store: number;
  exposed_store_num_new_store: number;
  exposed_store_num_loss_store: number;
  
  // 商家特有指标
  mct_market_fee_amt_new_store: number;    // 新客户营销费用
  mct_market_fee_amt_loss_store: number;   // 流失客户营销费用
  delivered_goods_amt_new_store_mmf: number; // 新客户营销产生货值
  delivered_goods_amt_loss_store_mmf: number; // 流失客户营销产生货值
  applied_after_sale_ticket_num_by_asdt: number; // 售后单数量
  applied_after_sale_ticket_num_by_asdt_info: string; // 售后单类型分布（JSON）
  
  // 系统列
  _synced_at: Date;
  _sync_batch_id: string;
}
```

**Validation**:
- 唯一键：(dt, mall_id, category_level4_id, merchant_id)
- 索引：(dt), (mall_id, dt), (category_level4_id, dt), (merchant_id, dt)
- 所有字段验证规则同 ads_category_daily

**Relationships**:
- JOIN biz_merchant_category_target ON (dt, mall_id, category_level4_id, merchant_name) → 获取目标数据和 L1/L2 等级
- JOIN ads_category_daily ON (dt, mall_id, category_level4_id) → 获取四级类目汇总数据（货值占比分母）

---

#### 1.3 ads_sku_daily（日 × SKU，每日全量快照）

**Description**: 商品维度的日粒度数据（每日全量快照），支撑商品分析页和概览页的商品表。

**Fields**:
```typescript
interface AdsSkuDaily {
  // 维度字段
  dt: Date;
  mall_id: string;
  mall_name: string;
  category_level4_id: string;
  category_level4_name: string;
  category_level1_id: string;
  category_level1_name: string;
  merchant_id: string;
  merchant_name: string;
  sku_id: string;                  // 商品 ID
  sku_name: string;                // 商品名称
  
  // 漏斗指标（同 ads_merchant_category_daily）
  exposed_store_num: number;
  clicked_store_num: number;
  added_store_num: number;
  ordered_store_num: number;
  
  // 交易指标（同 ads_merchant_category_daily）
  ordered_goods_num: number;
  ordered_goods_num_ps: number;
  delivered_goods_amt: number;
  delivered_goods_amt_ps: number;
  delivered_goods_num: number;
  commission_amt: number;
  subsidy_amt_plat: number;
  refund_amt_by_asdt_plat: number;
  
  // 售后指标（同 ads_merchant_category_daily）
  refund_amt: number;
  refund_amt_by_mct: number;
  applied_after_sale_goods_num: number;
  
  // T-7 售后复购指标
  applied_store_num_by_asdt: number;
  rebuy_store_num_cdta6d_applied_asdt: number; // 售后七日复购门店数
  rebuy_store_num_cdta2d_applied_asdt: number; // 售后三日复购门店数
  
  // BD 分享指标（同 ads_merchant_category_daily）
  shared_links_cnt: number;
  shared_links_store_num: number;
  exposed_store_num_by_share_links: number;
  clicked_store_num_by_share_links: number;
  ordered_store_num_by_share_links: number;
  
  // 客池指标（同 ads_merchant_category_daily）
  pool_num_old_store: number;
  pool_num_new_store: number;
  pool_num_loss_store: number;
  ordered_store_num_old_store: number;
  ordered_store_num_new_store: number;
  ordered_store_num_loss_store: number;
  exposed_store_num_old_store: number;
  exposed_store_num_new_store: number;
  exposed_store_num_loss_store: number;
  
  // 30 日曝光频次分布（JSON，同 ads_category_daily）
  store_num_by_exposed_30d_info: string;
  logon_store_num_by_exposed_30d_info: string;
  exposed_store_num_by_exposed_30d_info: string;
  ordered_store_num_by_exposed_30d_info: string;
  
  // 30 日下单频次分布（JSON，同 ads_category_daily）
  store_num_by_ordered_30d_info: string;
  logon_store_num_by_ordered_30d_info: string;
  exposed_store_num_by_ordered_30d_info: string;
  ordered_store_num_by_ordered_30d_info: string;
  
  // 商家营销与售后指标（同 ads_merchant_category_daily）
  mct_market_fee_amt_new_store: number;
  mct_market_fee_amt_loss_store: number;
  delivered_goods_amt_new_store_mmf: number;
  delivered_goods_amt_loss_store_mmf: number;
  applied_after_sale_ticket_num_by_asdt: number;
  applied_after_sale_ticket_num_by_asdt_info: string;
  
  // 商品属性
  origin_place: string;            // 产地
  product_class: string;           // 等级
  product_spec: string;            // 规格
  product_variety: string;         // 品种
  brand_name: string;              // 品牌
  merit: string;                   // 商品卖点
  
  // 商品状态
  is_onshelved: number;            // 是否上架（0/1）
  is_valid: number;                // 是否有效（0/1）
  onshelved_cnt_7d: number;        // 7 日内上架天数
  
  // 商品更新动态
  updated_video_gap: number;       // 最近视频更新间隔天数
  updated_main_pic_gap: number;    // 最近主图更新间隔天数
  is_updated_merit: number;        // 是否更新卖点（0/1）
  
  // 商品分类
  invalid_sku_type: string;        // 无效 SKU 类型
  potential_sku_type: string;      // 潜力 SKU 类型
  
  // 商品排名
  delivered_goods_amt_desc_rnk_by_mall_cat4: number; // 同品类货值排名
  ordered_store_num_desc_rnk_by_mall_cat4: number;   // 同品类下单门店数排名
  
  // 其他统计指标
  delivered_goods_amt_pg: number;  // 件单价
  cat4_in_cat1_store_ratio: number; // 日活覆盖率
  cat4_in_cat1_store_ratio_rnk: number; // 日活覆盖率排名
  exposed_store_num_desc_rnk_by_mall: number; // 曝光门店数排名
  exposed2ordered_store_ratio: number; // 曝光转化率
  exposed2store_store_ratio_desc_rnk_by_mall: number; // 曝光转化率排名
  exposed2store_store_ratio_desc_rnk_by_mall_cat4: number; // 同品类曝光转化率排名
  exposed2store_store_ratio_desc_rnk_by_mall_cat4_mct: number; // 同品类同商家曝光转化率排名
  exposed2store_store_ratio_desc_rnk_by_cat4: number; // 跨中心仓同品类曝光转化率排名
  exposed2store_store_ratio_desc_rnk_by_non: number; // 跨中心仓曝光转化率排名
  exposed_store_ratio_by_mall: number; // 曝光门店数占商城比例
  exposed_store_ratio_by_mall_desc_rnk_by_cat4: number; // 跨仓曝光门店数占商城比例排名
  exposed_store_ratio_by_cat4: number; // 曝光门店数占四级类目比例
  exposed_store_ratio_by_cat4_desc_rnk_by_mall_cat4: number; // 同品类曝光门店数占四级类目比例排名
  exposed_store_ratio_by_cat4_desc_rnk_by_cat4: number; // 同品类曝光门店数占四级类目比例排名
  
  // 系统列
  _synced_at: Date;
  _sync_batch_id: string;
}
```

**Validation**:
- 唯一键：(dt, mall_id, sku_id)
- 索引：(dt), (mall_id, dt), (category_level4_id, dt), (merchant_id, dt), (sku_id, dt)
- 所有字段验证规则同 ads_category_daily
- **每日全量快照**：必须包含所有 SKU×商家×类目组合，当日无销售的行指标为 0/NULL

**Relationships**:
- JOIN biz_sku_target ON (dt, sku_id) → 获取目标数据
- JOIN ads_merchant_category_daily ON (dt, mall_id, category_level4_id, merchant_id) → 获取商家四级类目汇总数据（货值占比分母）

---

### 2. 目标表

#### 2.1 biz_category_target（四级类目目标）

**Description**: 四级类目维度的目标数据，从飞书多维表格同步。

**Fields**:
```typescript
interface BizCategoryTarget {
  id: string;                      // UUID
  dt: Date;                        // 调度日期
  mall_id: string;                 // 商城 ID
  category_level4_id: string;      // 四级类目 ID
  category_name: string;           // 四级类目名称
  l1_target_amt: number;           // L1 品类目标货值
  l2_target_amt: number;           // L2 品类目标货值
  l3_target_amt: number;           // L3 品类目标货值
  start_date: Date;                // 起始日期
  end_date: Date;                  // 结束日期
  feishu_record_id: string;        // 飞书记录 ID
  _synced_at: Date;                // 同步时间
}
```

**Validation**:
- 唯一键：(dt, mall_id, category_level4_id)
- 索引：(dt), (mall_id, dt), (category_level4_id, dt)
- L1/L2/L3 是目标等级（非类目层级）

---

#### 2.2 biz_merchant_category_target（商家×品类目标）

**Description**: 商家×四级类目维度的目标数据，从飞书多维表格同步。

**Fields**:
```typescript
interface BizMerchantCategoryTarget {
  id: string;
  dt: Date;
  mall_id: string;
  category_level4_id: string;
  merchant_name: string;           // 商家名称
  merchant_level: string;          // 承接目标类型（L1/L2）
  target_goods_amt: number;        // 商家实接目标（货值）
  start_date: Date;
  end_date: Date;
  feishu_record_id: string;
  _synced_at: Date;
}
```

**Validation**:
- 唯一键：(dt, mall_id, category_level4_id, merchant_name)
- 索引：(dt), (mall_id, dt), (category_level4_id, dt), (merchant_name, dt)

---

#### 2.3 biz_sku_target（商品目标）

**Description**: 商品维度的目标数据，从飞书多维表格同步。

**Fields**:
```typescript
interface BizSkuTarget {
  id: string;
  dt: Date;
  sku_id: string;
  category_level4_id: string;      // 冗余
  target_goods_amt: number;        // 商品目标货值（待确认）
  feishu_record_id: string;
  _synced_at: Date;
}
```

**Validation**:
- 唯一键：(dt, sku_id)（待确认是否需加 category_level4_id）
- 索引：(dt), (sku_id, dt)

---

## Relationships Diagram

```
ads_category_daily ──┬── JOIN biz_category_target ──┐
                     │                              │
                     └── JOIN ads_mall_cat1_daily ──┴── 计算日活覆盖率、货值占比

ads_merchant_category_daily ──┬── JOIN biz_merchant_category_target ──┐
                              │                                       │
                              └── JOIN ads_category_daily ────────────┴── 计算货值占比、L1/L2 分层

ads_sku_daily ──┬── JOIN biz_sku_target ──────────────────────────────┐
                │                                                     │
                └── JOIN ads_merchant_category_daily ─────────────────┴── 计算货值占比
```

**关联规则**：
- 所有关联走业务 ID（mall_id / category_level4_id / merchant_id / sku_id），无物理外键
- 名称冗余在行内，减少 JOIN
- 目标表与 ADS 表来自不同同步批次，按业务键关联

---

## State Transitions

### 数据同步状态

```
数仓产出 ADS 数据
  ↓
妙搭 cron 触发同步任务
  ↓
拉取昨日分区数据
  ↓
按唯一键 upsert（幂等）
  ↓
写入 sys_sync_log（成功/失败/部分成功）
  ↓
后端 API 查询本地库
  ↓
前端展示
```

### 目标表同步状态

```
飞书多维表格更新
  ↓
妙搭插件触发同步（cron + 手动）
  ↓
searchRecords 分页拉取
  ↓
按业务键 upsert（幂等）
  ↓
写入 sys_sync_log
  ↓
后端 API 查询本地库
  ↓
前端展示
```

---

## Notes

- 所有 ADS 表遵循镜像原则：应用表 = ADS 全部列 + 系统列
- 系统列：`_synced_at`（同步时间）、`_sync_batch_id`（批次号）
- 数据保留：应用库滚动 90 天，长期历史留数仓
- 全量快照：`ads_sku_daily` 每日全量，支撑筛选下拉
- Top 相关数据：暂缺，后续通过 `ads_top_stat_daily` 补充
