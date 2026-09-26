# Stats-flutter

移动优先的统计分析套件，功能对标 [GNU PSPP](https://www.gnu.org/software/pspp/)，用 Flutter 重写并加入**学习**与**测试**模块。

## 特性

- **数据编辑**：数据视图 / 变量视图，双击编辑，值标签可增删改，缺失值设置
- **数据变换**：COMPUTE、RECODE、COUNT、RANK、SORT、SELECT IF、AGGREGATE、FLIP
- **描述与探索**：描述统计、频率、直方图、条形图、散点图、正态性检验
- **比较均值**：单样本 / 独立 / 配对 t 检验，单因素 ANOVA，分层均值，Tukey 事后比较
- **关系与预测**：Pearson/Spearman 相关、线性回归、交叉表卡方、K-Means、ROC
- **非参数与信度**：Mann-Whitney、Wilcoxon、Kruskal-Wallis、Cronbach α
- **学习模块**：8 课概念短课 + 核心公式
- **测试模块**：20 题随机抽题、即时判分、错题解析
- **CSV 导入/导出**、结果分享
- **主题**：浅色 / 深色 / 跟随系统 + 8 种主题色
- **i18n**：中文 / English 即时切换

## 统计内核

计算由独立 Dart 包 [`packages/statkit`](packages/statkit) 完成，零 Flutter 依赖，可单独复用。

```dart
import 'package:statkit/statkit.dart';

final d = Descriptives.compute([1, 2, 3, 4, 5]);
final t = TTest.oneSample(data, mu0: 70);
```

## 快速开始

```bash
flutter pub get
flutter run -d windows   # 或 chrome / macos / linux
```

## 构建镜像

- Gradle 发行版：`https://mirrors.cloud.tencent.com/gradle/`
- Maven：阿里云 `maven.aliyun.com`

## 许可

- 本仓库代码：MIT
- PSPP 研究参考：GNU PSPP 为 GPL；本项目为独立实现
