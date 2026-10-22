# 商家复盘 - 妙搭应用

商家复盘可视化看板，用于商家数据分析和业务复盘。

## 项目信息

- **应用 ID**: `app_17g5uw7qhs7`
- **应用类型**: 全栈应用
- **技术栈**: NestJS + React 19 + TypeScript
- **工作分支**: `sprint/default`

## 开发的 Skills

> **Skill 位置速查**（便于复制迁移）
>
> | 层级 | 路径 | 本项目的 Skill |
> |------|------|----------------|
> | 子项目级 | `merchant-review/.claude/skills/` | **csv-to-db-import**（自研，merchant-review 仓库 commit `9fb375e`）；其余 11 个（coding-guide、authz-guide、plugin-guide、trigger-guide、mcp-guide、openapi-guide、code-fix、miaoda-init、client-builtins-user-service、server-contacts-contract、user-identity）为妙搭官方模板自带 |
> | 本仓库级 | `.claude/skills/` | fuzzy-discovery、data-governance-checker、speckit-*（Spec Kit 工具链） |
> | 全局 | `~/.claude/skills/` | capturing-learning-notes（见下） |
>
> 迁移方式：Skill 均为**自包含目录**，整目录拷贝到目标项目的 `.claude/skills/`（或 `~/.claude/skills/`）即生效；脚本零第三方依赖，仅需 `python3`（≥3.10）和项目内可用的 `lark-cli`。

### csv-to-db-import

**位置**: `merchant-review/.claude/skills/csv-to-db-import/`

把数仓 / 飞书多维表格导出的 CSV 核对并灌入妙搭应用库（PostgreSQL）的 `ads_*` / `biz_*` 表，dev / online 皆可、带护栏。

**核心不变式**（三条，不可违反）:
1. **列核对先行**——任何写库前必须 CSV 列 ↔ 真实库列做 diff（实时从 `+db-table-get` 拉，不维护常驻配置，DB 是唯一真相源）
2. **人来做决定**——删列（门1）、删数据（门2）、写 online（门3）一律硬门、停下等人工确认
3. **可重跑幂等**——正式导入前按 `dt` 范围 `DELETE ... WHERE dt BETWEEN` 先删后插（禁止无 WHERE 全表删除）

**文件结构**:
```
merchant-review/.claude/skills/csv-to-db-import/
├── SKILL.md                      # 8 阶段流程编排 + 三门话术模板 + lark-cli 命令速查 + 校验 SQL 模板
└── scripts/
    ├── normalize_db_cols.py      # +db-table-get 原始输出 → [{name,type,nullable,default}]
    ├── reconcile_csv.py          # 只读：列 diff（三态）+ rename 候选 + 风险扫描，零副作用
    ├── prep_csv.py               # 按确认的丢弃清单转换（\N→空），csv 模块保 JSON 字段无损
    └── tests/                    # python3 -I -m unittest discover -s scripts/tests -t scripts
```

**触发方式**:
- "把 xxx.csv 同步到 yyy 表"、"导入数仓数据"、"验证表契约"

**已验证跑通**（dev，2026-10-19~20 累计 6 张表）:
`ads_sku_daily`(562)、`ads_category_daily`(12)、`ads_mall_cat1_daily`(89)、`ads_mall_daily`(48)、`ads_top_all_daily`(168)、`ads_merchant_category_daily`(272)；运行记录见 `merchant-review/logs/csv-db-import.log`

**已知坑**（写在 SKILL.md 内，迁移其它项目同样适用）:
- MaxCompute 导出带 UTF-8 BOM（读用 `utf-8-sig`）；空值标记 `\N`；字段内嵌逗号/中文 JSON 必须走 `csv` 模块，禁止 `split(',')`
- lark-cli `+db-execute` 会把 SQL 里的 `?` 当参数占位符——校验 SQL 禁用 jsonb `?` 算子，`::jsonb` 转换可用且要先排除 `''`
- 表名映射不能靠文件名推断（如 `ads_sku.csv` → `ads_sku_daily`、`ads_cat.csv` → `ads_category_daily`），需人工确认

**设计文档**: `merchant-review/docs/superpowers/specs/2026-10-19-csv-to-db-import-skill-design.md`、`merchant-review/docs/superpowers/plans/2026-10-19-csv-to-db-import-skill.md`

### capturing-learning-notes

**位置**: `~/.claude/skills/capturing-learning-notes/`

标准化的个人知识沉淀 skill，将学习过程中的知识点整理为结构化文档。

**功能**:
- 9 步标准化流程：检测目录 → 提取知识 → 识别类型 → 生成 frontmatter → 校验内容 → 保存文档 → 校验文件 → 更新索引 → 校验索引
- 双层分类体系：8 个默认分类（前端技术、后端技术、开发运维、开发工具、平台相关、架构设计、最佳实践、软技能）
- 5 种文档类型：决策记录、问题解决、最佳实践、教程指南、知识笔记
- 自动索引更新
- 跨项目资产合并

**触发方式**:
- "记录学习笔记"
- "沉淀知识"
- "总结一下这次讨论"

**文件结构**:
```
~/.claude/skills/capturing-learning-notes/
├── SKILL.md          # 核心流程（9 步）
├── README.md         # 框架背景与路线图
├── config.json       # 默认配置
└── templates/
    └── frontmatter.md # Frontmatter 模板
```

## 个人资产

### 学习笔记

**位置**: `docs/LearningNote/`

个人学习笔记目录，不作为项目上下文，已在 `.claude/settings.json` 中排除。

**目录结构**:
```
docs/LearningNote/
├── index.md          # 学习笔记索引
├── devops/           # 开发运维
├── frontend/         # 前端技术
├── backend/          # 后端技术
├── tools/            # 开发工具
├── platform/         # 平台相关
├── architecture/     # 架构设计
├── practice/         # 最佳实践
└── soft-skill/       # 软技能
```

**当前文档**:
- `devops/2026-01-18-pre-commit-hook-最佳实践.md` - Pre-commit Hook 最佳实践
- `miaoda/2026-10-17-本地开发数据库配置.md` - 妙搭本地开发数据库配置
- `practice/2026-10-17-使用-Subagent-Driven-Development-实现文档型-Skill.md` - 使用 SDD 实现文档型 Skill

## 快速开始

```bash
# 安装依赖
npm install

# 启动开发环境
make dev-start

# 代码检查
npm run lint

# 构建
npm run build
```

## 相关文档

- [CLAUDE.md](CLAUDE.md) - 项目开发规范和流程
- [Makefile](Makefile) - 常用命令
- [docs/superpowers/](docs/superpowers/) - 设计文档和实现计划
