# Stats-flutter

移动优先的统计分析套件，功能对标 [GNU PSPP](https://www.gnu.org/software/pspp/)，用 Flutter 重写，内置**学习**与**测试**模块。

**GitHub**: https://github.com/Maicarons/stats-flutter  
**Release**: [v1.0.0](https://github.com/Maicarons/stats-flutter/releases/tag/v1.0.0)

## 界面结构

```
开屏（统一 Logo）
  └─ 全局底部导航
       ├─ 工程   ← 多工程统计表管理（主页入口）
       ├─ 学习   ← 8 课概念 + 公式
       ├─ 测试   ← 20 题随机测验
       └─ 设置   ← 主题 / 语言 / 关于

打开某工程 → 工程工作区
       ├─ 数据   ← 表格编辑 / 变量视图 / CSV
       ├─ 分析   ← 全部统计过程
       └─ 变换   ← COMPUTE / RECODE / SORT …
```

## 功能一览

### 工程管理
- 多工程列表：新建（空白/示例）、打开、重命名、复制、删除
- JSON 持久化：`文档/stats_flutter_projects/`
- 工作区内一键保存

### 数据编辑
- 双击/长按编辑表格，Enter / Tab / Esc 键盘导航
- 变量视图：类型、测量、标签、小数位
- **值标签增删改**、缺失值设置
- 表格**默认不显示值标签**（可切换）
- CSV 导入 / 导出、加权、拆分、查找

### 数据变换（PSPP 风格）
COMPUTE · RECODE · COUNT · RANK · SORT CASES · SELECT IF · AGGREGATE · FLIP

### 统计分析
| 类别 | 过程 |
|------|------|
| 描述 | 描述统计、频率、直方图、条形图、散点图、正态性 |
| 比较均值 | 单样本/独立/配对 t 检验、单因素 ANOVA、MEANS、Tukey |
| 关系 | Pearson/Spearman、交叉表卡方 |
| 预测 | 线性回归、逻辑回归、ROC、K-Means、PCA 因子 |
| 稳健 | Mann-Whitney、Wilcoxon、Kruskal-Wallis |
| 测量 | Cronbach α 信度 |

### 语法编辑器
可执行子集：`DESCRIPTIVES` `FREQUENCIES` `T-TEST` `CORRELATIONS` `COMPUTE` `RECODE` `RANK` `SORT` `SELECT IF` `LIST` `HELP`

### 其他
- **i18n**：中文 / English 即时切换（`flutter gen-l10n`）
- **主题**：浅色 / 深色 / 跟随系统 + 8 种主题色
- **统一 Logo**：开屏 / 桌面图标 / Web / 文档站同一设计
- **Noto Sans SC** 中文字体（`google_fonts`）

## 统计内核 `packages/statkit`

纯 Dart，零 Flutter 依赖，13 组测试。

```dart
import 'package:statkit/statkit.dart';

final d = Descriptives.compute([1, 2, 3, 4, 5]);
final t = TTest.oneSample(data, mu0: 70);
final r = Regression.simple(x, y);
```

## 快速开始

```bash
git clone https://github.com/Maicarons/stats-flutter.git
cd stats-flutter
flutter pub get
flutter run -d windows   # 或 chrome / macos / linux

# 测试
cd packages/statkit && dart test
cd ../.. && flutter test

# 文档站
cd docs && npm install && npm run docs:dev
```

## 构建镜像（国内）

- **Gradle 发行版**：`https://mirrors.cloud.tencent.com/gradle/`
- **Maven**：阿里云 `maven.aliyun.com`（google / public / gradle-plugin）

## 项目结构

```
stats-flutter/
├── packages/statkit/          # 可复用统计内核
├── lib/
│   ├── core/                  # 模型 / 变换 / 语法 / 主题
│   ├── l10n/                  # 中英 ARB
│   ├── features/
│   │   ├── projects/          # 工程列表与工作区
│   │   ├── data_editor/       # 可编辑表格
│   │   ├── analysis/          # 分析入口与运行器
│   │   ├── transform/         # 数据变换
│   │   ├── syntax/            # 语法编辑器
│   │   ├── learn/ quiz/       # 学习与测试
│   │   └── settings/          # 设置与关于
│   └── shared/                # 状态 / BrandLogo
├── docs/                      # VitePress 中英双语文档
├── assets/                    # 图标 / 示例数据 / README
└── android/                   # 腾讯 Gradle + 阿里 Maven
```

## 文档

完整文档见 `docs/`（VitePress，中英双语）：

```bash
cd docs && npm install && npm run docs:dev
```

## 许可

- 本仓库代码：MIT
- PSPP 研究参考：GNU PSPP 为 GPL；本项目为独立实现
