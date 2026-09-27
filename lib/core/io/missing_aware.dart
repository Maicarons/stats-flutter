/// 用户缺失值：分析取值时统一排除（v1.1）
library;

import '../models/dataset.dart';

class MissingAware {
  /// 有效数值向量（应用变量的用户缺失值规则）
  static List<double> numeric(
    Dataset ds,
    String name, {
    bool applyUserMissing = true,
  }) {
    final i = ds.indexOf(name);
    if (i < 0) return [];
    final v = ds.variables[i];
    final out = <double>[];
    for (final row in ds.cases) {
      final raw = i < row.length ? row[i] : null;
      if (applyUserMissing && v.isMissing(raw)) continue;
      if (raw is num) out.add(raw.toDouble());
      if (raw is String) {
        final d = double.tryParse(raw);
        if (d != null) out.add(d);
      }
    }
    return out;
  }

  /// 原始向量（缺失用 null 表示）
  static List<Object?> raw(Dataset ds, String name, {bool applyUserMissing = true}) {
    final i = ds.indexOf(name);
    if (i < 0) return [];
    final v = ds.variables[i];
    return [
      for (final row in ds.cases)
        () {
          final raw = i < row.length ? row[i] : null;
          if (applyUserMissing && v.isMissing(raw)) return null;
          return raw;
        }(),
    ];
  }

  /// 成对有效索引（两列都非缺失）
  static List<int> pairwiseComplete(Dataset ds, String a, String b,
      {bool applyUserMissing = true}) {
    final ia = ds.indexOf(a);
    final ib = ds.indexOf(b);
    if (ia < 0 || ib < 0) return [];
    final va = ds.variables[ia];
    final vb = ds.variables[ib];
    final out = <int>[];
    for (var r = 0; r < ds.nCases; r++) {
      final ra = r < ds.cases[r].length ? ds.cases[r][ia] : null;
      final rb = r < ds.cases[r].length ? ds.cases[r][ib] : null;
      if (applyUserMissing) {
        if (va.isMissing(ra) || vb.isMissing(rb)) continue;
      }
      out.add(r);
    }
    return out;
  }
}
