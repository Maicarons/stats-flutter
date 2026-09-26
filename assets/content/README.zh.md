# Stats-flutter

**工程化**统计分析套件，灵感来自 [GNU PSPP](https://www.gnu.org/software/pspp/)，Flutter 实现，内置学习与测试。

**GitHub**: https://github.com/Maicarons/stats-flutter

**Docs site:** https://maicarons.github.io/stats-flutter/


## 界面

```
开屏 → 全局导航
  ├─ 工程   ← 主页：多工程管理
  ├─ 学习   ← 8 课概念
  ├─ 测试   ← 20 题测验
  └─ 设置   ← 主题 / 语言 / 关于

打开工程 → 工作区
  ├─ 数据   ← 表格 / 变量 / CSV
  ├─ 分析   ← 统计过程
  └─ 变换   ← PSPP 变换命令
```

## 功能

- **工程**：新建/打开/重命名/复制/删除，JSON 持久化
- **数据**：双击编辑、值标签增删改、缺失值、CSV
- **变换**：COMPUTE · RECODE · COUNT · RANK · SORT · SELECT IF · AGGREGATE · FLIP
- **统计**：描述、t 检验、ANOVA、相关、回归、逻辑回归、卡方、非参数、信度、聚类、ROC、PCA
- **语法编辑器**：可执行 PSPP 命令子集
- **学习 + 测试** 全局可用
- **中英 i18n**、主题色、统一 Logo

## 统计内核

纯 Dart 包 `packages/statkit`（13 组测试）：

```dart
import 'package:statkit/statkit.dart';
final d = Descriptives.compute([1, 2, 3, 4, 5]);
```

## 快速开始

```bash
flutter pub get
flutter run -d windows
```

## 许可

MIT（独立实现；PSPP 为 GPL）
