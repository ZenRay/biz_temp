# BI Dashboard 项目

## 项目背景

### 业务场景

水果生鲜品类的日常复盘与诊断。业务方需要一个能支撑快速复盘的工具，能够查看数据，并在查看数据的过程中辅助诊断相关业务问题。

### 核心问题

当前复盘流程依赖飞书多维表格，存在以下瓶颈：

1. **工具性能差**：数据加载时间最高约 2 分钟，单一卡片修改时长超过 30 分钟
2. **诊断路径未工具化**：资深人员的诊断经验未显性化，运营人员缺乏系统化引导
3. **数据迭代慢**：搭建复杂，数据上线困难，无法快速响应复盘过程中的新数据需求

**结果**：日复盘耗时约 3 小时，远超业务可接受范围。

### 目标用户

- **主要用户**：运营人员、数据人员（约 10 人）
- **次要用户**：业务负责人、BD 成员

### 成功指标

- **基线**：数据准确率
- **核心目标**：复盘时间从 3 小时缩短到 **1 小时内**
- **节点目标**：打通 3 个品类

## 项目结构

```
BIDashboard/
├── CLAUDE.md                    # 本文件 - 项目背景说明
├── discovery.md                 # 发现文档 - 问题定义与 MVP 范围
├── 诊断框架 0.1.md              # 诊断框架初版（基于复盘会议逐字稿）
├── README.md                    # 项目 README
├── merchant-review/             # 妙搭开发目录（核心实现）
└── .claude/skills/              # 项目级 skills
    ├── fuzzy-discovery/         # 模糊发现 skill
    └── capturing-learning-notes/ # 知识沉淀 skill
```

## merchant-review 子项目

### 定位

**妙搭开发目录**，是本项目核心实现。基于飞书妙搭平台构建的全栈应用，用于替换飞书多维表格，解决性能和交互性问题。

### 技术栈

- **后端**：NestJS + Drizzle ORM
- **前端**：React 19 + shadcn/ui + Tailwind CSS
- **平台**：飞书妙搭（Miaoda）
- **应用 ID**：`app_17g5uw7qhs7`
- **工作分支**：`sprint/default`

### 详细文档

merchant-review 子项目的详细开发规范、环境配置、发布流程等，请参考：

👉 [merchant-review/CLAUDE.md](merchant-review/CLAUDE.md)

### 快速开始

```bash
cd merchant-review

# 初始化环境（推荐）
# 使用 miaoda-init skill 自动完成环境配置

# 或手动初始化
npm install
make dev-start

# 发布到 dev 环境（lark-cli 当前版本无 --environment 参数；full_stack 应用必须带 --apply-reason）
git push origin sprint/default
lark-cli apps +release-create --app-id app_17g5uw7qhs7 --branch sprint/default --apply-reason "发布说明"
```

### 可用 Skills

merchant-review 子项目提供了以下开发 skills：

- **coding-guide**: 项目编码规范（必读）
- **miaoda-init**: 环境初始化
- **authz-guide**: 权限控制
- **plugin-guide**: 插件集成
- **trigger-guide**: 自动化触发器
- **mcp-guide**: MCP 工具开发
- **openapi-guide**: OpenAPI 接口
- **code-fix**: 代码排错
- **client-builtins-user-service**: 前端用户鉴权
- **server-contacts-contract**: 用户信息查询
- **user-identity**: 用户身份

## 当前阶段

### MVP 范围（已确认）

**包含**：
1. 性能优化：替换飞书多维表格，解决加载时间长的问题
2. 检查清单：将诊断框架 v0.1 转化为可执行的检查清单
3. 快速迭代：简化数据上线流程
4. 交互式下钻：支持品类 → 商家 → SKU → 区县 → 门店

**不包含**：
- 异常触发流程（非 MVP）
- 决策树配置（非 MVP）
- 数据门禁自动化（人工判断）
- 品类差异化配置（待评估）
- 高代码系统（妙搭方案满足 10 人场景）

### 验证计划

1. **第 1-2 周**：原型验证（加载 < 10s，检查清单可用）
2. **第 3-4 周**：试运行（复盘时间 < 1h）
3. **第 5 周+**：品类扩展评估

## 关键文档

| 文档 | 用途 |
|------|------|
| [discovery.md](discovery.md) | 问题定义、需求假设、MVP 范围、验证计划 |
| [诊断框架 0.1.md](诊断框架 0.1.md) | 诊断流程、下钻顺序、异常场景、数据门禁 |
| [merchant-review/CLAUDE.md](merchant-review/CLAUDE.md) | 开发规范、环境配置、发布流程 |

## 外部资源

- **飞书文档**：https://bggc.feishu.cn/wiki/VZELwsM8oiBfuWk6sh7ccjEenvb（内网访问，详细数据需求）
- **妙搭后台**：https://miaoda.feishu.cn/app/app_17g5uw7qhs7
- **应用 ID**：`app_17g5uw7qhs7`

## 注意事项

1. **merchant-review 是独立子项目**：有自己的 git 仓库、CLAUDE.md、skills，开发时应进入该目录
2. **禁止自动提交**：AI 助手不得自动执行 `git commit` 或 `git push`，仅在用户明确要求时才执行
3. **发布前必须测试**：先发布到 dev 环境验证，再手动发布到 online
4. **数据准确性是基线**：数据门禁必须通过，否则停止业务归因

## 下一步行动

1. 补全诊断框架 v0.1 的"异常场景触发条件"和"指标口径"
2. 在 merchant-review 中搭建 MVP 原型
3. 邀请 1-2 名运营人员参与原型测试
4. 制定反馈收集机制

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at `.specify/specs/001-frontend-mvp/plan.md`
<!-- SPECKIT END -->
