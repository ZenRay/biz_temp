# Implementation Plan: 商家复盘 Dashboard 前端 MVP

**Branch**: `001-frontend-mvp` | **Date**: 2026-10-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-frontend-mvp/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

基于 React 19 + TypeScript + Tailwind CSS + shadcn/ui + ECharts 技术栈，在飞书妙搭平台上构建商家复盘 Dashboard 前端 MVP。核心交付：三栏布局框架（导航栏+筛选器+TOC）、可交互数据表格（分页/排序/全屏）、筛选器联动与 URL 同步、交互式下钻跳转。使用 mock 数据先行开发，后端 API 就绪后对接。

## Technical Context

**Language/Version**: TypeScript 5.x + React 19

**Primary Dependencies**: 
- UI: shadcn/ui + Tailwind CSS（妙搭脚手架预装）
- Charts: ECharts ^6.1.0 + echarts-for-react ~3.0.2（妙搭脚手架预装）
- State: React Query（数据缓存）+ Zustand（UI 状态）
- Router: react-router-dom（嵌套路由）

**Storage**: N/A（前端项目，数据来自后端 API）

**Testing**: Vitest + React Testing Library（妙搭脚手架预装）

**Target Platform**: Web（桌面浏览器，最小分辨率 1280×720）

**Project Type**: Web application（单页应用 SPA）

**Performance Goals**: 
- 首屏加载 < 10s
- 筛选器切换后数据刷新 < 3s（缓存命中时即时）
- 表格渲染 1000 条数据无卡顿
- 商品页完全加载 < 20s（商品页数据量最大，包含多个表格和图表）

**Constraints**: 
- 必须使用飞书妙搭平台
- 必须使用 Fresh Produce BI 设计系统 token
- 必须支持 URL 参数同步筛选状态

**Scale/Scope**: 
- 用户规模：10 人（运营团队）
- 页面数量：5 个（概览、品类分析、商家分析、商品分析、诊断占位）
- 组件数量：约 20 个核心组件

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Data Accuracy Gate | ✅ PASS | 前端只负责展示，计算逻辑在后端 |
| II. Diagnostic Flow Alignment | ✅ PASS | 页面结构对齐诊断流程，支持下钻路径 |
| III. Design System Fidelity | ✅ PASS | 使用 Fresh Produce BI token |
| IV. Platform-First Development | ✅ PASS | 使用妙搭预装依赖，不额外安装 |
| V. Dev-Verify-Publish Workflow | ✅ PASS | 遵循 dev → online 发布流程 |
| VI. Phased Iteration | ✅ PASS | MVP 范围严格受控，货盘模块延后 |

**Gate Result**: ✅ PASS - 无违反项

## Project Structure

### Documentation (this feature)

```text
.specify/specs/001-frontend-mvp/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── components.md    # 组件接口契约
│   └── mock-data.md     # Mock 数据结构
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
merchant-review/
├── client/
│   └── src/
│       ├── components/
│       │   ├── ui/              # shadcn/ui 基础组件
│       │   ├── layout/          # 布局组件（Sidebar, FilterBar, TOC）
│       │   ├── data/            # 数据展示组件（DataTable, EChart）
│       │   └── navigation/      # 导航组件（Breadcrumbs, PageSection）
│       ├── pages/
│       │   ├── OverviewPage.tsx
│       │   ├── CategoryAnalysisPage.tsx
│       │   ├── MerchantAnalysisPage.tsx
│       │   ├── ProductAnalysisPage.tsx
│       │   └── DiagnosisPage.tsx
│       ├── hooks/
│       │   ├── useFilters.ts    # 筛选器状态管理
│       │   └── useTableSort.ts  # 表格排序逻辑
│       ├── types/
│       │   └── index.ts         # 类型定义
│       └── utils/
│           └── mock-data.ts     # Mock 数据
├── shared/
│   └── types/
│       └── api.ts               # 前后端共享类型（待后端定义）
└── Reference/
    ├── full-prototype.html      # 交互原型
    └── 前端需求v0.1.md          # 需求文档
```

**Structure Decision**: 采用单项目结构（Option 1），前端代码在 `merchant-review/client/`。后端代码在 `merchant-review/server/`（不在本计划范围）。共享类型在 `merchant-review/shared/`。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

无违反项，此节留空。
