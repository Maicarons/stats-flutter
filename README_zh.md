# Stats-flutter

**工程化统计分析套件**，用 Flutter 构建，覆盖全平台，内置学习与测试模块。

[![CI](https://github.com/Maicarons/stats-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/Maicarons/stats-flutter/actions/workflows/ci.yml)
[![Docs](https://github.com/Maicarons/stats-flutter/actions/workflows/deploy-docs.yml/badge.svg)](https://maicarons.github.io/stats-flutter/)
[![Release](https://img.shields.io/github/v/release/Maicarons/stats-flutter)](https://github.com/Maicarons/stats-flutter/releases)

**📖 在线文档:** https://maicarons.github.io/stats-flutter/  
**English README:** [README.md](./README.md)

## 界面结构

```
开屏 → 全局底部导航
  ├─ 工程   ← 主页：多工程统计表管理
  ├─ 学习   ← 8 课概念 + 公式
  ├─ 测试   ← 20 题随机测验
  └─ 设置   ← 主题 / 语言 / 关于

打开工程 → 工程工作区
  ├─ 数据   ← 表格编辑 / 变量视图 / CSV
  ├─ 分析   ← 全部统计过程
  └─ 变换   ← COMPUTE / RECODE / SORT …
```

**学习、测试、设置是全局的**；**数据、分析、变换属于工程**。

## 功能

### 工程管理
- 新建（空白/示例）、打开、重命名、复制、删除
- JSON 持久化：`文档/stats_flutter_projects/`

### 数据编辑
- 双击/长按编辑，Enter / Tab / Esc 导航
- **值标签增删改**、缺失值
- 表格**默认不显示值标签**
- CSV 导入导出、加权、拆分、查找

### 数据变换
COMPUTE · RECODE · COUNT · RANK · SORT CASES · SELECT IF · AGGREGATE · FLIP

### 统计过程
| 类别 | 过程 |
|------|------|
| 描述 | 描述统计、频率、直方图、条形图、散点图、正态性 |
| 比较均值 | t 检验、ANOVA、MEANS、Tukey |
| 关系 | Pearson/Spearman、交叉表卡方 |
| 预测 | 线性回归、逻辑回归、ROC、K-Means、PCA |
| 稳健 | Mann-Whitney、Wilcoxon、Kruskal-Wallis |
| 测量 | Cronbach α |

### 语法编辑器
可执行子集：`DESCRIPTIVES` `T-TEST` `COMPUTE` `RECODE` `SORT` `SELECT IF` `LIST` `HELP`

## 统计内核 `packages/statkit`

纯 Dart，零 Flutter 依赖，13 组测试。

```dart
import 'package:statkit/statkit.dart';
final d = Descriptives.compute([1, 2, 3, 4, 5]);
```

## 快速开始

```bash
git clone https://github.com/Maicarons/stats-flutter.git
cd stats-flutter
flutter pub get
flutter run -d windows
```

### 测试

```bash
cd packages/statkit && dart test
cd ../.. && flutter test
```

### 文档站

```bash
cd docs && npm install && npm run docs:dev
```

线上地址：https://maicarons.github.io/stats-flutter/

## 构建镜像（国内）

- Gradle 发行版：`https://mirrors.cloud.tencent.com/gradle/`
- Maven：阿里云 `maven.aliyun.com`

## 许可

- 本仓库代码：AGPL-3.0
