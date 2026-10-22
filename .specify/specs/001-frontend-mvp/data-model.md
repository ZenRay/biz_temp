# Data Model: 商家复盘 Dashboard 前端 MVP

**Date**: 2026-10-18  
**Feature**: [spec.md](./spec.md)

## Overview

本文档定义了前端 MVP 中涉及的核心数据实体、字段、关系和验证规则。

## Entities

### 1. Category（四级类目）

**Description**: 品类分类的最基础维度，是所有筛选和下钻的起点。

**Fields**:
```typescript
interface Category {
  id: string;           // 类目 ID（如 "1001"）
  name: string;         // 类目名称（如 "红富士"）
}
```

**Validation**:
- `id`: 非空字符串，唯一标识
- `name`: 非空字符串

**Relationships**:
- 与 Merchant 多对多（一个类目可有多个商家，一个商家可经营多个类目）
- 与 SKU 一对多（一个类目下有多个 SKU）

---

### 2. Merchant（商家）

**Description**: 商家实体，经营一个或多个品类。

**Fields**:
```typescript
interface Merchant {
  id: string;           // 商家 ID（如 "2001"）
  name: string;         // 商家名称（如 "商家A"）
}
```

**Validation**:
- `id`: 非空字符串，唯一标识
- `name`: 非空字符串

**Relationships**:
- 与 Category 多对多
- 与 SKU 一对多（一个商家有多个 SKU）

---

### 3. SKU（商品）

**Description**: 最小商品单元，归属于特定商家和品类。

**Fields**:
```typescript
interface SKU {
  id: string;           // SKU ID（如 "3001"）
  name: string;         // SKU 名称（如 "SKU001"）
  categoryLevel4Id: string;   // 所属类目 ID
  merchantId: string;   // 所属商家 ID
}
```

**Validation**:
- `id`: 非空字符串，唯一标识
- `name`: 非空字符串
- `categoryLevel4Id`: 必须引用有效的 Category.id
- `merchantId`: 必须引用有效的 Merchant.id

**Relationships**:
- 属于 Category（多对一）
- 属于 Merchant（多对一）

---

### 4. FilterState（筛选条件）

**Description**: 用户选择的筛选参数组合，通过 URL query params 管理。

**Fields**:
```typescript
interface FilterState {
  dateWindow?: '7' | '15' | '30';  // 日期窗口（天）
  dateStart?: string;              // 开始日期（YYYY-MM-DD）
  dateEnd?: string;                // 结束日期（YYYY-MM-DD）
  categoryLevel4Id?: string;             // 四级类目 ID
  merchantId?: string;             // 商家 ID
  skuId?: string;                  // SKU ID
}
```

**Validation**:
- `dateWindow`: 可选，枚举值 '7' | '15' | '30'
- `dateStart` / `dateEnd`: 可选，ISO 8601 日期格式
- `categoryLevel4Id` / `merchantId` / `skuId`: 可选，必须引用有效实体

**Relationships**:
- 引用 Category、Merchant、SKU（可选）

---

### 5. TableRow（表格行数据）

**Description**: 通用表格行数据结构，支持动态列。

**Fields**:
```typescript
interface TableRow {
  [key: string]: string | number | boolean | null;
  // 动态字段，根据表格类型不同而不同
  // 示例：
  // categoryLevel4Id: string
  // categoryName: string
  // merchantId: string
  // merchantName: string
  // salesAmount: number
  // achievementRate: number
}
```

**Validation**:
- 每行必须包含唯一标识字段（如 id、categoryLevel4Id、merchantId 等）
- 数值字段可为 null（表示无数据）

**Relationships**:
- 可引用 Category、Merchant、SKU

---

### 6. TableColumn（表格列定义）

**Description**: 表格列配置，定义列名、字段、可排序性、可点击性。

**Fields**:
```typescript
interface TableColumn {
  key: string;              // 字段名（对应 TableRow 的 key）
  title: string;            // 列标题（显示在表头）
  sortable?: boolean;       // 是否可排序
  clickable?: boolean;      // 是否可点击跳转
  align?: 'left' | 'center' | 'right';  // 对齐方式
  width?: number | string;  // 列宽
}
```

**Validation**:
- `key`: 非空字符串
- `title`: 非空字符串
- `sortable`: 可选，默认 false
- `clickable`: 可选，默认 false
- `align`: 可选，默认 'left'

---

### 7. SortState（排序状态）

**Description**: 表格当前排序配置。

**Fields**:
```typescript
interface SortState {
  columnKey: string | null;  // 排序字段
  direction: 'asc' | 'desc' | 'none';  // 排序方向
}
```

**Validation**:
- `columnKey`: 可为 null（无排序）
- `direction`: 枚举值 'asc' | 'desc' | 'none'

---

### 8. PageSection（页面区块）

**Description**: 页面内容区块，用于 TOC 自动生成。

**Fields**:
```typescript
interface PageSection {
  id: string;      // 区块 ID（用于锚点跳转）
  title: string;   // 区块标题（显示在 TOC）
}
```

**Validation**:
- `id`: 非空字符串，页面内唯一
- `title`: 非空字符串

---

## Relationships Diagram

```
Category (1) ←→ (N) Merchant
    ↓
    ↓ (1:N)
    ↓
   SKU (N) ← (1) Merchant

FilterState → Category (optional)
FilterState → Merchant (optional)
FilterState → SKU (optional)

TableRow → Category (optional)
TableRow → Merchant (optional)
TableRow → SKU (optional)

TableColumn → defines structure of TableRow
SortState → applies to TableColumn
PageSection → organizes page content
```

---

## State Transitions

### FilterState Transitions

```
Initial (empty) 
  → User selects dateWindow 
  → FilterState { dateWindow: '7' }
  
  → User selects categoryLevel4Id 
  → FilterState { dateWindow: '7', categoryLevel4Id: '1001' }
  
  → User clicks confirm 
  → URL updates: ?dateWindow=7&categoryLevel4Id=1001
  
  → User navigates to another page 
  → FilterState preserved in URL
  
  → User refreshes page 
  → FilterState restored from URL
```

### SortState Transitions

```
Initial (none)
  → User clicks column header 
  → SortState { columnKey: 'salesAmount', direction: 'asc' }
  
  → User clicks same column again 
  → SortState { columnKey: 'salesAmount', direction: 'desc' }
  
  → User clicks same column third time 
  → SortState { columnKey: null, direction: 'none' }
  
  → User clicks different column 
  → SortState { columnKey: 'achievementRate', direction: 'asc' }
```

---

## Validation Rules

### General Rules

1. **ID 引用完整性**: 所有 ID 字段必须引用有效实体（在 mock 数据中保证）
2. **日期格式**: 所有日期字段使用 ISO 8601 格式（YYYY-MM-DD）
3. **数值范围**: 百分比字段（如 achievementRate）范围 0-100
4. **必填字段**: 实体的 id 和 name 为必填

### FilterState Rules

1. **日期窗口与日期范围**: dateWindow 和 dateStart/dateEnd 互斥，优先使用 dateWindow
2. **层级关系**: categoryLevel4Id → merchantId → skuId，下级依赖上级（如 merchantId 必须在 categoryLevel4Id 存在时才有意义）

### SortState Rules

1. **单列排序**: 同时只能有一个字段排序
2. **三态循环**: 升序 → 降序 → 默认 → 升序

---

## Mock Data Examples

### Category Mock

```typescript
const mockCategories: Category[] = [
  { id: '1001', name: '红富士' },
  { id: '1002', name: '嘎啦' },
  { id: '1003', name: '国光' },
  { id: '1004', name: '花牛' }
];
```

### Merchant Mock

```typescript
const mockMerchants: Merchant[] = [
  { id: '2001', name: '商家A' },
  { id: '2002', name: '商家B' },
  { id: '2003', name: '商家C' }
];
```

### SKU Mock

```typescript
const mockSKUs: SKU[] = [
  { id: '3001', name: 'SKU001', categoryLevel4Id: '1001', merchantId: '2001' },
  { id: '3002', name: 'SKU002', categoryLevel4Id: '1001', merchantId: '2001' },
  { id: '3003', name: 'SKU003', categoryLevel4Id: '1002', merchantId: '2002' }
];
```

### TableRow Mock

```typescript
const mockTableData: TableRow[] = [
  {
    categoryLevel4Id: '1001',
    categoryName: '红富士',
    merchantId: '2001',
    merchantName: '商家A',
    salesAmount: 123456,
    achievementRate: 92
  },
  {
    categoryLevel4Id: '1002',
    categoryName: '嘎啦',
    merchantId: '2002',
    merchantName: '商家B',
    salesAmount: 98765,
    achievementRate: 87
  }
];
```

---

## Notes

- 所有实体 ID 使用字符串类型，便于后续扩展（如 UUID）
- Mock 数据与真实 API 响应结构保持一致
- 类型定义放在 `client/src/types/index.ts`，便于复用
- 共享类型（前后端）放在 `shared/types/api.ts`（待后端定义）
