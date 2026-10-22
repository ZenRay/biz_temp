# Component Contracts: 商家复盘 Dashboard 前端 MVP

**Date**: 2026-10-18  
**Feature**: [spec.md](../spec.md)

## Overview

本文档定义了前端 MVP 中核心组件的接口契约，包括 props、状态和交互行为。

---

## Layout Components

### 1. Sidebar

**Description**: 左侧导航栏，支持收起/展开。

**Props**:
```typescript
interface SidebarProps {
  collapsed: boolean;
  onToggle: () => void;
  currentPath: string;
}
```

**Behavior**:
- `collapsed = true` 时宽度为 0，完全隐藏
- `collapsed = false` 时宽度为 240px
- 点击菜单项触发路由跳转
- 高亮当前路径对应的菜单项

---

### 2. FilterBar

**Description**: 顶部筛选器栏，常驻吸顶显示。

**Props**:
```typescript
interface FilterBarProps {
  filters: FilterState;
  onFilterChange: (filters: FilterState) => void;
  visibleFields: Array<'dateWindow' | 'dateRange' | 'category' | 'merchant' | 'sku'>;
}
```

**Behavior**:
- 根据 `visibleFields` 显示对应的筛选器
- 筛选器值变化时调用 `onFilterChange`
- 点击"确认"按钮后同步更新 URL 参数
- 页面加载时从 URL 读取初始值

---

### 3. TableOfContents

**Description**: 右侧目录导航，基于 PageSection 自动生成。

**Props**:
```typescript
interface TableOfContentsProps {
  sections: PageSection[];
  activeSection?: string;
}
```

**Behavior**:
- 无 sections 时不渲染
- 点击目录项平滑滚动到对应 section
- 滚动时高亮当前可见的 section（可选，MVP 不强制）

---

## Data Display Components

### 4. DataTable

**Description**: 可交互数据表格，支持分页、排序、全屏。

**Props**:
```typescript
interface DataTableProps {
  columns: TableColumn[];
  data: TableRow[];
  pageSize?: number;  // 默认 20
  clickableColumns?: Array<{
    key: string;
    onClick: (row: TableRow) => void;
  }>;
  enableFullscreen?: boolean;  // 默认 true
}
```

**Behavior**:
- 默认每页显示 20 条数据
- 点击表头触发排序（升序 → 降序 → 默认）
- 可点击列显示为链接样式，点击触发 `onClick`
- 右上角显示全屏按钮（如果 `enableFullscreen = true`）
- 全屏模式下保留分页和排序功能

**State**:
```typescript
interface DataTableState {
  currentPage: number;
  sortState: SortState;
  isFullscreen: boolean;
}
```

---

### 5. EChart

**Description**: ECharts 图表封装组件。

**Props**:
```typescript
interface EChartProps {
  option: EChartsOption;
  height?: number | string;  // 默认 400
  enableFullscreen?: boolean;  // 默认 true
  enableDataZoom?: boolean;  // 默认 false
}
```

**Behavior**:
- 渲染 ECharts 图表
- 全屏模式下自动 resize
- `enableDataZoom = true` 时显示日期拖拽条（仅在全屏模式）

---

### 6. KPICard

**Description**: KPI 指标卡片。

**Props**:
```typescript
interface KPICardProps {
  title: string;
  value: string | number;
  trend?: 'up' | 'down' | 'flat';
  trendValue?: string;  // 如 "+5.2%"
  target?: string;  // 如 "目标: 100%"
}
```

**Behavior**:
- 显示标题、数值、趋势箭头、目标值
- 趋势向上显示绿色，向下显示红色

---

## Navigation Components

### 7. Breadcrumbs

**Description**: 面包屑导航。

**Props**:
```typescript
interface BreadcrumbsProps {
  items: Array<{
    label: string;
    path?: string;
  }>;
}
```

**Behavior**:
- 显示当前页面路径
- 点击可跳转（如果有 `path`）
- 最后一项不可点击（当前位置）

---

### 8. PageSection

**Description**: 页面内容区块容器。

**Props**:
```typescript
interface PageSectionProps {
  id: string;
  title: string;
  children: React.ReactNode;
}
```

**Behavior**:
- 渲染 section 标题和内容
- 自动注册到 PageSectionContext，供 TableOfContents 使用

---

## Fullscreen Components

### 9. FullscreenModal

**Description**: 全屏弹窗容器。

**Props**:
```typescript
interface FullscreenModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  scale?: number;  // 1.0 = 100%
  onScaleChange?: (scale: number) => void;
}
```

**Behavior**:
- 居中显示，背景半透明遮罩
- 点击遮罩或按 ESC 关闭
- 显示放大/缩小按钮
- `scale = 1.0` 时放大按钮失效
- `scale = 初始值` 时缩小按钮失效

---

## Hooks

### 10. useFilters

**Description**: 筛选器状态管理 hook。

**Signature**:
```typescript
function useFilters(): {
  filters: FilterState;
  setFilters: (filters: FilterState) => void;
  updateURL: (filters: FilterState) => void;
}
```

**Behavior**:
- 从 URL 读取初始筛选状态
- 筛选器变化时同步更新 URL
- 提供响应式的 filters 对象

---

### 11. useTableSort

**Description**: 表格排序逻辑 hook。

**Signature**:
```typescript
function useTableSort<T>(
  data: T[],
  options?: { initialSort?: SortState }
): {
  sortState: SortState;
  sortedData: T[];
  handleSort: (columnKey: string) => void;
}
```

**Behavior**:
- 管理排序状态（升序/降序/默认）
- 返回排序后的数据
- 点击表头时调用 `handleSort`

---

## Type Exports

所有类型定义从 `client/src/types/index.ts` 导出：

```typescript
export type {
  Category,
  Merchant,
  SKU,
  FilterState,
  TableRow,
  TableColumn,
  SortState,
  PageSection,
} from './types';
```

---

## Notes

- 所有组件使用 TypeScript 严格类型检查
- Props 接口使用 `interface` 而非 `type`（便于扩展）
- 可选 props 使用 `?` 标记，提供合理默认值
- 事件处理函数命名统一使用 `on` 前缀
