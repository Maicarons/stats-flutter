/// CTABLES 简化版：透视汇总表（v0.4）
library;

import 'descriptives.dart';

enum CellSummary {
  count,
  percent,
  validPercent,
  mean,
  sum,
  sd,
  min,
  max,
  median,
}

class CTableCell {
  final double? value;
  final String display;
  const CTableCell({required this.value, required this.display});
}

class CTablesResult {
  final List<String> rowLabels;
  final List<String> colLabels;
  final List<List<CTableCell>> cells;
  final List<CTableCell> rowTotals;
  final List<CTableCell> colTotals;
  final CTableCell grandTotal;
  final CellSummary summary;
  final String rowVar;
  final String colVar;
  final String valueVar;

  const CTablesResult({
    required this.rowLabels,
    required this.colLabels,
    required this.cells,
    required this.rowTotals,
    required this.colTotals,
    required this.grandTotal,
    required this.summary,
    required this.rowVar,
    required this.colVar,
    required this.valueVar,
  });
}

/// 二维透视汇总
/// rows / cols: 每行的行键与列键；values: 可选数值（计数模式可全 null）
CTablesResult crosstabSummary({
  required List<Object?> rowKeys,
  required List<Object?> colKeys,
  List<double?>? values,
  required String rowVar,
  required String colVar,
  String valueVar = '',
  CellSummary summary = CellSummary.count,
  Map<Object?, String>? rowLabels,
  Map<Object?, String>? colLabels,
}) {
  final n = rowKeys.length;
  final rMap = <Object?, List<double?>>{};
  final cMap = <Object?, List<double?>>{};
  final cellsMap = <(Object?, Object?), List<double?>>{};

  for (var i = 0; i < n; i++) {
    final r = rowKeys[i];
    final c = colKeys[i];
    if (r == null || c == null) continue;
    final v = values != null && i < values.length ? values[i] : 1.0;
    rMap.putIfAbsent(r, () => []).add(v);
    cMap.putIfAbsent(c, () => []).add(v);
    cellsMap.putIfAbsent((r, c), () => []).add(v);
  }

  final rKeys = rMap.keys.toList()
    ..sort((a, b) => a.toString().compareTo(b.toString()));
  final cKeys = cMap.keys.toList()
    ..sort((a, b) => a.toString().compareTo(b.toString()));

  String labR(Object? k) =>
      rowLabels != null && rowLabels.containsKey(k) ? rowLabels[k]! : k.toString();
  String labC(Object? k) =>
      colLabels != null && colLabels.containsKey(k) ? colLabels[k]! : k.toString();

  CTableCell summarize(List<double?> list) {
    final nums = list.whereType<double>().toList();
    switch (summary) {
      case CellSummary.count:
        return CTableCell(
            value: nums.length.toDouble(),
            display: '${nums.length}');
      case CellSummary.percent:
        return CTableCell(
            value: nums.length.toDouble(), display: '${nums.length}');
      case CellSummary.validPercent:
        return CTableCell(
            value: nums.length.toDouble(), display: '${nums.length}');
      case CellSummary.mean:
        if (nums.isEmpty) return const CTableCell(value: null, display: '');
        final d = Descriptives.compute(nums);
        return CTableCell(
            value: d.mean, display: d.mean.toStringAsFixed(3));
      case CellSummary.sum:
        final s = nums.fold<double>(0, (a, b) => a + b);
        return CTableCell(value: s, display: s.toStringAsFixed(3));
      case CellSummary.sd:
        if (nums.isEmpty) return const CTableCell(value: null, display: '');
        final d = Descriptives.compute(nums);
        return CTableCell(value: d.sd, display: d.sd.toStringAsFixed(3));
      case CellSummary.min:
        if (nums.isEmpty) return const CTableCell(value: null, display: '');
        final m = nums.reduce((a, b) => a < b ? a : b);
        return CTableCell(value: m, display: m.toStringAsFixed(3));
      case CellSummary.max:
        if (nums.isEmpty) return const CTableCell(value: null, display: '');
        final m = nums.reduce((a, b) => a > b ? a : b);
        return CTableCell(value: m, display: m.toStringAsFixed(3));
      case CellSummary.median:
        if (nums.isEmpty) return const CTableCell(value: null, display: '');
        final d = Descriptives.compute(nums);
        return CTableCell(value: d.median, display: d.median.toStringAsFixed(3));
    }
  }

  // percentages relative to grand for percent mode
  final grandList = <double?>[
    for (var i = 0; i < n; i++)
      if (rowKeys[i] != null && colKeys[i] != null)
        values != null && i < values.length ? values[i] : 1.0
  ];
  final grandN = grandList.whereType<double>().length;

  CTableCell cellOf(Object? r, Object? c) {
    final list = cellsMap[(r, c)] ?? const <double?>[];
    if (summary == CellSummary.percent && grandN > 0) {
      final cnt = list.whereType<double>().length;
      final pct = cnt / grandN * 100;
      return CTableCell(value: pct, display: '${pct.toStringAsFixed(1)}%');
    }
    return summarize(list);
  }

  final rowLabelsOut = [for (final k in rKeys) labR(k)];
  final colLabelsOut = [for (final k in cKeys) labC(k)];
  final cells = [
    for (final r in rKeys) [for (final c in cKeys) cellOf(r, c)]
  ];
  final rowTotals = [for (final r in rKeys) summarize(rMap[r]!)];
  final colTotals = [for (final c in cKeys) summarize(cMap[c]!)];
  final grand = summarize(grandList);

  return CTablesResult(
    rowLabels: rowLabelsOut,
    colLabels: colLabelsOut,
    cells: cells,
    rowTotals: rowTotals,
    colTotals: colTotals,
    grandTotal: grand,
    summary: summary,
    rowVar: rowVar,
    colVar: colVar,
    valueVar: valueVar,
  );
}
