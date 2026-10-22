---
name: data-governance-checker
description: 检查数据仓库设计的规范性（命名、数据类型、业务定义），输出检查报告和修复建议。支持 Markdown 表格、SQL DDL、用户直接输入三种格式。
---

# Data Governance Checker

检查数据仓库设计的规范性，输出检查报告和修复建议。

## 使用场景

**显式触发：**
- "检查指标规范性"、"检查命名规范"、"检查数据类型"
- "检查数仓设计"、"检查字段命名"
- "/data-governance-checker"

**隐式触发：**
- 用户提供了一批指标定义，要求检查规范性
- 用户粘贴了 SQL DDL，要求检查数据类型

## 执行流程

按以下 7 个步骤顺序执行，每步完成后向用户展示进度。

### 步骤 1：加载配置

按优先级扫描配置文件：

1. `.claude/data-governance.json`（项目级）
2. `~/.claude/data-governance.json`（用户级）
3. SKILL 内置默认配置（`config/default-config.json`）

**找到 →** 加载配置，合并缺失字段用默认值填充。
**未找到 →** 使用内置默认配置，提示用户："未找到自定义配置，使用默认配置。是否创建项目级配置？"

配置合并规则：项目级 > 用户级 > 默认配置，按字段深度合并。

### 步骤 2：检测报告存储目录

按以下顺序扫描：

1. 配置中 `reportPath` 指定的路径
2. `docs/data-governance/reports/`
3. `docs/governance/`
4. `docs/data-quality/`
5. 当前目录 `./`

**找到 →** 使用该目录。
**未找到 →** 推荐 3 个选项让用户选择：
- 选项 A：`docs/data-governance/reports/`（推荐）
- 选项 B：`docs/governance/`
- 选项 C：当前目录

用户选择后创建目录。

### 步骤 3：确认检查范围

> **⛔ GATE — 必须在此暂停，等待用户回复后才能继续。**
> 不得跳过此步骤。即使用户之前说过"检查"或"开始"，也必须展示确认信息并等待本次回复。

向用户展示确认信息：

```
请确认本次检查的范围：

检查层面（可多选）：
☑ A. 命名规范
☑ B. 数据类型规范
☑ C. 业务定义完整性

严格程度：
○ 使用配置文件中的设置（默认）
○ 本次全部为 ERROR
○ 本次全部为 WARNING
```

**暂停，等待用户回复。** 用户回复后才可进入步骤 4。

快捷确认：如果用户说"确认""开始""默认""ok"等肯定词，使用默认设置（A+B+C，配置文件严格程度）直接进入步骤 4。

### 步骤 4：解析输入

**自动检测输入格式：**

| 检测条件 | 判定格式 |
|---------|---------|
| 包含 `CREATE TABLE`（不区分大小写） | SQL DDL |
| 包含 `\| --- \|` 或 `\|---\|` | Markdown 表格 |
| 其他 | 用户直接输入 |

**解析为统一结构：**

每个字段解析为以下结构：

```json
{
  "name": "指标名称（中文）",
  "id": "指标标识（英文字段名）",
  "type": "数据类型",
  "definition": "业务定义",
  "source": "来源行号或位置"
}
```

**Markdown 表格解析规则：**
- 跳过表头行和分隔行
- 按 `|` 分割每行
- 去除首尾空白
- 空单元格视为空字符串

**SQL DDL 解析规则：**
- 提取 `CREATE TABLE` 和 `)` 之间的内容
- 按 `,` 分割字段定义（注意嵌套括号）
- 提取字段名和数据类型
- 注释（`--` 和 `/* */`）中的内容跳过
- 字段名称作为 `id`，`name` 留空

**用户直接输入解析规则：**
- 按行分割
- 每行按 `|`、`、`、`,`、空格（连续多个）分割
- 第一个非空字段作为 `name`，第二个作为 `id`，第三个作为 `type`，第四个作为 `definition`

**解析完成后向用户确认：**

> **⛔ GATE — 必须在此暂停，等待用户回复后才能继续。**
> 不得跳过此步骤。必须展示解析结果并等待用户确认。

```
检测到输入格式为：{格式}，共 {N} 个字段。确认开始检查？
```

**暂停，等待用户回复。** 用户回复后才可进入步骤 5。

快捷确认：如果用户说"确认""开始""ok"等肯定词，直接进入步骤 5。

### 步骤 5：执行检查

根据用户确认的检查范围，依次执行对应的规则检查。

每条规则检查后，记录问题到问题列表：

```json
{
  "level": "ERROR | WARNING | INFO",
  "rule": "规则名称",
  "field": "字段标识",
  "fieldName": "字段名称",
  "current": "当前值",
  "problem": "问题描述",
  "suggestion": "修复建议",
  "suggestedValue": "建议修复值"
}
```

#### 5.1 命名规范检查

**规则 N1：数量单位统一**

检查字段标识的后缀是否与语义匹配：

| 后缀 | 语义 | 检查逻辑 |
|------|------|---------|
| `_num` | 数量/件数 | 字段名含 goods、order、store、sku 等 + 表示计数 |
| `_amt` | 金额 | 字段名含 amt、amount、fee、price、cost、commission、subsidy、refund |
| `_rate` | 比率 | 字段名含 rate、ratio |

**检查逻辑：**
1. 如果字段标识以 `_amt` 结尾但名称含"件数""数量""门店数"→ ERROR：金额后缀用于数量
2. 如果字段标识以 `_num` 结尾但名称含"金额""货值""费用""补贴"→ ERROR：数量后缀用于金额
3. 如果字段标识以 `_rate` 结尾但名称不含"率""比"→ WARNING：比率后缀用于非比率
4. 如果字段标识包含 `amount` → WARNING：建议用 `_amt` 替代 `amount`

**规则 N2：时间窗口后缀**

检查字段标识中的时间窗口后缀是否规范：

合法后缀列表（从配置读取）：
- 单日：`_1d` / `_7d` / `_30d` / `_cd`（当日）
- 周期：`_mtd`（月至今）/ `_ytd`（年至今）
- 过去：`_m1d` / `_m2d` / `_m3d` / `_m7d`（T-N日）
- 未来：`_a1d` / `_a3d` / `_a7d`（T+N日）
- 范围：`_m{N}dt{M}d`（T-N到T-M），如 `_m6dt0d`（T-6到T0，近7天）、`_m2dt0d`（T-2到T0，近3天）

**检查逻辑：**
1. 如果字段标识包含数字+`d` 但不匹配合法后缀（如 `_7day`、`_3days`）→ ERROR：时间窗口后缀不规范
2. 如果字段标识包含 `m` + 数字 + `d`（如 `_m2d`、`_m7d`）→ 合法（T-N 语义）
3. 如果字段标识包含 `a` + 数字 + `d`（如 `_a3d`）→ 合法（T+N 语义）
4. 如果字段标识包含 `m{N}dt{M}d`（如 `_m6dt0d`）→ 合法（T-N到T-M 范围语义）
5. 注意：`_t0d` 不单独使用，只作为范围后缀的一部分（如 `_m6dt0d`）

**规则 N3：客户类型后缀**

检查客户类型后缀是否规范：

合法后缀：`_new` / `_old` / `_recall`

**检查逻辑：**
1. 如果字段标识包含 `_loss` → WARNING：建议用 `_recall` 替代 `_loss`
2. 如果字段标识包含 `_store` 结尾且前面是 `_old` / `_new` → INFO：可能歧义，确认是"老店"还是"老客户"

**规则 N4：避免前缀歧义**

**检查逻辑：**
1. 如果字段标识以 `new_`、`old_`、`recall_` 开头 → ERROR：应该用后缀而非前缀（如 `new_price` → `price_new`）

**规则 N5：标价 vs 成交价**

**检查逻辑：**
1. 如果字段标识以 `price_` 开头且不含 `actual` → 视为标价（维度表字段）
2. 如果字段标识以 `actual_price` 开头 → 视为成交价（事实表字段）
3. 如果字段标识含 `price` 但无法判断是标价还是成交价 → INFO：建议明确命名

#### 5.2 数据类型检查

**规则 T1：金额用 numeric**

检查逻辑：
1. 如果字段标识含 `_amt`、`amount`、`fee`、`price`、`cost`、`commission`、`subsidy`
2. 且数据类型为 `int`、`integer`、`bigint`、`smallint`、`float`、`double`、`real`
3. → ERROR：金额应该用 `numeric(18,2)` 或 `decimal(18,2)`

**规则 T2：件数用整数类型**

检查逻辑：
1. 如果字段标识含 `_num`、`_cnt`、`count`
2. 且数据类型为 `numeric`、`decimal`、`float`、`double`、`text`、`varchar`
3. → WARNING：件数应该用整数类型（`int` / `bigint` / `smallint` / `tinyint`）

**规则 T3：比率用 numeric**

检查逻辑：
1. 如果字段标识含 `_rate`、`ratio`
2. 且数据类型为 `float`、`double`、`real`
3. → WARNING：比率建议用 `numeric(5,4)` 或 `decimal(5,4)`，避免浮点精度问题

**规则 T4：text 类型检查**

检查逻辑：
1. 如果数据类型为 `text`
2. 且字段标识含 `_info`、`_json`、`_mapping`、`_detail`
3. → WARNING（仅提醒）：text 类型存储结构化数据，建议考虑拆分为多行或多列

#### 5.3 业务定义完整性检查

**规则 D1：业务定义非空**

检查逻辑：
1. 如果 `definition` 为空或只包含空白字符
2. → ERROR：业务定义缺失

**规则 D2：计算口径明确**

检查逻辑：
1. 如果 `definition` 包含"平均""每""占比""率"等词
2. 但 `definition` 不包含 `=`、`/`、`÷`、`公式`等计算符号
3. → WARNING：建议补充计算公式

**规则 D3：排除条件明确**

检查逻辑：
1. 如果 `definition` 包含"有效""合格""正常"等限定词
2. 但 `definition` 不包含括号说明或具体条件
3. → WARNING：建议明确"有效"的定义（如"已支付且未退款"）

### 步骤 6：生成报告

#### 6.1 统计信息

```
总字段数：{N}
问题数：{total}（ERROR: {error_count}, WARNING: {warning_count}, INFO: {info_count}）
通过率：{pass_rate}%（无问题的字段占比）
```

#### 6.2 问题列表

按严格程度分组展示：

```markdown
## ERROR 级别问题（必须修复）

### {序号}. {规则名称}
- **字段**：{字段名称}（`{字段标识}`）
- **当前值**：`{当前值}`
- **问题**：{问题描述}
- **建议修复**：`{建议修复值}`

---

## WARNING 级别问题（建议修复）

（同上格式）

---

## INFO 级别问题（可选优化）

（同上格式）
```

#### 6.3 修复后的版本

根据所有 ERROR 和 WARNING 的修复建议，生成修复后的完整字段列表。

**Markdown 表格输入 → 输出修复后的 Markdown 表格**
**SQL DDL 输入 → 输出修复后的 SQL DDL**
**用户直接输入 → 输出修复后的表格**

修复规则：
- ERROR 级别：自动应用修复建议
- WARNING 级别：自动应用修复建议，但标注 `[已自动修复]`
- INFO 级别：不自动修复，保留原值

#### 6.4 保存报告

报告文件名：`{YYYY-MM-DD}-check-report.md`

报告内容结构：

```markdown
# 数据规范性检查报告

**检查时间**：{YYYY-MM-DD HH:mm:ss}
**输入格式**：{Markdown 表格 / SQL DDL / 用户直接输入}
**检查范围**：{命名规范、数据类型、业务定义}
**配置文件**：{配置文件路径 或 "默认配置"}

## 检查统计

- 总字段数：{N}
- 问题数：{total}（ERROR: {error_count}, WARNING: {warning_count}, INFO: {info_count}）
- 通过率：{pass_rate}%

## ERROR 级别问题（必须修复）

（问题列表）

## WARNING 级别问题（建议修复）

（问题列表）

## INFO 级别问题（可选优化）

（问题列表）

## 修复后的版本

（修复后的完整字段列表）
```

### 步骤 7：输出结果

**保存报告到文件后，在对话中展示摘要：**

```
✅ 检查完成

📊 统计：{N} 个字段，{total} 个问题（ERROR: {error_count}, WARNING: {warning_count}）
📄 报告：{report_path}

主要问题：
- {问题1}（{级别}）
- {问题2}（{级别}）
- {问题3}（{级别}）

修复后的版本已生成，是否采纳？
```

如果用户说"采纳"或"确认"，将修复后的版本输出为最终结果。
如果用户说"不采纳"或"部分采纳"，询问具体哪些修复需要保留。

## 配置说明

### 配置文件格式

```json
{
  "version": "1.0",
  "reportPath": "docs/data-governance/reports",
  "rules": {
    "naming": {
      "countSuffix": "_num",
      "amountSuffix": "_amt",
      "rateSuffix": "_rate",
      "timeWindowSuffix": ["_1d", "_7d", "_30d", "_mtd", "_ytd", "_m7d", "_a3d", "_cdta3d", "_cd"],
      "customerTypeSuffix": ["_new", "_old", "_recall"]
    },
    "dataType": {
      "amountType": ["numeric", "decimal"],
      "integerTypes": ["int", "integer", "bigint", "smallint", "tinyint"],
      "rateType": ["numeric", "decimal"],
      "textCheck": {
        "enabled": true,
        "strictMode": false,
        "suggestSplit": true
      }
    }
  },
  "strictness": {
    "naming": "ERROR",
    "dataType": "WARNING",
    "definition": "WARNING"
  }
}
```

### 配置字段说明

| 字段 | 类型 | 说明 | 默认值 |
|------|------|------|--------|
| `version` | string | 配置版本号 | `"1.0"` |
| `reportPath` | string | 报告存储路径（相对路径） | `"docs/data-governance/reports"` |
| `rules.naming.countSuffix` | string | 数量/件数后缀 | `"_num"` |
| `rules.naming.amountSuffix` | string | 金额后缀 | `"_amt"` |
| `rules.naming.rateSuffix` | string | 比率后缀 | `"_rate"` |
| `rules.naming.timeWindowSuffix` | array | 合法时间窗口后缀列表 | 见配置文件 |
| `rules.naming.customerTypeSuffix` | array | 合法客户类型后缀列表 | `["_new", "_old", "_recall"]` |
| `rules.dataType.amountType` | array | 金额合法数据类型 | `["numeric", "decimal"]` |
| `rules.dataType.integerTypes` | array | 整数合法数据类型 | `["int", "integer", "bigint", "smallint", "tinyint"]` |
| `rules.dataType.rateType` | array | 比率合法数据类型 | `["numeric", "decimal"]` |
| `rules.dataType.textCheck.enabled` | boolean | 是否启用 text 类型检查 | `true` |
| `rules.dataType.textCheck.strictMode` | boolean | text 检查是否为严格模式 | `false` |
| `rules.dataType.textCheck.suggestSplit` | boolean | 是否建议拆分结构化 text | `true` |
| `strictness.naming` | string | 命名规范检查的严格程度 | `"ERROR"` |
| `strictness.dataType` | string | 数据类型检查的严格程度 | `"WARNING"` |
| `strictness.definition` | string | 业务定义检查的严格程度 | `"WARNING"` |

## 关联知识

- [[数据指标字典建设方法论与2026年演进趋势]]
- [[原子指标设计-业务过程-业务对象与修饰词的最佳实践]]
- [[商品属性维度设计与分客户类型定价的指标命名规范]]
- [[交叉场景指标命名规范-售后复购类指标]]
- [[多时间维度DWS设计-按订单日期与按事件日期的双粒度方案]]
