# Tasks: 商家复盘 Dashboard 前端 MVP

**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)  
**Generated**: 2026-10-18  
**Total Phases**: 4

---

## Phase 1: Setup & Foundation

**Goal**: 搭建项目基础架构，配置设计系统，建立核心布局框架  
**Duration**: 2-3 天  
**Dependencies**: 无

### 1.1 项目初始化

- [x] T001 创建项目目录结构（client/src/components, pages, hooks, types, utils）
- [x] T002 配置 Tailwind CSS，在 tailwind.config.ts 中添加 Fresh Produce BI 设计 token（色彩、字体、圆角、阴影）
- [x] T003 定义核心类型接口（client/src/types/index.ts）：Category, Merchant, SKU, FilterState, TableRow, TableColumn, SortState, PageSection
- [x] T004 创建 Mock 数据文件（client/src/utils/mock-data.ts），包含品类、商家、SKU、表格数据示例

### 1.2 路由与状态管理

- [x] T005 配置 react-router-dom 嵌套路由（client/src/App.tsx）：概览、品类分析、商家分析、商品分析、诊断页
- [x] T006 实现 useFilters hook（client/src/hooks/useFilters.ts）：从 URL 读取/同步筛选状态
- [x] T007 实现 useTableSort hook（client/src/hooks/useTableSort.ts）：管理表格排序状态（升序/降序/默认）

### 1.3 核心布局组件

- [x] T008 实现 Sidebar 组件（client/src/components/layout/Sidebar.tsx）：左侧导航栏，支持收起/展开
- [x] T009 实现 FilterBar 组件（client/src/components/layout/FilterBar.tsx）：顶部筛选器栏，支持日期窗口、四级类目、商家、商品筛选
- [x] T010 实现 Breadcrumbs 组件（client/src/components/navigation/Breadcrumbs.tsx）：面包屑导航
- [x] T011 实现 PageSection 组件（client/src/components/navigation/PageSection.tsx）：页面区块容器，注册到 TOC
- [x] T012 实现 TableOfContents 组件（client/src/components/layout/TableOfContents.tsx）：右侧目录导航

---

## Phase 2: Core User Stories (P1)

**Goal**: 实现核心功能——概览页、下钻跳转、筛选器联动  
**Duration**: 3-4 天  
**Dependencies**: Phase 1 完成

### 2.1 User Story 1: 全局概览与快速定位

**Independent Test**: 打开概览页，查看数据明细表格，确认分页可用，确认筛选器可切换数据

- [x] T013 [US1] 实现 DataTable 组件基础版（client/src/components/data/DataTable.tsx）：表格渲染、分页（每页 20 条）
- [x] T014 [US1] 实现概览页（client/src/pages/OverviewPage.tsx）：显示数据明细表格，集成筛选器
- [x] T015 [US1] 实现表格分页交互：上一页/下一页按钮，分页指示器（"第 X 页，每页 20 条"）

### 2.2 User Story 3: 筛选器联动与 URL 同步

**Independent Test**: 选择筛选条件后 URL 更新，刷新页面后筛选条件保留

- [x] T016 [US3] 实现筛选器确认按钮逻辑：点击确认后调用 onFilterChange 更新 URL
- [x] T017 [US3] 实现筛选器下拉框搜索功能：输入关键词过滤选项
- [x] T018 [US3] 实现筛选器"ID-名称"格式显示：如"1001-红富士"
- [x] T019 [US3] 实现页面加载时从 URL 读取筛选参数并回显

### 2.3 User Story 2: 交互式下钻诊断

**Independent Test**: 点击表格中品类名称，跳转到品类分析页且筛选器自动填充

- [x] T020 [US2] 实现 DataTable 可点击列：配置 clickableColumns，点击触发跳转
- [x] T021 [US2] 实现品类分析页（client/src/pages/CategoryAnalysisPage.tsx）：品类表格、商家品类表格、商品表格
- [x] T022 [US2] 实现商家品类分析页（client/src/pages/MerchantAnalysisPage.tsx）：商家品类表格、商品表格
- [x] T023 [US2] 实现商品分析页（client/src/pages/ProductAnalysisPage.tsx）：商品明细表格
- [x] T024 [US2] 实现下钻跳转逻辑：品类→商家→SKU，携带 URL 参数

---

## Phase 3: Enhanced Features (P2)

**Goal**: 实现增强功能——表格排序、全屏放大、布局优化  
**Duration**: 2-3 天  
**Dependencies**: Phase 2 完成

### 3.1 User Story 7: 表格列排序

**Independent Test**: 点击表头排序，验证升序/降序/默认三态切换

- [x] T025 [US7] 实现 DataTable 表头排序 UI：点击表头显示排序箭头（↑/↓）
- [x] T026 [US7] 集成 useTableSort hook 到 DataTable：点击表头触发排序
- [x] T027 [US7] 实现排序状态三态循环：升序→降序→默认→升序

### 3.2 User Story 5: 表格全屏放大与数据查看

**Independent Test**: 点击全屏按钮，弹窗展示完整表格，支持缩放和关闭

- [x] T028 [US5] 实现 FullscreenModal 组件（client/src/components/data/FullscreenModal.tsx）：弹窗容器，支持缩放
- [x] T029 [US5] 实现 DataTable 全屏按钮：右上角显示⛶按钮，点击打开弹窗
- [x] T030 [US5] 实现弹窗缩放控制：放大/缩小按钮，初始状态缩小按钮失效，最大状态放大按钮失效
- [x] T031 [US5] 实现弹窗关闭交互：点击外部/ESC/关闭按钮
- [x] T032 [US5] 实现弹窗内表格独立分页和滚动

### 3.3 User Story 4: 页面内导航与布局框架

**Independent Test**: 点击导航栏收起按钮，验证布局变化；点击 TOC 项，验证平滑滚动

- [x] T033 [US4] 实现导航栏收起/展开动画：宽度从 240px → 0，内容区自适应
- [x] T034 [US4] 实现面包屑点击收起导航栏：点击面包屑区域触发 onToggle
- [x] T035 [US4] 实现 TOC 平滑滚动：点击目录项调用 scrollIntoView({ behavior: 'smooth' })
- [x] T036 [US4] 实现诊断页 placeholder（client/src/pages/DiagnosisPage.tsx）：显示"功能开发中"提示

---

## Phase 4: Polish & Cross-Cutting Concerns

**Goal**: 完善边缘情况、错误处理、性能优化  
**Duration**: 1-2 天  
**Dependencies**: Phase 3 完成

### 4.1 边缘情况处理

- [x] T037 实现表格空状态：数据为空时显示"暂无数据"，隐藏分页器
- [x] T038 实现筛选器空选项：下拉框无数据时显示"暂无数据"
- [x] T039 实现无效 URL 参数处理：ID 不存在时筛选器显示"未知"，表格显示空状态
- [x] T040 实现网络请求失败处理：显示错误提示和重试按钮

### 4.2 性能优化

- [x] T041 优化表格渲染：使用 React.memo 包裹 TableRow，避免不必要的重渲染
- [x] T042 优化筛选器切换：使用 useMemo 缓存过滤后的数据
- [x] T043 实现数据缓存：使用 React Query 的 stale-while-revalidate 策略

### 4.3 最终验证

- [x] T044 执行 quickstart.md 中的 8 个验证场景，确保所有功能可用
- [x] T045 运行类型检查（npm run type-check）和代码检查（npm run lint）
- [x] T046 构建生产版本（npm run build），验证无错误

---

## Dependency Graph

```
Phase 1 (Setup & Foundation)
    ↓
Phase 2 (Core User Stories - P1)
    ├─ US1: 概览页
    ├─ US3: 筛选器联动
    └─ US2: 下钻跳转
    ↓
Phase 3 (Enhanced Features - P2)
    ├─ US7: 表格排序
    ├─ US5: 全屏放大
    └─ US4: 布局优化
    ↓
Phase 4 (Polish)
    └─ 边缘情况 + 性能优化 + 验证
```

---

## Parallel Execution Opportunities

### Phase 1 可并行任务

- T001-T004 可并行（项目初始化、类型定义、Mock 数据）
- T005-T007 可并行（路由、hooks）
- T008-T012 可并行（布局组件）

### Phase 2 可并行任务

- US1 (T013-T015) 和 US3 (T016-T019) 可并行开发
- US2 (T020-T024) 依赖 US1 完成（需要 DataTable 组件）

### Phase 3 可并行任务

- US7 (T025-T027) 和 US5 (T028-T032) 可并行开发
- US4 (T033-T036) 可与 US7/US5 并行

---

## Implementation Strategy

### MVP Scope (Phase 1 + Phase 2)

完成 Phase 1 和 Phase 2 后，系统具备：
- ✅ 概览页数据表格展示
- ✅ 筛选器联动与 URL 同步
- ✅ 品类→商家→SKU 下钻跳转
- ✅ 基础布局框架（导航栏、筛选器、TOC）

**可独立交付给用户试用**，验证核心诊断流程。

### Incremental Delivery

- **Week 1**: Phase 1（基础架构）+ Phase 2 部分（US1 概览页）
- **Week 2**: Phase 2 完成（US2, US3）→ MVP 交付
- **Week 3**: Phase 3（增强功能）
- **Week 4**: Phase 4（优化）+ 用户反馈收集

---

## Success Criteria Validation

完成所有任务后，验证以下指标：

- ✅ SC-001: 首屏加载 < 10s
- ✅ SC-002: 下钻跳转不超过 3 次点击
- ✅ SC-003: 筛选器切换后数据刷新 < 3s
- ✅ SC-004: 刷新页面后筛选条件保留
- ✅ SC-005: 日复盘时间从 3h 缩短到 1h（试运行后评估）
- ✅ SC-007: 分页、全屏、TOC 等功能 100% 可用

---

## Notes

- 所有任务基于 mock 数据开发，后端 API 就绪后替换数据源
- 货盘呈现模块明确排除在 MVP 范围外
- 趋势图（US6）在概览页不实现，仅在分析页使用
- 表格排序（US7）为 P2 优先级，但实现简单，可在 Phase 3 快速完成
