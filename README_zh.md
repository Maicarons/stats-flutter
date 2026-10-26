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
- CSV 导入导出、**SPSS `.sav` 导出**（未压缩系统文件，PSPP / SPSS 可读）、加权、拆分、查找

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

语法层：PSPP 注释语义（`*` / `COMMENT`）、宏（`DEFINE`、位置与关键字参数、`!LET` / `!IF` / `!DO`、`!CONCAT` …）、`INCLUDE`（相对路径 + 循环保护）、逐命令错误定位、`.sps` 往返（剥 BOM、非法字节替换为 U+FFFD）

v1.6.0 新增：`SAVE OUTFILE='x.sav'` 写出 SPSS 系统文件；`SPLIT FILE BY …` / `OFF` 使所有分析按拆分变量组合逐组输出（每组一张报告卡片）

v1.7.0 新增：程序流 `DO IF / ELSE IF / ELSE`、`LOOP / BREAK`、`VECTOR`（条件逐案求值，支持 `< > <= >= = ~= AND OR NOT`）；分析中心新增 **Kendall W 一致性** 与 **KS 精确检验**（完全指定分布）页面

v1.8.0 新增：语法 `TEMPORARY.`（临时变换随下一个过程命令回滚）；分析中心新增**单因素 MANOVA**（Wilks / Pillai / Hotelling-Lawley / Roy，与 statsmodels 对拍一致）；**Stata `.dta`(117/118/119) 导入**

v1.9.0 新增：CTABLES-lite 升级——透视表支持**多汇总指标**（计数 / 百分比 / 均值等八选多）与**层变量**（每层一张表）；`.dta` 导入补齐**值标签**；新增 **ODS（LibreOffice）导入**

### 输出与导出
- 会话级输出树：每个分析每次运行一张卡片，最新在前、默认只展开最新一张
- 每张卡片：复制、分享、删除、导出；「导出全部」把该分析的所有卡片合成一份
- **PDF**（内置中文字体子集、页眉页脚、第 x / y 页）、**HTML**、**Markdown**
- 三种输出共用表样式：数值列右对齐、p 值列加星着色、变量与值标签

### 平台
- 国际化：English / 中文（flutter gen-l10n）
- 主题：浅色 / 深色 / 跟随系统 + 8 种主色
- 统一品牌图标（启动页 / 应用图标 / 文档）
- 中文显示：内置 Noto Sans SC 子集并改名 `StatsSansSC`（OFL-1.1，`tools/subset_cjk_font.py` 可复现）；拉丁文使用 Inter

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
