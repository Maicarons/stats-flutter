/// 用户缺失值口径（v1.4.0 M5 统一，全部过程遵循同一套规则）。
///
/// 一个变量在某个个案上的取值算「缺失」，当且仅当 `Variable.isMissing` 为真：
/// 空值、空字符串，或命中用户声明的离散缺失值 / 缺失范围。
///
/// 规则：
/// - **A 单变量**：只用一个变量自身非缺失的个案（`numeric` / `raw`）；
/// - **B 多变量（完全案例）**：成对检验、成对回归、因子分析、信度、逐步回归、
///   协方差分析、多项 logistic 的每一列都取自**同一批个案** —— 其中任何变量缺失
///   即整行剔除（`alignedNumeric`），保证列与列仍按个案对齐；相关矩阵按
///   PSPP / SPSS 默认的**成对删除**（`pairs`）逐对选取个案；
/// - **C 加权**：加权统计同时要求权重变量也非缺失（`weighted`）；权重为 0 的
///   个案保留在个案数里，但不计入有效权重；
/// - **D 分组**：分组变量的取值缺失时，该个案不进入任何一组（`_splitByGroup` 与
///   有序分组的 `_orderedLevels` 都遵守）；
/// - **E 分类过程**：频数、交叉表、条形图把用户缺失值记为「缺失」
///   （`Dataset.rawColumn` 返回 null，`Frequencies.nMissing` 计数），不作为类别。
///
/// 与 PSPP 的差别：PSPP 在 `MISSING=INCLUDE` 时把用户缺失值当普通取值；
/// 本应用分析过程固定按上述口径排除，不做逐过程开关。
library;

import '../models/dataset.dart';

class MissingAware {
  /// 有效数值向量（规则 A：应用变量的用户缺失值规则）
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

  /// 原始向量（缺失用 null 表示，规则 A / 规则 E）
  static List<Object?> raw(Dataset ds, String name,
      {bool applyUserMissing = true}) {
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

  /// 完全案例（listwise，规则 B）：[names] 每个变量在该个案都有效时返回行号。
  static List<int> completeRows(Dataset ds, List<String> names) {
    final idx = [for (final n in names) ds.indexOf(n)];
    if (idx.any((i) => i < 0)) return [];
    final out = <int>[];
    for (var r = 0; r < ds.nCases; r++) {
      final row = ds.cases[r];
      var ok = true;
      for (final i in idx) {
        final raw = i < row.length ? row[i] : null;
        if (ds.variables[i].isMissing(raw)) {
          ok = false;
          break;
        }
      }
      if (ok) out.add(r);
    }
    return out;
  }

  /// 完全案例的数值列（规则 B）：返回与 [names] 一一对应的多列，
  /// **列之间按个案对齐**；某个变量在该个案非数值（或缺失）时整行剔除。
  static List<List<double>> alignedNumeric(Dataset ds, List<String> names) {
    final idx = [for (final n in names) ds.indexOf(n)];
    final cols = [for (final _ in names) <double>[]];
    if (idx.any((i) => i < 0)) return cols;
    for (var r = 0; r < ds.nCases; r++) {
      final row = ds.cases[r];
      final vals = <double>[];
      var ok = true;
      for (final i in idx) {
        final raw = i < row.length ? row[i] : null;
        if (ds.variables[i].isMissing(raw)) {
          ok = false;
          break;
        }
        final v = raw is num ? raw.toDouble() : double.tryParse('$raw');
        if (v == null) {
          ok = false;
          break;
        }
        vals.add(v);
      }
      if (!ok) continue;
      for (var c = 0; c < cols.length; c++) {
        cols[c].add(vals[c]);
      }
    }
    return cols;
  }

  /// 成对完整个案的两列（规则 B）：相关矩阵、成对检验、散点用。
  static (List<double>, List<double>) pairs(Dataset ds, String x, String y) {
    final cols = alignedNumeric(ds, [x, y]);
    return (cols[0], cols[1]);
  }

  /// 加权统计的（值, 权重）两列（规则 C）：两者都有效才保留该个案。
  static (List<double>, List<double>) weighted(
      Dataset ds, String value, String weight) {
    return pairs(ds, value, weight);
  }

  /// 按分组变量拆组（规则 D + 规则 A）：分组变量或分析变量缺失的个案不进任何组；
  /// 组标签用分组变量的显示值（值标签优先）。
  static Map<String, List<double>> groups(
      Dataset ds, String valueVar, String groupVar) {
    final vi = ds.indexOf(valueVar);
    final gi = ds.indexOf(groupVar);
    if (vi < 0 || gi < 0) return {};
    final vv = ds.variables[vi];
    final gv = ds.variables[gi];
    final out = <String, List<double>>{};
    for (final row in ds.cases) {
      final gRaw = gi < row.length ? row[gi] : null;
      final vRaw = vi < row.length ? row[vi] : null;
      if (gv.isMissing(gRaw) || vv.isMissing(vRaw)) continue;
      final v = vRaw is num ? vRaw.toDouble() : double.tryParse('$vRaw');
      if (v == null) continue;
      out.putIfAbsent(gv.displayValue(gRaw), () => []).add(v);
    }
    return out;
  }
}
