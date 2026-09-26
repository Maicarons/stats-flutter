# Stats-flutter

移动优先的统计分析套件，功能对标 [GNU PSPP](https://www.gnu.org/software/pspp/)，用 Flutter 重写并加入**学习**与**测试**模块。

## 特性

- **数据编辑**：数据视图 / 变量视图，值标签、测量级别、缺失值
- **描述与探索**：描述统计、频率、直方图、条形图、散点图
- **比较均值**：单样本 / 独立 / 配对 t 检验（含 Levene），单因素 ANOVA（含效应量）
- **关系与预测**：Pearson/Spearman 相关、线性回归、交叉表卡方、K-Means
- **非参数与信度**：Mann-Whitney、Wilcoxon、Kruskal-Wallis、Cronbach α
- **学习模块**：概念短课 + 核心公式
- **测试模块**：随机抽题、即时判分、错题解析
- **CSV 导入/导出**、结果文本分享

统计计算由独立 Dart 包 [`packages/statkit`](packages/statkit) 完成，零 Flutter 依赖，可单独复用。

## 项目结构

```
stats-flutter/
├── packages/statkit/          # 可复用统计内核 pub 包
├── lib/
│   ├── core/                  # 模型 / 主题
│   ├── features/
│   │   ├── data_editor/       # 数据编辑器
│   │   ├── analysis/          # 分析入口与运行器
│   │   ├── output/            # 报告渲染
│   │   ├── learn/             # 学习模块
│   │   └── quiz/              # 测试模块
│   └── shared/                # 全局状态
├── assets/
├── docs/PSPP_RESEARCH.md      # PSPP 研究纪要
├── android/                   # Gradle 已配置腾讯发行版镜像
└── test/
```

## 快速开始

```bash
flutter pub get
flutter run
```

### Android 构建镜像

- Gradle 发行版：`https://mirrors.cloud.tencent.com/gradle/`
- Maven 依赖：阿里云 `maven.aliyun.com`（google / public / gradle-plugin）

## 测试

```bash
cd packages/statkit && dart test
flutter test
```

## 许可

- 本仓库代码：MIT
- PSPP 研究参考：GNU PSPP 为 GPL；本项目为独立实现，不复制其源码
