# 快速开始

StatLab 是一款对标 [GNU PSPP](https://www.gnu.org/software/pspp/) 的 Flutter 统计分析应用，覆盖桌面级统计过程，并针对移动端做了交互优化。

## 环境要求

| 组件 | 版本 |
|------|------|
| Flutter | ≥ 3.41（stable） |
| Dart | ≥ 3.11 |
| Node.js | ≥ 20（仅文档站需要） |

## 安装与运行

```bash
git clone https://github.com/statlab/stats-flutter.git
cd stats-flutter

# 应用
flutter pub get
flutter run -d windows   # 或 chrome / macos / linux

# 统计内核测试
cd packages/statkit && dart test

# 文档站
cd docs && npm install && npm run docs:dev
```

## Android 国内加速

本仓库已配置：

- **Gradle 发行版**：腾讯云镜像 `https://mirrors.cloud.tencent.com/gradle/`
- **Maven 依赖**：阿里云 `maven.aliyun.com`（google / public / gradle-plugin）

配置见 `android/gradle/wrapper/gradle-wrapper.properties` 与 `android/settings.gradle.kts`。

## 项目结构

```
stats-flutter/
├── packages/statkit/       # 可复用纯 Dart 统计内核
├── lib/
│   ├── core/               # 模型 / 主题
│   ├── l10n/               # 中英 ARB 与生成代码
│   ├── features/
│   │   ├── data_editor/    # 可编辑数据表格
│   │   ├── analysis/       # 分析入口与运行器
│   │   ├── output/         # 报告渲染
│   │   ├── learn/          # 学习模块
│   │   ├── quiz/           # 测试模块
│   │   └── settings/       # 设置
│   └── shared/             # 全局状态
├── docs/                   # VitePress 文档
├── assets/
└── android/                # 腾讯 Gradle + 阿里 Maven
```

## 下一步

- [数据编辑器](/guide/data-editor) — 双击编辑与 CSV 导入导出
- [统计分析](/guide/analysis) — 如何跑一次完整分析
- [学习与测试](/guide/learn-quiz) — 从概念到练习
