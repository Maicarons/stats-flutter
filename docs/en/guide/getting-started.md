# Getting Started

StatLab is a Flutter statistical suite inspired by [GNU PSPP](https://www.gnu.org/software/pspp/), with mobile-first UX, learning and testing modules.

## Requirements

| Component | Version |
|------|------|
| Flutter | ≥ 3.41 (stable) |
| Dart | ≥ 3.11 |
| Node.js | ≥ 20 (docs only) |

## Install & Run

```bash
git clone https://github.com/statlab/stats-flutter.git
cd stats-flutter

flutter pub get
flutter run -d windows   # or chrome / macos / linux

cd packages/statkit && dart test

cd docs && npm install && npm run docs:dev
```

## Mirrors (China)

- **Gradle distribution**: Tencent Cloud `https://mirrors.cloud.tencent.com/gradle/`
- **Maven**: Aliyun `maven.aliyun.com`

## Next

- [Data Editor](/en/guide/data-editor)
- [Analysis](/en/guide/analysis)
- [Learn & Quiz](/en/guide/learn-quiz)
