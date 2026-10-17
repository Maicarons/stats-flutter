/// 会话内输出树（v1.5.0 M4.1）：按分析页保存每次运行的报告，最新在最前。
///
/// 只活在本次 App 运行里——切页面、返回再进不丢，重启即空
/// （跨启动持久化留 v1.6.0，见计划 M4.1 的「明确不做」）。
library;

import '../output/report_builder.dart';

class OutputStore {
  OutputStore._();

  static final Map<String, List<AnalysisReport>> _byAnalysis = {};

  /// 该分析的输出列表；**活列表、最新在最前**，改动请走 [add] / [remove] / [clear]。
  static List<AnalysisReport> of(String analysisId) =>
      _byAnalysis.putIfAbsent(analysisId, () => <AnalysisReport>[]);

  /// 追加一次运行结果。
  static void add(String analysisId, AnalysisReport report) =>
      of(analysisId).insert(0, report);

  /// 删掉某一张报告卡（按引用比较，卡片直接传自己手里那一份）。
  static bool remove(String analysisId, AnalysisReport report) =>
      of(analysisId).remove(report);

  /// 清空某个分析的输出。
  static void clear(String analysisId) => of(analysisId).clear();

  /// 是否有输出（AppBar 与「清空输出」按钮据此显示）。
  static bool has(String analysisId) => of(analysisId).isNotEmpty;

  /// 是否有任何分析的输出（切页面后仍可用于全局判断）。
  static bool get anyReport => _byAnalysis.values.any((l) => l.isNotEmpty);

  /// 测试用：清掉全部状态。
  static void reset() => _byAnalysis.clear();
}
