# Data Governance Checker

检查数据仓库设计的规范性，输出检查报告和修复建议。

## 功能

- **命名规范检查** — 数量/金额/比率后缀统一、时间窗口后缀、客户类型后缀、避免前缀歧义
- **数据类型检查** — 金额用 numeric、件数用整数类型、比率用 numeric、text 类型提醒
- **业务定义检查** — 定义非空、计算口径明确、排除条件明确

## 使用方式

### 方式 1：直接调用

```
/data-governance-checker
```

然后粘贴需要检查的内容。

### 方式 2：自然语言触发

```
请检查以下指标定义的规范性

| 指标名称 | 指标标识 | 数据类型 | 业务定义 |
|---------|---------|---------|---------|
| 客均货值 | delivered_goods_num_ps | numeric | 最终成功交易送达到平均一个门店的商品价值 |
```

### 方式 3：检查 SQL DDL

```
请检查以下表结构的规范性

CREATE TABLE dws_order_1d (
  dt DATE,
  store_id VARCHAR(50),
  ordered_goods_num INT,
  delivered_goods_amt INT
);
```

## 支持的输入格式

| 格式 | 检测方式 | 示例 |
|------|---------|------|
| Markdown 表格 | 包含 `\| --- \|` | 指标字典文档 |
| SQL DDL | 包含 `CREATE TABLE` | 表结构定义 |
| 用户直接输入 | 其他 | 对话中粘贴的字段列表 |

## 配置

### 项目级配置

创建 `.claude/data-governance.json`：

```json
{
  "version": "1.0",
  "reportPath": "docs/data-governance/reports",
  "rules": {
    "naming": {
      "countSuffix": "_num",
      "amountSuffix": "_amt",
      "timeWindowSuffix": ["_1d", "_7d", "_m7d", "_a3d"]
    }
  },
  "strictness": {
    "naming": "ERROR",
    "dataType": "WARNING"
  }
}
```

### 配置分层

| 层级 | 路径 | 用途 | 是否随项目迁移 |
|------|------|------|--------------|
| 项目级 | `.claude/data-governance.json` | 团队共享规范 | ✅ 是 |
| 用户级 | `~/.claude/data-governance.json` | 个人偏好 | ❌ 否 |
| 内置默认 | SKILL 内部 | 兜底配置 | ✅ 是 |

### 可配置项

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `reportPath` | 报告存储路径 | `docs/data-governance/reports` |
| `rules.naming.countSuffix` | 数量后缀 | `_num` |
| `rules.naming.amountSuffix` | 金额后缀 | `_amt` |
| `rules.naming.rateSuffix` | 比率后缀 | `_rate` |
| `rules.naming.timeWindowSuffix` | 合法时间窗口后缀 | 见默认配置 |
| `rules.naming.customerTypeSuffix` | 合法客户类型后缀 | `_new`, `_old`, `_recall` |
| `rules.dataType.amountType` | 金额合法类型 | `numeric`, `decimal` |
| `rules.dataType.integerTypes` | 整数合法类型 | `int`, `bigint`, `smallint`, `tinyint` |
| `strictness.naming` | 命名检查严格程度 | `ERROR` |
| `strictness.dataType` | 数据类型检查严格程度 | `WARNING` |
| `strictness.definition` | 业务定义检查严格程度 | `WARNING` |

## 输出

### 检查报告

保存到 `reportPath` 目录，文件名格式：`{YYYY-MM-DD}-check-report.md`

报告包含：
- 检查统计（总字段数、问题数、通过率）
- ERROR 级别问题列表（必须修复）
- WARNING 级别问题列表（建议修复）
- INFO 级别问题列表（可选优化）
- 修复后的完整版本

### 对话摘要

```
✅ 检查完成

📊 统计：42 个字段，15 个问题（ERROR: 5, WARNING: 10）
📄 报告：docs/data-governance/reports/2026-10-18-check-report.md

主要问题：
- 客均货值标识命名错误（ERROR）
- 金额字段数据类型错误（ERROR）
- 业务定义缺失（WARNING）

修复后的版本已生成，是否采纳？
```

## 检查规则详情

### 命名规范

| 规则 | 级别 | 说明 |
|------|------|------|
| 数量单位统一 | ERROR | `_num`=数量, `_amt`=金额, `_rate`=比率 |
| 时间窗口后缀 | ERROR | `_1d`/`_7d`/`_m7d`(T-7)/`_a3d`(T+3)/`_cdta3d`(T0到T+3) |
| 客户类型后缀 | ERROR | `_new`/`_old`/`_recall` |
| 避免前缀歧义 | ERROR | 用 `price_new` 而非 `new_price` |
| 标价 vs 成交价 | ERROR | `price_new`(标价) vs `actual_price_new`(成交价) |

### 数据类型

| 规则 | 级别 | 说明 |
|------|------|------|
| 金额用 numeric | ERROR | 金额用 `numeric(18,2)` 或 `decimal(18,2)` |
| 件数用整数类型 | WARNING | 件数用 `int`/`bigint`/`smallint`/`tinyint` |
| 比率用 numeric | WARNING | 比率用 `numeric(5,4)` 或 `decimal(5,4)` |
| text 类型检查 | WARNING | text 存储结构化数据时提醒拆分（仅提醒） |

### 业务定义

| 规则 | 级别 | 说明 |
|------|------|------|
| 定义非空 | ERROR | 所有字段必须有业务定义 |
| 计算口径明确 | WARNING | 含"平均""率"等词时建议补充公式 |
| 排除条件明确 | WARNING | 含"有效""合格"时建议明确条件 |

## 长期规划

### Phase 2：表结构规范检查（计划中）

| 检查项 | 说明 | 优先级 |
|--------|------|--------|
| 事实表归因字段 | 检查是否包含 `share_id`、`bd_id` 等归因字段 | P1 |
| 维度表冗余 | 检查维度表是否包含必要的冗余字段（如品类层级） | P1 |
| 快照字段 | 检查事实表是否包含必要的快照字段（如 `customer_type_at_order`） | P1 |
| 双日期字段 | 检查售后类事实表是否同时包含 `order_date` 和 `event_date` | P2 |

### Phase 3：架构设计规范检查（计划中）

| 检查项 | 说明 | 优先级 |
|--------|------|--------|
| DWS 双粒度设计 | 检查是否按不同时间维度拆分 DWS 表 | P1 |
| 事实表拆分 | 检查是否按业务过程拆分事实表 | P1 |
| 分层架构 | 检查 ODS → DWD → DWS → ADS 分层是否清晰 | P2 |
| 表命名规范 | 检查表名是否符合 `dwd_` / `dws_` / `ads_` 前缀规范 | P2 |

### Phase 4：高级功能（未来）

| 功能 | 说明 | 优先级 |
|------|------|--------|
| 指标血缘分析 | 自动追踪指标的来源和依赖关系 | P3 |
| 指标字典自动生成 | 从 SQL DDL 自动生成指标字典文档 | P3 |
| 跨项目规范同步 | 支持多项目间的规范配置同步 | P3 |
| 可视化报告 | 生成 HTML 格式的可视化检查报告 | P3 |

## 未完成项

### 已知限制

- [ ] 当前不支持检查存储过程、视图中的字段命名
- [ ] 不支持检查 ETL 脚本中的字段映射
- [ ] 不支持检查指标之间的逻辑关系（如比率 = 分子 / 分母）
- [ ] 不支持检查字段注释的完整性
- [ ] 不支持检查分区字段的命名规范

### 待优化项

- [ ] 增加更多行业特定的命名规范模板（零售、金融、互联网）
- [ ] 支持自定义规则扩展（用户可编写自定义检查规则）
- [ ] 支持批量检查（一次检查多个文件或目录）
- [ ] 支持增量检查（只检查新增或修改的字段）
- [ ] 支持检查历史记录（对比两次检查的差异）

### 待完善文档

- [ ] 编写详细的使用教程（含截图）
- [ ] 编写常见问题 FAQ
- [ ] 编写规则配置最佳实践
- [ ] 编写自定义规则开发指南
