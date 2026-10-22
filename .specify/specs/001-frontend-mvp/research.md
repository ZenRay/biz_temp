# Research: 商家复盘 Dashboard 前端 MVP

**Date**: 2026-10-18  
**Feature**: [spec.md](./spec.md)

## Overview

本文档记录了前端 MVP 开发过程中的关键技术决策和最佳实践。

## Technical Context 中的未知项

**无 NEEDS CLARIFICATION** - 所有技术决策已在需求文档和原型中确认。

## 关键技术决策

### 1. 状态管理方案

**Decision**: 三层状态管理
- URL query params → 筛选器状态（可分享、可后退）
- React Query cache → 数据缓存（stale-while-revalidate）
- Zustand → UI 状态（导航栏收起、全屏弹窗）

**Rationale**: 
- 筛选器状态需要可分享和浏览器后退支持，URL 参数是最佳选择
- React Query 提供自动缓存失效和去重请求，适合 BI 看板只读场景
- Zustand 轻量且简单，适合管理 UI 状态

**Alternatives considered**:
- Redux：过于复杂，对于 10 人团队和 MVP 阶段不必要
- Context API：全局状态更新会导致不必要的重渲染

### 2. 路由与 URL 参数设计

**Decision**: 使用 react-router-dom v6 嵌套路由 + query params

**Rationale**:
- 嵌套路由符合页面层级结构（概览 → 品类 → 商家 → 商品）
- Query params 便于筛选器状态同步和 URL 分享
- 支持浏览器前进/后退导航

**Alternatives considered**:
- Path params（如 `/category/1001`）：不够灵活，筛选条件组合多时 URL 过长
- Hash routing：不利于 SEO 和直接访问（但本项目不需要 SEO）

### 3. 表格组件实现

**Decision**: 基于 shadcn/ui Table 组件封装 DataTable，支持分页、排序、全屏

**Rationale**:
- shadcn/ui 已在妙搭脚手架预装，无需额外安装
- 封装统一接口，所有表格复用相同逻辑
- 支持列排序（升序/降序/默认）和全屏放大

**Alternatives considered**:
- AG Grid：功能强大但体积大，对于 MVP 过于复杂
- 自研表格组件：开发成本高，不如基于现有组件封装

### 4. 图表库选择

**Decision**: ECharts + echarts-for-react

**Rationale**:
- 妙搭脚手架已预装，无需额外安装
- 支持 dataZoom（日期拖拽）功能，满足趋势图交互需求
- Canvas 渲染性能好，适合大数据量场景

**Alternatives considered**:
- Recharts：已在脚手架中，但 dataZoom 支持不如 ECharts
- D3.js：灵活但开发成本高，MVP 阶段不必要

### 5. 设计系统落地

**Decision**: 在 Tailwind config 中配置 Fresh Produce BI token

**Rationale**:
- 统一视觉语言，降低维护成本
- 通过 token 化便于后续主题扩展
- 与原型保持一致，减少沟通成本

**Alternatives considered**:
- CSS Variables：不如 Tailwind 工具类直观
- 内联样式：无法复用，维护成本高

### 6. Mock 数据策略

**Decision**: 在 `utils/mock-data.ts` 中定义 mock 数据，通过 API 接口返回

**Rationale**:
- 前端开发不依赖后端 API 就绪
- Mock 数据结构与真实 API 一致，后续只需替换数据源
- 便于独立开发和测试

**Alternatives considered**:
- MSW (Mock Service Worker)：功能强大但配置复杂
- 硬编码在组件中：不利于数据复用和维护

## 最佳实践参考

### 1. React 性能优化

- 使用 `React.memo` 包裹纯展示组件
- 使用 `useMemo` 缓存复杂计算（如表格排序）
- 使用 `useCallback` 缓存事件处理函数
- 避免在 render 中创建新对象/数组

### 2. TypeScript 类型安全

- 所有组件 props 必须定义类型
- API 响应数据定义接口类型
- 避免使用 `any`，必要时使用 `unknown` + 类型守卫

### 3. 组件设计原则

- 单一职责：每个组件只做一件事
- 可组合性：小组件组合成大组件
- 可测试性：组件易于单元测试
- 可访问性：使用语义化 HTML 和 ARIA 属性

### 4. 错误处理

- 网络请求失败时显示友好错误提示
- 提供重试按钮
- 记录错误日志（console.error 或日志服务）

### 5. 加载状态

- 首次加载显示 skeleton
- 数据刷新时显示 loading indicator
- 缓存命中时即时显示，后台静默刷新

## 待确认事项

**无** - 所有技术决策已确认。

## 参考资源

- [React 19 文档](https://react.dev/)
- [Tailwind CSS 文档](https://tailwindcss.com/)
- [shadcn/ui 文档](https://ui.shadcn.com/)
- [ECharts 文档](https://echarts.apache.org/)
- [React Query 文档](https://tanstack.com/query/latest)
- [Zustand 文档](https://github.com/pmndrs/zustand)
