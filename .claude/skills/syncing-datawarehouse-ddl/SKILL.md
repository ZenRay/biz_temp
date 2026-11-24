---
name: syncing-datawarehouse-ddl
description: Use when 数仓 dataSQL/Automation 产出表新增或变更列（扩列、改注释、类型调整）、需要承接到妙搭 PG 库（生成 DDL、更新 schema.ts、dev 执行并验证数据），或 ETL 门1「列核对」报「CSV 表头出现表外列」中止时。触发词：dataSQL 扩列、DDL、schema.ts、+db-execute、ads_* 表、新列 NULL、导入中止。
---

# 数仓扩列 → DDL 承接 → dev 生效

## 核心原则

数仓（ODPS）产出表扩列是**结构先行**的：Got SQL 若是 `SELECT t1.*`，新列会**立刻出现在导出 CSV 表头（值可能全空）**，而 `scripts/import_data2miaoda.sh` 门1 会因「CSV 有表外列」中止该表全部导入。**所以承接 DDL 有紧迫性**——不是「等数据有了再建列」，而是「列先到、数据后到」。

开发期默认只处理 dev；online 仅在用户明确下令时纳入（CLAUDE.md 2026-10-31 裁决）。

## 变更类型分流（先判型，再走流程）

| 类型 | 走法 |
|---|---|
| **新增列** | 全流程 ①→⑦ |
| **改列注释**（列名/类型不变） | 只走 ①②④⑤：DDL 文件内 `COMMENT ON` **逐条单独执行**；验证查 `pg_description`（见坑表）；**豁免** ③schema.ts/⑥ETL/发布——注释对 CSV、门1、前端零影响 |
| **改名/类型变更** | **本技能模板不适用**（无 `ADD COLUMN IF NOT EXISTS` 形态）。纪律反转：DDL **不得先行**，必须与数仓切换同窗（任一侧先改，`t1.*` 表的 CSV 表头即与库不匹配、门1 天天中止该表导入）；`RENAME COLUMN` **不幂等**——执行前先查 information_schema 列现状，只见旧名才执行，中断重跑前必须重查；schema.ts 同批改列名后 `type:check`。先向数仓确认是否整族改名（族内分裂=口径混淆雷） |

## 流程（新增列主路径，按序执行）

### ① 核实变更事实（只读，不凭需求描述下结论）

```bash
cd /home/ray/Documents/RecentWorks/BIDashboard
git log --oneline -5 -- dataSQL/            # 数仓侧最近的扩列提交
git diff <上一个提交> -- dataSQL/backup.sql  # 钉死：列名逐字、类型（BIGINT/DECIMAL）、中文注释原文
```

三件必须核实的事：
- 新列在**最终 SELECT 输出**里（只在中间 CTE 出现=没出来，先催数仓，不承接）。
- **口头描述与实测冲突时停手取证**：列事实三选一定权威凭据——dataSQL 提交行号 / ODPS `DESC <源表>` 列清单 / 一份非空真实 CSV 表头。拿不到就**不写 DDL**（按描述建列=列名/类型漂移，DROP 易、RENAME 不幂等）。源表若是 DROP+CREATE 重建的 temp 表（如 mct_cat4 族），表头可非追加变化，一次进来可能不止一列。
- Got 导出 SQL 的投影形态（在仓库同级目录 `/home/ray/Documents/RecentWorks/Automation/Got/<表>.sql`，不在 BIDashboard 内）：`t1.*` 自动带列；显式列清单则需数仓/我们补列（`grep -c <新列名> <该文件>` 得 0 且投影是 `*` = 通配自动带，别误判成「没带列」）。
- 最新 CSV 现状：`head -1 data/<表>.csv | tr ',' '\n' | grep <新列>`（表头到了没）＋抽样值是否非空（值到了没）。表头到、值空 = 正常中间态。

### ② 写 DDL 文件

路径 `merchant-review/server/database/ddl/NNN_YYYYMMDD_<表>_<描述>.sql`。
**编号以执行时 `ls server/database/ddl/` 尾号+1 为准**（并行会话可能已占号；biz_sku_target DROP 预留号顺延）。

模板（幂等三件套 + 五段头注释）：

```sql
-- NNN: <表> 新增 k 列 —— <业务族一句话>
-- 来源：数仓 <ODPS 表> <日期> 扩列（dataSQL/<文件>:<行号>）。
-- 口径：<抄数仓注释的业务定义，含窗口语义如「上周同日值」「T-6~T 累计」>。
-- 类型：计数列 bigint；金额列 double precision（数仓 DECIMAL(x,2) 按本表既有惯例落 double，
--   先 grep schema.ts 同表既有金额列确认惯例）。
-- 数据流：<Got 投影形态判定结论 + 值何时到>。
-- 执行状态：待执行。（执行后回填）

ALTER TABLE IF EXISTS <表>
  ADD COLUMN IF NOT EXISTS <col> bigint,
  ...;
COMMENT ON COLUMN <表>.<col> IS '<中文注释>';
```

**不加 NOT NULL、不加默认值**——历史行留 NULL 是预期状态，不是缺陷。

### ③ 手写 schema.ts 同步

在对应表定义（如 `adsCategoryDaily`）追加列定义，类型与 DDL 逐列一致：计数 `bigint("col", { mode: 'number' })`、金额 `doublePrecision("col")`。

**禁止跑 `npm run gen:db-schema`**——它按 online 库全量重生成，会丢掉 dev-only 未上线列（commit 105487a 教训）。

验证：`npm run type:check`（改完即跑）。

### ④ dev 执行 DDL（常规操作，`--yes` 必带）

在 `merchant-review/` 目录下：

```bash
lark-cli apps +db-execute --app-id app_17g5uw7qhs7 --environment dev --yes \
  --sql "$(cat server/database/ddl/NNN_*.sql)"
```

### ⑤ 验证生效（不信任执行命令的回显）

`+db-execute` 可能报 error/missing_result/rows_affected=0 而实际已成功。**唯一判据 = information_schema 复核**：

```bash
lark-cli apps +db-execute --app-id app_17g5uw7qhs7 --environment dev --yes \
  --sql "SELECT column_name, data_type, is_nullable FROM information_schema.columns
         WHERE table_name='<表>' AND column_name IN (<新列清单>) ORDER BY column_name;"
```

行数齐、类型对、is_nullable=YES → 成功；缺列 → 语句拆开逐条重跑（幂等安全）再查。

再加一道**门1 同源复核**（门1 列核对读的是 `+db-table-get` 而非 information_schema，用它确认「导入侧已可见」）：
`lark-cli apps +db-table-get --app-id app_17g5uw7qhs7 --table <表> --environment dev | grep <新列名>`

随后：`ss -tlnp | grep :3000` 查 DDL 是否拉起陈旧 `node dist/server/main` 进程占端口（占则 kill + `make dev-restart`）。

### ⑥ 验证数据（小窗，防 COUNT 超时误判）

```bash
lark-cli apps +db-execute --app-id app_17g5uw7qhs7 --environment dev --yes \
  --sql "SELECT dt, count(*) rows, count(<新列>) nn FROM <表> WHERE dt >= '<近3天>' GROUP BY dt ORDER BY dt DESC;"
```

- nn=0 且 CSV 值也空 → 「结构已承接、数据等数仓出值」，如实回写 DDL 头注释「执行状态」，**不重灌、不改代码凑数**。
- nn>0 → 抽一行与数仓口径手算比对（数据准确性是基线）。

门1 中止过的表要恢复灌数（dev 常规）：好 CSV 已在 `data/` → `./ETL2miaoda.sh --skip-export --only <表> --env dev`；需重导 → 去掉 `--skip-export`。前置：`logs/etl/.etl.lock` 空闲（`flock -n`，有实例在跑会 exit 3，别 kill 别人的实例、别绕锁手工跑 `batch_export_sql.sh`）。**验证窗口按该表 Got SQL 的实窗算**（各表不同：多数 16 天，distribute 族只有 7 天），clear 幂等只删本批 CSV 覆盖的 dt 范围。

### ⑦ 收尾（均需用户明确指示，不得自动做）

- `git add <逐个文件>` + commit（禁 `git add -A`、禁自动提交、commit 不带署名尾行）。
- push `sprint/default` + `lark-cli apps +release-create --app-id app_17g5uw7qhs7 --branch sprint/default --apply-reason "..."`（仅消费新列的代码需随发；纯 DDL+schema.ts 可搭下次发布）。
- online：见下方两个坑。

## 实证坑（本仓实测，别再踩）

| 坑 | 事实 | 对策 |
|---|---|---|
| dev→online 结构同步 | **dev release 会自动把 schema 同步到 online**（2026-11-04 实测：发布后 online information_schema 直接有新列） | 不必默认规划 `+db-env-migrate`；要判 online 结构只认 online `information_schema` 直查（`--environment online`） |
| `+db-env-diff` | 对比目标是**发布快照分支 "main"，不是 online 库**；返回 `changes:[]` ≠ online 有该列 | 判断 online 结构别用它 |
| Got `t1.*` | CSV 表头先到、值后到（甚至长期 NULL） | 门1 中止 = 承接 DDL 的触发信号；NULL 属预期，写入 DDL 头注释 |
| lark-cli 回显 | 可能假报错/假 rows_affected=0 | 一律 information_schema / count 复核后再决定是否重跑 |
| gen:db-schema | 按 online 重生成，丢 dev-only 列 | 扩列一律手写 schema.ts |
| 大窗校验 | count(*) 全表可能超时误判失败 | 先 `WHERE dt >=` 小窗 |
| 整文件多语句执行 | `--sql "$(cat NNN.sql)"` 可**静默丢尾段**（031 实证：ALTER 落了、7 条 COMMENT 全丢，回显无异常） | 分段执行（ALTER 一段、每条 COMMENT 各一段），且每段用各自的判据复核 |
| 空 CSV（0 行导出） | 4 字节 BOM+LF、无表头时，门1 报的是「必需列缺失」**不是**「表外列」——别按错列方向排查；根因在上游导出 0 行（重导/催数仓），**严禁改 CSV 表头迁就库结构** |
| 注释验证判据 | `information_schema.columns` **不含注释**，查不出 COMMENT 丢没丢 | 只认 `pg_description`：`SELECT a.attname, d.description FROM pg_class c JOIN pg_attribute a ON a.attrelid=c.oid LEFT JOIN pg_description d ON d.objoid=c.oid AND d.objsubid=a.attnum JOIN pg_namespace n ON n.oid=c.relnamespace WHERE c.relname='<表>' AND n.nspname='workspace_aadkzzkymjidu' AND a.attname IN (<列清单>) AND a.attnum>0;` |

## 授权边界

| 常规可做 | 须用户明确指示 |
|---|---|
| 只读探查、dev `+db-execute`（含 ALTER，带 `--yes`）、dev ETL 灌数 | git commit/push、release-create、任何 online 写、`+db-env-migrate` |

`ONLINE_CONFIRM=1` 只能由用户本人设置，agent 不得代设。

## 常见错误

- 「等数仓有值再建列」→ 门1 会先把该表导入打死。
- 按需求描述写 DDL 不核对 dataSQL 实际提交 → 列名/类型漂移。
- 用 `+db-env-diff` 空结果宣称「online 已同步」→ 比的是快照分支。
- DDL 执行后不查 3000 端口 → 前端 API 404/缺字段找不到原因。
