# Quickstart: 商家复盘 Dashboard 前端 MVP 验证指南

**Date**: 2026-10-18  
**Feature**: [spec.md](./spec.md)

## Overview

本文档提供前端 MVP 的可运行验证场景，证明核心功能端到端可用。

---

## Prerequisites

- Node.js 18+ 已安装
- npm 或 pnpm 已安装
- 妙搭脚手架已初始化（`merchant-review/` 目录存在）
- 浏览器（Chrome/Firefox/Safari 最新版）

---

## Setup

### 1. 进入项目目录

```bash
cd merchant-review
```

### 2. 安装依赖（如果未安装）

```bash
npm install
```

### 3. 启动开发服务器

```bash
npm run dev
```

预期输出：
```
VITE v5.x.x  ready in xxx ms

➜  Local:   http://localhost:5173/
➜  Network: use --host to expose
```

### 4. 打开浏览器

访问 `http://localhost:5173/`，应看到概览页。

---

## Validation Scenarios

### Scenario 1: 概览页基础展示

**Steps**:
1. 打开 `http://localhost:5173/`
2. 查看页面布局

**Expected**:
- ✅ 左侧导航栏显示（可收起/展开）
- ✅ 顶部筛选器显示（日期窗口、日期、四级类目）
- ✅ 数据明细表格显示第一页（20 条数据）
- ✅ 表格分页器显示"第 1 页，每页 20 条"

---

### Scenario 2: 筛选器联动与 URL 同步

**Steps**:
1. 在概览页选择日期窗口"近 15 天"
2. 选择四级类目"1001-红富士"
3. 点击"确认"按钮
4. 查看 URL

**Expected**:
- ✅ URL 更新为 `?dateWindow=15&categoryLevel4Id=1001`
- ✅ 表格数据过滤为红富士品类
- ✅ 刷新页面后筛选器保持选中状态

---

### Scenario 3: 下钻跳转

**Steps**:
1. 在概览页表格中点击品类名称"红富士"
2. 查看跳转后的页面
3. 查看 URL

**Expected**:
- ✅ 跳转到品类分析页 `/category/analysis?categoryLevel4Id=1001`
- ✅ 筛选器自动显示"1001-红富士"
- ✅ 面包屑显示"品类分析 / 红富士"

---

### Scenario 4: 表格排序

**Steps**:
1. 在概览页表格中点击"销售额"列头
2. 再次点击"销售额"列头
3. 第三次点击"销售额"列头

**Expected**:
- ✅ 第一次点击：数据按销售额升序排列，列头显示 ↑
- ✅ 第二次点击：数据按销售额降序排列，列头显示 ↓
- ✅ 第三次点击：恢复默认排序，列头箭头消失

---

### Scenario 5: 表格全屏

**Steps**:
1. 在概览页表格右上角点击全屏按钮（⛶）
2. 查看弹窗
3. 点击放大按钮
4. 点击缩小按钮
5. 按 ESC 键

**Expected**:
- ✅ 弹窗居中显示，展示完整表格
- ✅ 放大按钮使弹窗增大（最多 100%）
- ✅ 放大到最大时放大按钮失效
- ✅ 初始状态时缩小按钮失效
- ✅ 按 ESC 关闭弹窗

---

### Scenario 6: 导航栏收起/展开

**Steps**:
1. 点击顶部控制栏的收起按钮（☰）
2. 查看页面布局
3. 点击面包屑区域

**Expected**:
- ✅ 导航栏收起（宽度变为 0）
- ✅ 内容区占满宽度
- ✅ 点击面包屑后导航栏重新展开

---

### Scenario 7: TOC 导航

**Steps**:
1. 进入品类分析页（有 PageSection）
2. 查看右侧 TOC
3. 点击"趋势分析"

**Expected**:
- ✅ 右侧 TOC 显示"指标概览"、"趋势分析"、"数据明细"
- ✅ 点击后平滑滚动到对应 section

---

### Scenario 8: 分页功能

**Steps**:
1. 在概览页表格中点击"下一页"
2. 查看分页器
3. 点击"上一页"

**Expected**:
- ✅ 表格切换到第 2 页
- ✅ 分页器更新为"第 2 页，每页 20 条"
- ✅ 点击"上一页"回到第 1 页

---

## Testing Commands

### 运行单元测试

```bash
npm run test
```

### 运行类型检查

```bash
npm run type-check
```

### 运行代码检查

```bash
npm run lint
```

### 构建生产版本

```bash
npm run build
```

---

## Troubleshooting

### 问题：页面空白

**Solution**:
- 检查浏览器控制台是否有错误
- 确认 `npm run dev` 成功启动
- 清除浏览器缓存后刷新

### 问题：筛选器不生效

**Solution**:
- 检查 URL 参数是否正确
- 确认 `useFilters` hook 正确同步状态
- 查看控制台是否有 React 错误

### 问题：表格排序不工作

**Solution**:
- 确认列定义中 `sortable: true`
- 检查 `useTableSort` hook 是否正确实现
- 查看数据是否为正确的数值类型

---

## Success Criteria Validation

完成以上 8 个场景后，验证以下成功指标：

- ✅ **SC-001**: 首屏加载 < 10s（手动计时）
- ✅ **SC-002**: 下钻跳转不超过 3 次点击（Scenario 3）
- ✅ **SC-003**: 筛选器切换后数据刷新 < 3s（Scenario 2）
- ✅ **SC-004**: 刷新页面后筛选条件保留（Scenario 2）
- ✅ **SC-007**: 分页、全屏、TOC 等功能 100% 可用（Scenarios 5-8）

---

## Next Steps

验证通过后，进入 `/speckit-tasks` 生成任务列表，开始实现。
