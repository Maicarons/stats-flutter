/// 应用元信息。
///
/// 版本号与 `pubspec.yaml` 的 `version:` 手工保持一致（避免引入 package_info 平台通道）。
library;

abstract final class AppInfo {
  static const String name = 'Stats-flutter';
  static const String version = '1.5.0+7';
  static const String buildLabel = '1.5.0';
}
