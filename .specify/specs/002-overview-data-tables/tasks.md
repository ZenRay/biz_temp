# Tasks: 概览页面数据表格

**Feature**: 002-overview-data-tables
**Created**: 2026-10-19
**Plan**: [plan.md](./plan.md)

---

## Phase 1: Setup & Database (1-2 days)

### Goals

- 创建 ADS 同步表和目标表的镜像表
- 创建必要的索引支撑查询性能
- 验证表结构和索引

### Independent Test Criteria

- 数据库表创建成功，无语法错误
- 索引创建成功，查询计划使用索引
- 表结构与 data-model.md 定义一致

### Tasks

- [x] T001 创建 ADS 同步表 ads_category_daily 在 server/database/ddl/002_overview_data_tables.sql
- [x] T002 创建 ADS 同步表 ads_merchant_category_daily 在 server/database/ddl/002_overview_data_tables.sql
- [x] T003 创建 ADS 同步表 ads_sku_daily 在 server/database/ddl/002_overview_data_tables.sql
- [x] T004 创建目标表 biz_category_target 在 server/database/ddl/002_overview_data_tables.sql
- [x] T005 创建目标表 biz_merchant_category_target 在 server/database/ddl/002_overview_data_tables.sql
- [x] T006 创建目标表 biz_sku_target 在 server/database/ddl/002_overview_data_tables.sql
- [x] T007 创建 ads_category_daily 索引 (dt), (mall_id, dt), (category_level4_id, dt) 在 server/database/ddl/002_overview_data_tables.sql
- [x] T008 创建 ads_merchant_category_daily 索引 (dt), (mall_id, dt), (category_level4_id, dt), (merchant_id, dt) 在 server/database/ddl/002_overview_data_tables.sql
- [x] T009 创建 ads_sku_daily 索引 (dt), (mall_id, dt), (category_level4_id, dt), (merchant_id, dt), (sku_id, dt) 在 server/database/ddl/002_overview_data_tables.sql
- [x] T010 创建 biz_category_target 索引 (dt), (mall_id, dt), (category_level4_id, dt) 在 server/database/ddl/002_overview_data_tables.sql
- [x] T011 创建 biz_merchant_category_target 索引 (dt), (mall_id, dt), (category_level4_id, dt), (merchant_name, dt) 在 server/database/ddl/002_overview_data_tables.sql
- [x] T012 创建 biz_sku_target 索引 (dt), (sku_id, dt) 在 server/database/ddl/002_overview_data_tables.sql
- [x] T013 生成数据库迁移脚本（DDL 文件，幂等：IF NOT EXISTS）
- [x] T014 执行数据库迁移（lark-cli apps +db-execute，dev 环境）
- [x] T015 验证表结构和索引（6 张表 21 个索引，EXPLAIN 验证索引使用，upsert 幂等验证通过）

---

## Phase 2: Backend API Development (2-3 days)

### Goals

- 实现概览页面数据 API（GET /api/overview）
- 实现日期窗口聚合逻辑（按指标类型区分）
- 实现计算逻辑（曝光转化率、达成率、客均件数等）
- 实现分页和排序
- 编写单元测试

### Independent Test Criteria

- API 端点可访问，返回正确的 JSON 结构
- 日期窗口聚合逻辑正确（存量指标取最新值，流量指标求和，比率指标重新计算）
- 计算逻辑正确（曝光转化率、达成率、客均件数、平台盈余金额、平台毛利率、日活覆盖率、货值占比）
- 分页和排序功能正常
- 单元测试覆盖核心计算逻辑

### Tasks

- [x] T016 创建 OverviewController 在 server/modules/overview/overview.controller.ts
- [x] T017 创建 OverviewService 在 server/modules/overview/overview.service.ts
- [x] T018 实现 GET /api/overview 端点 在 server/modules/overview/overview.controller.ts
- [x] T019 实现查询参数验证（dateStart, dateEnd, dateWindow, categoryLevel4Id, merchantId, skuId, page, pageSize, sortBy, sortOrder）在 server/modules/overview/dto/overview-query.dto.ts
- [x] T020 实现 ADS 表查询逻辑（ads_category_daily, ads_merchant_category_daily, ads_sku_daily）在 server/modules/overview/overview.service.ts
- [x] T021 实现目标表查询逻辑（biz_category_target, biz_merchant_category_target, biz_sku_target）在 server/modules/overview/overview.service.ts
- [x] T022 实现日期窗口聚合逻辑（存量指标取最新值，流量指标求和）在 server/modules/overview/utils/aggregation.ts
- [x] T023 实现计算逻辑工具函数 在 server/modules/overview/utils/calculations.ts
  - [x] T023a 实现曝光转化率计算（下单店铺数 / 曝光店铺数）
  - [x] T023b 实现货值目标达成率计算（货值 / 货值目标）
  - [x] T023c 实现客均件数计算（下单件数 / 下单店铺数）
  - [x] T023d 实现平台盈余金额计算（平台抽佣金额 - 平台承担赔付金额 - 平台补贴金额）
  - [x] T023e 实现平台毛利率计算（平台盈余金额 / 货值）
  - [x] T023f 实现日活覆盖率计算（下单店铺数 / 一级类目下单店铺数）— 工具函数已实现；品类/商家表暂返回 null（依赖缺失的 ads_mall_cat1_daily 表，SKU 表直接取 ADS 预计算字段 cat4_in_cat1_store_ratio）
  - [x] T023g 实现货值占比计算（当前粒度货值 / 上级粒度货值）
- [x] T024 实现四级类目表数据组装逻辑 在 server/modules/overview/overview.service.ts
- [x] T025 实现商家四级类目表数据组装逻辑 在 server/modules/overview/overview.service.ts
- [x] T026 实现商品表数据组装逻辑 在 server/modules/overview/overview.service.ts
- [x] T027 实现分页和排序逻辑 在 server/modules/overview/overview.service.ts
- [x] T028 实现错误处理（400 参数错误, 404 数据不存在, 500 服务器内部错误）— 400 由 class-validator + BadRequestException 实现；500 由全局 GlobalExceptionFilter 兜底；空数据返回空表格结构而非 404（符合前端独立加载/空态设计）
- [x] T029 编写单元测试：日期窗口聚合逻辑 在 server/modules/overview/utils/__tests__/aggregation.spec.ts
- [x] T030 编写单元测试：计算逻辑工具函数 在 server/modules/overview/utils/__tests__/calculations.spec.ts
- [x] T031 编写单元测试：OverviewService 核心逻辑 在 server/modules/overview/__tests__/overview.service.spec.ts
- [x] T032 运行所有单元测试并确保通过（38/38 通过）

### Phase 2 完成说明（2026-10-19）

- **实际路径**：项目后端无 `src` 层级，实际为 `server/modules/overview/`（与既有 hello/view 模块一致）
- **测试框架**：项目原本无任何测试框架，已安装 `vitest`（devDependency），新增 `npm test` / `npm run test:watch` 脚本，`vitest.config.ts` 配置 `@server`/`@shared` 别名
- **平台包 mock**：`@lark-apaas/fullstack-nestjs-core` 在 vitest 下有 ESM interop 问题，service 测试用 `vi.mock` 桩替代（仅需 DI token）
- **接口验证**：`GET /api/overview` 三种场景通过（正常请求 / 分页排序参数 / 非法 dateWindow 返回 400）；当前 ADS 表无同步数据，返回空表格结构属预期
- **模块注册**：OverviewModule 已注册到 app.module.ts business-modules 区（ViewModule 之前）
- **共享类型**：`shared/api.interface.ts` 已定义 OverviewQueryParams / CategoryTableRow / MerchantCategoryTableRow / ProductTableRow / OverviewResponse
- **遗留 TODO**（Phase 4 或后续迭代）：达成等级（achieveLevel）业务规则待确认；~~日活覆盖率分母依赖 ads_mall_cat1_daily 表~~ ✅ 已解决（2026-10-19 GAP-A 批次：ads_mall_daily / ads_mall_cat1_daily / dim_mall 已建表并接线，商城登录/曝光店铺数、日活覆盖率、品类曝光门店数均从真实表取值）；~~商家/商品表的品类曝光门店数（categoryExposedStoreNum）待扩展~~ ✅ 已解决（同上）

---

## Phase 3: Frontend Implementation (2-3 days)

### Goals

- 修改概览页面布局（垂直堆叠三个 PageSection）
- 实现三个表格组件（四级类目、商家四级类目、商品）
- 实现固定列策略（品类表固定第一列，商家表固定第二列，商品表固定第三列）
- 实现 TOC 跳转
- 实现全屏放大功能
- 实现独立加载状态和错误处理
- 对接后端 API

### Independent Test Criteria

- 概览页面显示三个 PageSection，垂直堆叠
- 右侧 TOC 显示三个 section 标题，点击后平滑滚动到对应表格
- 四级类目表格显示所有定义的列（包括 Top 相关列，即使数据为空）
- 商家四级类目表格显示所有定义的列（包括 Top 相关列）
- 商品表格显示所有定义的列（包括 Top 相关列）
- 表格支持分页（默认 20 条/页）
- 表格支持列排序（点击表头切换升序/降序/默认）
- 表格支持全屏放大（点击全屏按钮弹出居中弹窗）
- 四级类目表固定第一列（四级类目名称）
- 商家四级类目表固定第二列（商家名称），第一列可隐藏
- 商品表固定第三列（商品名称），前两列可隐藏
- 每个表格独立显示加载状态
- 某个表格加载失败时，仅该表格显示错误提示和重试按钮
- API 对接成功，数据正确展示

### User Story 1: 四级类目数据概览 (P1)

- [x] T033 [US1] 创建 CategoryTable 组件 在 client/src/components/overview/CategoryTable.tsx
- [x] T034 [US1] 定义四级类目表列配置（包含所有 FR-002 定义的字段）在 client/src/components/overview/columns.ts（CATEGORY_COLUMNS，27 列）
- [x] T035 [US1] 实现四级类目名称 ID-名称格式显示（FR-006）在 client/src/components/overview/mappers.ts（formatIdName）
- [x] T036 [US1] 实现 Top 相关字段占位符显示（FR-005）— Top 列已定义表头，行数据未含对应 key 时渲染 '-'
- [x] T037 [US1] 实现四级类目表固定第一列（FR-027a）— DataTable fixedColumnIndex=0（sticky left）
- [x] T038 [US1] 实现四级类目表分页功能（默认 20 条/页）
- [x] T039 [US1] 实现四级类目表列排序功能（useTableSort 三态循环）
- [x] T040 [US1] 实现四级类目表全屏放大功能（FullscreenModal，保留分页与独立滚动）

### User Story 2: 商家四级类目数据概览 (P1)

- [x] T041 [US2] 创建 MerchantCategoryTable 组件 在 client/src/components/overview/MerchantCategoryTable.tsx
- [x] T042 [US2] 定义商家四级类目表列配置（包含所有 FR-003 定义的字段）在 client/src/components/overview/columns.ts（MERCHANT_CATEGORY_COLUMNS，37 列）
- [x] T043 [US2] 实现四级类目名称和商家名称 ID-名称格式显示（FR-006, FR-007）在 client/src/components/overview/mappers.ts
- [x] T044 [US2] 实现 Top 相关字段占位符显示（FR-005）
- [x] T045 [US2] 实现商家四级类目表固定第二列（商家名称），第一列可隐藏（FR-027b）— fixedColumnIndex=1，第一列随水平滚动自然移出
- [x] T046 [US2] 实现商家四级类目表默认排序为四级类目（FR-027b）— compareLabels（四级类目 → 商家，zh-CN locale）
- [x] T047 [US2] 实现商家四级类目表分页功能（默认 20 条/页）
- [x] T048 [US2] 实现商家四级类目表列排序功能
- [x] T049 [US2] 实现商家四级类目表全屏放大功能

### User Story 3: 商品数据概览 (P1)

- [x] T050 [US3] 创建 ProductTable 组件 在 client/src/components/overview/ProductTable.tsx
- [x] T051 [US3] 定义商品表列配置（包含所有 FR-004 定义的字段）在 client/src/components/overview/columns.ts（PRODUCT_COLUMNS，42 列）
- [x] T052 [US3] 实现四级类目名称、商家名称、商品名称 ID-名称格式显示（FR-006, FR-007, FR-008）在 client/src/components/overview/mappers.ts
- [x] T053 [US3] 实现 Top 相关字段占位符显示（FR-005）
- [x] T054 [US3] 实现 Top 相关字段多行格式显示（FR-009 ~ FR-014）— DataTable td 已支持 whitespace-pre-line 多行渲染，列已定义；Top 数据待 ads_top_stat_daily 就绪后由 mapper 填充 '\n' 分隔文本
- [x] T055 [US3] 实现商品表固定第三列（商品名称），前两列可隐藏（FR-027c）— fixedColumnIndex=2
- [x] T056 [US3] 实现商品表默认排序为四级类目、商家（FR-027c）— compareLabels（四级类目 → 商家 → 商品）
- [x] T057 [US3] 实现商品表分页功能（默认 20 条/页）
- [x] T058 [US3] 实现商品表列排序功能
- [x] T059 [US3] 实现商品表全屏放大功能

### User Story 5: 表格交互与数据展示 (P2)

- [x] T060 [US5] 实现表格表头吸顶（sticky）功能 在 client/src/components/data/DataTable.tsx（三表共用）
- [x] T061 [US5] 实现表格独立加载状态（loading spinner）— DataTable loading prop
- [x] T062 [US5] 实现表格独立错误状态和重试按钮 — DataTable error/onRetry props（FR-030e/f）
- [x] T063 [US5] 实现表格空数据状态显示（"暂无数据"占位）

### Overview Page Layout

- [x] T064 修改概览页面布局为垂直堆叠三个 PageSection 在 client/src/pages/OverviewPage.tsx（项目实际页面路径，无 pages/overview/ 目录）
- [x] T065 添加 PageSection 标题和说明（FR-030c）— SectionDescription 组件
- [x] T066 实现右侧 TOC 自动生成（FR-030b）— 复用 PageSection 注册中心 + TableOfContents 既有设施，三个 section 自动出现
- [x] T067 实现 TOC 点击平滑滚动到对应表格（FR-030b）— 既有 scrollIntoView({ behavior: 'smooth' })
- [x] T068 对接后端 API（GET /api/overview）在 client/src/api/overview.ts + OverviewPage useQuery（@tanstack/react-query）
- [x] T069 实现 API 数据到表格组件的映射 在 client/src/components/overview/mappers.ts
- [x] T070 实现表格数据刷新逻辑 — queryKey 含筛选参数，筛选变化自动重新请求；重试按钮触发 refetch

### Phase 3 完成说明（2026-10-19）

- **数据获取策略**：单一接口一次拉取（pageSize=1000，后端 DTO @Max 已从 100 放宽到 1000），分页/排序在客户端完成 — 符合数据量级假设（单表 ≤1000 行），避免三表共享 page 参数的耦合
- **日期缺省逻辑**：筛选器未选日期时，以"昨天"为截止按日期窗口（默认近 7 天）回推起始日期
- **DataTable 扩展**（向后兼容，001 页面不受影响）：新增 loading / error / onRetry / fixedColumnIndex props 和 TableColumn.format 列格式化；td 支持 whitespace-pre-line 多行；重构消除了表格 JSX 重复
- **app.tsx**：新增全局 QueryClientProvider（refetchOnWindowFocus 关闭、retry 1、staleTime 60s）
- **api/index.ts**：改为命名空间导出 `export * as overviewApi from './overview'`
- **列配置**：三表全部列（含 Top 占位列）在 columns.ts 集中定义；行数据存原始数值保证排序正确，显示格式由列 format 决定
- **自检结果**：type:check（server+client）✓、eslint ✓、stylelint ✓、vitest 38/38 ✓、生产构建 build:client ✓、vite dev 全部新模块转换 200 ✓
- **端到端冒烟验证**：向 dev 库插入测试数据（2 天品类 + 商家 + SKU + 三张目标表）→ API 返回三表数据，全部计算值人工核对正确（曝光转化率 0.375、达成率 0.5、客均件数 7、平台盈余 135、毛利率 0.075、货值占比 0.2222、SKU 覆盖率 0.15 等）→ categoryLevel4Id 筛选生效 → 测试数据已清理
- **遗留**：Top 列多行文本内容待 ads_top_stat_daily 数据源；商城登录/曝光店铺数待 ads_mall_daily 表（列已占位显示 '-'）

---

## Phase 4: Integration & Testing (1-2 days)

### Goals

- 实现筛选器联动与数据刷新（User Story 4）
- 端到端测试（筛选器联动、分页、排序、全屏放大、TOC 跳转）
- 性能测试（加载时间 < 10s）
- 边界场景测试（空数据、无效 ID、网络错误）
- 修复 bug

### Independent Test Criteria

- 筛选器选择后，三个表格同步刷新
- 筛选器状态通过 URL 参数同步，刷新页面后筛选条件保留
- 端到端测试场景全部通过
- 首屏加载时间 < 10s
- 筛选器切换后刷新时间 < 3s
- 边界场景处理正确（空数据、无效 ID、网络错误）

### User Story 4: 筛选器联动与数据刷新 (P2)

- [x] T071 [US4] 实现筛选器日期窗口选择（近 7 天 / 近 15 天 / 近 30 天）— 复用 001 FilterBar 既有 Select（实际路径 client/src/components/layout/FilterBar.tsx），OverviewPage 按窗口回推日期接入 API
- [x] T072 [US4] 实现筛选器日期范围选择 — 复用 001 DateRangePicker，dateStart/dateEnd 接入 API
- [x] T073 [US4] 实现筛选器四级类目下拉选择 — 选项改为 GET /api/overview/filter-options 真实数据（ads_sku_daily 最大日期 DISTINCT，方案 B），替换 mock
- [x] T074 [US4] 实现筛选器商家下拉选择 — 按已确认四级类目联动过滤
- [x] T075 [US4] 实现筛选器商品下拉选择 — 按已确认类目 + 商家联动过滤
- [x] T076 [US4] 实现筛选器状态通过 URL query params 管理（FR-026）— 复用 001 useFilters（URL 单一数据源）
- [x] T077 [US4] 实现筛选器选择后三个表格同步刷新（FR-025）— 共享 useQuery，queryKey 含全部筛选参数，单一请求供给三表
- [x] T078 [US4] 实现筛选器回显逻辑（刷新页面或分享链接时）— useFilters 从 URL 解析 + FilterBar draft 回显（001 既有）
- [x] T079 [US4] 实现表格内日期窗口选择器（FR-035b）— 曾实现 WindowSelect + toolbarLeft；**2026-10-19 用户决定移除**：概览三表不放窗口筛选器，改为单日数据显示（WindowSelect.tsx 已删除）
- [x] T080 [US4] 实现表格内日期窗口切换时数据重新聚合（FR-035b）— 随 T079 移除；FR-035b 暂缓，表格只显示对应日期一天数据（筛选结束日期 → 起始日期 → 数据最新日期 dataDate → 昨天兜底）

### End-to-End Testing

- [x] T081 端到端测试：四级类目表格加载和交互 参考 quickstart.md Scenario 1 — API 层验证（冒烟数据 → 27 列数据正确返回）；UI 交互组件级验证（编译 + 类型 + lint）
- [x] T082 端到端测试：筛选器联动 参考 quickstart.md Scenario 2 — categoryLevel4Id/merchantId/skuId 筛选实测生效；三表同源共享请求保证同步
- [x] T083 端到端测试：全屏放大 参考 quickstart.md Scenario 3 — FullscreenModal（001 已人工验收）+ DataTable 重构后保留分页/独立滚动，编译验证
- [x] T084 端到端测试：TOC 跳转 参考 quickstart.md Scenario 4 — PageSection 注册中心 + scrollIntoView smooth（001 既有设施），三个 section 自动注册
- [x] T085 端到端测试：商家四级类目表格加载和交互 — API 层验证（货值占比分母跨表查询正确）
- [x] T086 端到端测试：商品表格加载和交互 — API 层验证（SKU 指标 + 覆盖率字段正确）
- [x] T087 端到端测试：分页和排序功能 — API 分页/排序参数实测（page=2&pageSize=10、sortBy、非法值 400）+ 客户端 useTableSort 三态循环
- [x] T088 端到端测试：筛选器回显和 URL 参数同步 — useFilters URL 单一数据源（001 已验证），概览页无额外状态

### Performance Testing

- [x] T089 性能测试：首屏加载时间 < 10s（SC-001）— 实测 overview API 首次 4.1s、后续 2.0-2.4s（远程 dev 库网络延迟为主），达标
- [x] T090 性能测试：筛选器切换后刷新时间 < 3s（SC-002）— 实测 2.0-2.4s，达标（接近上限；优化候选：表内目标/分母查询并行化、生产库就近部署）
- [x] T091 性能测试：优化 SQL 查询性能 — 21 个索引 Phase 1 已建并 EXPLAIN 验证；所有查询走 dt + 维度过滤条件，无全表扫描
- [x] T092 性能测试：优化前端渲染性能 — 评估结论：客户端分页每页 20 行 + useMemo 缓存映射，单表 ≤1000 行量级无需虚拟滚动（避免过度设计）

### Edge Case Testing

- [x] T093 边界场景测试：筛选器选项为空时显示"暂无数据" — FilterCombobox CommandEmpty 既有 + filter-options 空库实测返回空数组（dataDate: null）
- [x] T094 边界场景测试：表格数据为空时显示"暂无数据"占位提示 — DataTable 空态分支，分页器隐藏
- [x] T095 边界场景测试：URL 参数包含无效 ID 时页面正常加载 — 实测无效 categoryLevel4Id/merchantId/skuId 返回空表格结构（HTTP 200）；FilterCombobox 显示 "ID-未知"
- [x] T096 边界场景测试：网络请求失败时显示错误提示和重试按钮 — DataTable error/onRetry + react-query retry:1 + refetch 重试链路已实现
- [x] T097 边界场景测试：快速连续切换筛选器时只显示最新一次请求结果 — react-query 以参数为 queryKey，过期请求结果不渲染（机制保证）
- [x] T098 边界场景测试：Top 相关字段暂无数据时表头正常显示 — columns.ts 恒定渲染全部表头，行数据缺失 key 显示 '-'（Phase 3 冒烟已验证）

### Bug Fixes

- [x] T099 修复端到端测试发现的 bug — 未发现阻塞性 bug（本轮修复：残留生产进程占用端口导致 API 404，已清理重启）
- [x] T100 修复性能测试发现的 bug — 性能达标，无需修复；记录优化候选（表内查询并行化）
- [x] T101 修复边界场景测试发现的 bug — 全部边界场景通过，无需修复

### Phase 4 完成说明（2026-10-19）

- **filter-options 后端接口**：GET /api/overview/filter-options（商家/商品选项按已确认类目/商家联动过滤，选项来自 ads_sku_daily 最大日期 DISTINCT）；FilterBar 已从 mock 切换到真实数据（全站分析页共享受益）
- **表格级日期窗口（FR-035b）**：WindowSelect（跟随筛选器/近7/15/30天）+ DataTable toolbarLeft 插槽（加载/错误/空态下仍可操作）；窗口覆盖时该表独立请求（dateEnd 不变、dateStart 回推），与全局一致时复用共享请求，三表窗口互相独立
- **冒烟验证**（插入 → 验证 → 清理，dev 库已还原为空）：filter-options 三场景（全量/联动/无效 ID）✓；overview 六参数筛选 ✓；分页排序 ✓；非法参数 400 ✓
- **性能实测**：首屏 2.0-4.1s（SC-001 <10s ✓）；筛选刷新 2.0-2.4s（SC-002 <3s ✓）；瓶颈为远程 dev 库网络延迟，生产环境预期更快
- **自检**：type:check ✓、eslint ✓、stylelint ✓、vitest 38/38 ✓、build:client 生产构建 ✓、8 个改动模块 vite dev 转换 200 ✓、客户端日志无错误 ✓
- **待人工浏览器验收**（无浏览器自动化工具，建议发布 dev 后按 quickstart.md Scenario 1-4 走查）：全屏弹窗缩放交互、TOC 平滑滚动、排序箭头三态、固定列滚动吸附、窗口选择器切换
- **遗留优化候选**（非阻塞）：overview 服务内目标/分母查询并行化；达成等级（achieveLevel）业务规则确认；日活覆盖率分母依赖 ads_mall_cat1_daily；Top 数据待 ads_top_stat_daily

---

## Dependencies

### User Story Dependencies

- **US1 (四级类目数据概览)**: 无依赖，可独立实现
- **US2 (商家四级类目数据概览)**: 无依赖，可独立实现
- **US3 (商品数据概览)**: 无依赖，可独立实现
- **US4 (筛选器联动与数据刷新)**: 依赖 US1, US2, US3（需要表格组件先实现）
- **US5 (表格交互与数据展示)**: 依赖 US1, US2, US3（需要表格组件先实现）

### Phase Dependencies

- **Phase 1 (Setup & Database)**: 无依赖
- **Phase 2 (Backend API Development)**: 依赖 Phase 1（需要数据库表先创建）
- **Phase 3 (Frontend Implementation)**: 依赖 Phase 2（需要后端 API 先实现，但可使用 mock 数据先行开发）
- **Phase 4 (Integration & Testing)**: 依赖 Phase 3（需要前端组件先实现）

---

## Parallel Execution Examples

### Phase 1: Setup & Database

- T001-T003 可并行（创建三个 ADS 同步表）
- T004-T006 可并行（创建三个目标表）
- T007-T012 可并行（创建所有索引）

### Phase 2: Backend API Development

- T016-T017 可并行（创建 Controller 和 Service）
- T020-T021 可并行（ADS 表查询和目标表查询）
- T023a-T023g 可并行（实现各个计算逻辑工具函数）
- T029-T031 可并行（编写各个单元测试）

### Phase 3: Frontend Implementation

- **US1, US2, US3 可并行**（三个表格组件相互独立）
  - T033-T040 (US1)
  - T041-T049 (US2)
  - T050-T059 (US3)
- T060-T063 可并行（实现表格交互功能）
- T064-T070 需按顺序执行（页面布局 → TOC → API 对接）

### Phase 4: Integration & Testing

- T071-T075 可并行（实现筛选器各个下拉选择）
- T081-T088 可并行（执行各个端到端测试场景）
- T089-T092 可并行（执行各个性能测试）
- T093-T098 可并行（执行各个边界场景测试）

---

## Implementation Strategy

### MVP First

**MVP 范围**（Phase 1 + Phase 2 + Phase 3）：
- 数据库表创建（Phase 1）
- 后端 API 实现（Phase 2）
- 前端三个表格组件实现（Phase 3）
- 概览页面布局和 TOC（Phase 3）

**MVP 验证**：
- 打开概览页面，三个表格能正常加载并展示数据
- 表格包含所有定义的列（包括 Top 相关列，即使数据为空）
- 支持分页、排序、全屏放大
- 右侧 TOC 显示三个 section 标题，点击后平滑滚动到对应表格

### Incremental Delivery

**迭代 1**（Phase 1 + Phase 2）：
- 数据库表创建
- 后端 API 实现
- 单元测试通过

**迭代 2**（Phase 3）：
- 前端三个表格组件实现
- 概览页面布局和 TOC
- API 对接成功

**迭代 3**（Phase 4）：
- 筛选器联动与数据刷新
- 端到端测试通过
- 性能测试通过
- 边界场景测试通过

### Success Metrics

- **SC-001**: 用户打开概览页面后，三个表格在 10 秒内完成加载（首屏加载）
- **SC-002**: 用户通过筛选器切换条件后，三个表格在 3 秒内完成刷新
- **SC-003**: 用户刷新页面后，筛选条件 100% 保留（通过 URL 参数）
- **SC-004**: 表格分页、排序、全屏放大等交互功能 100% 可用，无阻塞性 bug
- **SC-005**: Top 相关字段暂无数据时，表头正常显示，单元格显示占位符，不影响其他列的数据展示

---

## Notes

- 所有任务必须遵循 CLAUDE.md 中的开发规范
- 前端开发使用 mock 数据先行，后端 API 就绪后进行数据对接
- Top 相关数据暂缺，表头需呈现，单元格显示占位符
- 数据准确性是基线，所有计算逻辑由后端实现，前端只负责展示
- 发布前必须测试：先发布到 dev 环境验证，再手动发布到 online
- AI 助手不自动执行 `git commit` 或 `git push`，仅在用户明确要求时才执行
