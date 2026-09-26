# 快速开始

**Stats-flutter** 是对标 [GNU PSPP](https://www.gnu.org/software/pspp/) 的 Flutter 统计分析应用，采用**工程化**管理统计表。

- GitHub: https://github.com/Maicarons/stats-flutter
- 最新版本: [v1.0.0](https://github.com/Maicarons/stats-flutter/releases/tag/v1.0.0)

## 环境要求

| 组件 | 版本 |
|------|------|
| Flutter | ≥ 3.41（stable） |
| Dart | ≥ 3.11 |
| Node.js | ≥ 20（仅文档站） |

## 安装与运行

```bash
git clone https://github.com/Maicarons/stats-flutter.git
cd stats-flutter

flutter pub get
flutter run -d windows   # 或 chrome / macos / linux
```

## 界面导览

```
开屏（统一 Logo + 项目名）
  └─ 全局底部导航
       ├─ 工程   ← 主页：工程列表
       ├─ 学习   ← 概念短课
       ├─ 测试   ← 随机测验
       └─ 设置   ← 主题 / 语言 / 关于

点击打开工程 → 工程工作区
       ├─ 数据   ← 表格 / 变量 / CSV
       ├─ 分析   ← 统计过程
       └─ 变换   ← 数据变换
```

**学习、测试、设置是全局的**，不必打开工程。  
**数据、分析、变换属于工程**，每个工程一份独立统计表。

## 测试

```bash
cd packages/statkit && dart test
cd ../.. && flutter test
```

## 文档站

```bash
cd docs && npm install && npm run docs:dev
```

## Android 国内加速

- Gradle 发行版：腾讯云 `https://mirrors.cloud.tencent.com/gradle/`
- Maven：阿里云 `maven.aliyun.com`

配置见 `android/gradle/wrapper/gradle-wrapper.properties` 与 `android/settings.gradle.kts`。

## 下一步

- [工程管理](/guide/projects) — 多工程工作流
- [数据编辑器](/guide/data-editor) — 表格与变量
- [统计分析](/guide/analysis) — 跑通一次分析
- [数据变换](/guide/transforms) — PSPP 变换命令
