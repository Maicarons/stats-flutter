/// 多选集（MRSETS）数据层：定义 / 删除 / 显示 / 频数 / 交叉表。
///
/// 定义语义对齐 PSPP 2.1.2（`src/language/commands/mrsets.c`、`src/data/mrset.c`）：
/// - **MDGROUP（二分法组）**：组内每个成员变量各算一个类别，取值为 `VALUE=` 的
///   个案视为「选中」；类别标签默认取成员变量的变量标签（`CATEGORYLABELS=VARLABELS`），
///   也可改成取该变量对选中值的值标签（`COUNTEDVALUES`）；
/// - **MCGROUP（分类法组）**：成员变量是同一个分类问题的「宽格式」多个响应，
///   每个非缺失取值都算一个响应，类别按「取值」合并，标签取成员变量对该值的值标签
///   （没有值标签时取值本身的显示文本）；
/// - 组内变量必须不少于 2 个且类型一致；同名定义**覆盖**旧定义（PSPP
///   `dict_add_mrset` 行为），名字按大小写不敏感查找。
///
/// 频数与交叉表在 PSPP 里由 CTABLES 提供；本应用内置 `/FREQUENCIES` 与
/// `/CROSSTABS` 两个扩展子命令。口径按 SPSS 多响应表的惯例：分母分别是
/// **响应数**（responses，一个个案可以贡献多个响应）与**有响应的个案数**
/// （cases），两者都随附报告，因此百分比可以按需选择。
///
/// 计数未加权（与当前分析口径一致，权重口径的复核见 v1.4.0 M5）。
library;

import 'dataset.dart';

/// 多选集类型
enum MrSetType {
  /// MDGROUP：多个二分变量（每个变量一个「选中值」）
  md('MDGROUP', 'Dichotomies', '二分法组'),

  /// MCGROUP：同一个分类变量的多个响应（宽格式）
  mc('MCGROUP', 'Categories', '分类法组');

  const MrSetType(this.verb, this.en, this.zh);

  /// 语法关键字
  final String verb;
  final String en;
  final String zh;
}

/// 二分法组的类别标签来源
enum MrCategorySource {
  /// CATEGORYLABELS=VARLABELS（默认）：用成员变量的变量标签
  varLabels('VARLABELS', 'Variable labels', '变量标签'),

  /// CATEGORYLABELS=COUNTEDVALUES：用成员变量对「选中值」的值标签
  countedValues('COUNTEDVALUES', 'Counted value labels', '选中值的值标签');

  const MrCategorySource(this.verb, this.en, this.zh);

  final String verb;
  final String en;
  final String zh;
}

/// 多选集定义（MRSETS）
class MrSet {
  MrSet({
    required this.name,
    this.label = '',
    required this.type,
    required this.variables,
    this.counted,
    this.categoryLabels = MrCategorySource.varLabels,
  });

  /// 集合名（SPSS 惯例以 `$` 开头，本应用不强制）
  String name;

  /// 集合标签（可空）
  String label;

  MrSetType type;

  /// 成员变量名（≥ 2 个且类型一致）
  List<String> variables;

  /// MDGROUP 的「选中值」`VALUE=`；MCGROUP 恒为 null
  Object? counted;

  /// MDGROUP 的 `CATEGORYLABELS=`
  MrCategorySource categoryLabels;

  bool get isDichotomy => type == MrSetType.md;

  /// 成员变量的显示文本（PSPP 的 DISPLAY 表按行列出）
  String get membersText => variables.join('\n');

  MrSet copy() => MrSet(
        name: name,
        label: label,
        type: type,
        variables: List.of(variables),
        counted: counted,
        categoryLabels: categoryLabels,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'label': label,
        'type': type.verb,
        'variables': variables,
        if (counted != null) 'counted': counted,
        'categoryLabels': categoryLabels.verb,
      };

  factory MrSet.fromJson(Map<String, dynamic> j) => MrSet(
        name: (j['name'] ?? '') as String,
        label: (j['label'] ?? '') as String,
        type: MrSetType.values.firstWhere((e) => e.verb == j['type'],
            orElse: () => MrSetType.md),
        variables: [
          for (final v in (j['variables'] as List? ?? [])) '$v',
        ],
        counted: j['counted'] as Object?,
        categoryLabels: MrCategorySource.values.firstWhere(
            (e) => e.verb == j['categoryLabels'],
            orElse: () => MrCategorySource.varLabels),
      );
}

/// 归类用的键：数值按 double 规范化，字符串去尾空白后精确比较
/// （PSPP 的定宽字符串与去尾空白等价）。数值与字符串不会混键。
String mrValueKey(Object v) =>
    v is num ? 'n:${v.toDouble()}' : 's:${v.toString().trim()}';

/// 频数表 / 交叉表里的一行（一个类别）
class MrCategory {
  MrCategory({
    required this.label,
    this.source = '',
    this.value,
    this.count = 0,
  });

  /// 类别显示名（变量标签 / 值标签 / 取值文本）
  final String label;

  /// 类别所属的成员变量名（MDGROUP 用；MCGROUP 是首个贡献该取值的变量）
  String source;

  /// 类别对应的取值（MCGROUP 与 COUNTEDVALUES 模式用）
  final Object? value;

  /// 频数（响应数）
  int count;
}

/// 组内频数
class MrSetFrequency {
  MrSetFrequency({
    required this.set,
    required this.categories,
    required this.nResponses,
    required this.nCasesWithResponse,
    required this.nCases,
  });

  final MrSet set;
  final List<MrCategory> categories;

  /// 总响应数（一个个案可有多个响应）
  final int nResponses;

  /// 至少有一个响应的个案数
  final int nCasesWithResponse;

  /// 数据集全部个案数
  final int nCases;
}

/// 多选集与一个分类变量的交叉表
class MrSetCrosstab {
  MrSetCrosstab({
    required this.set,
    required this.byVar,
    required this.byLabel,
    required this.colLabels,
    required this.rows,
    required this.counts,
    required this.colResponses,
    required this.colCasesWithResponse,
    required this.colCases,
  });

  final MrSet set;

  /// 列变量名与标签
  final String byVar;
  final String byLabel;

  /// 各列的显示文本（列变量的取值标签或取值文本）
  final List<String> colLabels;

  /// 行（多选集的类别）
  final List<MrCategory> rows;

  /// counts[行][列]
  final List<List<int>> counts;

  /// 每列的响应数
  final List<int> colResponses;

  /// 每列「有响应」的个案数
  final List<int> colCasesWithResponse;

  /// 每列的个案数（列变量非缺失）
  final List<int> colCases;

  int get nRows => rows.length;
  int get nCols => colLabels.length;

  int rowTotal(int r) => counts[r].fold(0, (a, b) => a + b);

  /// 合计列（所有列相加）
  List<int> get totalCol {
    final out = List<int>.filled(nRows, 0);
    for (var r = 0; r < nRows; r++) {
      out[r] = rowTotal(r);
    }
    return out;
  }

  int get totalResponses => colResponses.fold(0, (a, b) => a + b);
  int get totalCasesWithResponse =>
      colCasesWithResponse.fold(0, (a, b) => a + b);
  int get totalCases => colCases.fold(0, (a, b) => a + b);
}

/// MRSETS 的定义 / 查询 / 频数 / 交叉表
class MRSets {
  /// 定义多选集；同名（大小写不敏感）时覆盖旧定义。
  static MrSet define(
    Dataset ds, {
    required String name,
    required MrSetType type,
    required List<String> variables,
    String label = '',
    Object? counted,
    MrCategorySource categoryLabels = MrCategorySource.varLabels,
  }) {
    final n = name.trim();
    if (n.isEmpty) throw ArgumentError('MRSETS requires a set name');
    if (!RegExp(r'^[A-Za-z_$@#][A-Za-z0-9_$@#.]*$').hasMatch(n)) {
      throw ArgumentError('invalid multiple response set name: $n');
    }
    // 去重后仍需 ≥ 2 个成员
    final names = <String>[];
    final idxs = <int>[];
    for (final v in variables) {
      final i = ds.indexOf(v);
      if (i < 0) throw ArgumentError('variable not found: $v');
      if (idxs.contains(i)) continue;
      idxs.add(i);
      names.add(ds.variables[i].name);
    }
    if (idxs.length < 2) {
      throw ArgumentError('at least two variables are required');
    }
    final t = ds.variables[idxs.first].type;
    for (final i in idxs) {
      if (ds.variables[i].type != t) {
        throw ArgumentError('all variables in a set must have the same type');
      }
    }
    final numeric = t == VarType.numeric;
    if (type == MrSetType.md) {
      if (counted == null) {
        throw ArgumentError('MDGROUP requires VALUE=');
      }
      if (numeric && counted is! num) {
        throw ArgumentError('VALUE must be numeric for numeric variables');
      }
      if (!numeric && (counted is! String || counted.isEmpty)) {
        throw ArgumentError('VALUE must be a string for string variables');
      }
    } else if (counted != null) {
      throw ArgumentError('MCGROUP does not accept VALUE=');
    }
    final set = MrSet(
      name: n,
      label: label,
      type: type,
      variables: names,
      counted: type == MrSetType.md ? counted : null,
      categoryLabels:
          type == MrSetType.md ? categoryLabels : MrCategorySource.varLabels,
    );
    final at = ds.mrSets
        .indexWhere((s) => s.name.toLowerCase() == n.toLowerCase());
    if (at >= 0) {
      ds.mrSets[at] = set;
    } else {
      ds.mrSets.add(set);
    }
    return set;
  }

  /// 按名查找（大小写不敏感）
  static MrSet? lookup(Dataset ds, String name) {
    final key = name.trim().toLowerCase();
    for (final s in ds.mrSets) {
      if (s.name.toLowerCase() == key) return s;
    }
    return null;
  }

  /// 删除多选集，返回实际删除的数量
  static int delete(Dataset ds, List<String> names) {
    var removed = 0;
    for (final n in names) {
      final key = n.trim().toLowerCase();
      final before = ds.mrSets.length;
      ds.mrSets.removeWhere((s) => s.name.toLowerCase() == key);
      if (ds.mrSets.length < before) removed++;
    }
    return removed;
  }

  /// 组内频数表
  static MrSetFrequency frequencies(Dataset ds, MrSet set) {
    final idxs = <int>[];
    for (final v in set.variables) {
      final i = ds.indexOf(v);
      if (i < 0) throw ArgumentError('variable not found: $v');
      idxs.add(i);
    }
    final cats = <MrCategory>[];
    var nResponses = 0;
    var nCasesWithResponse = 0;

    if (set.isDichotomy) {
      final countedKey = set.counted == null ? '' : mrValueKey(set.counted!);
      for (final i in idxs) {
        final v = ds.variables[i];
        final label = set.categoryLabels == MrCategorySource.countedValues
            ? v.displayValue(set.counted)
            : (v.label.isNotEmpty ? v.label : v.name);
        var c = 0;
        for (final row in ds.cases) {
          final raw = i < row.length ? row[i] : null;
          if (raw == null || v.isMissing(raw)) continue;
          if (mrValueKey(raw) == countedKey) c++;
        }
        cats.add(MrCategory(
            label: label, source: v.name, value: set.counted, count: c));
        nResponses += c;
      }
      for (final row in ds.cases) {
        var any = false;
        for (final i in idxs) {
          final raw = i < row.length ? row[i] : null;
          final v = ds.variables[i];
          if (raw == null || v.isMissing(raw)) continue;
          if (mrValueKey(raw) == countedKey) {
            any = true;
            break;
          }
        }
        if (any) nCasesWithResponse++;
      }
    } else {
      final byKey = <String, MrCategory>{};
      final order = <String>[];
      for (final row in ds.cases) {
        var any = false;
        for (final i in idxs) {
          final raw = i < row.length ? row[i] : null;
          final v = ds.variables[i];
          if (raw == null || v.isMissing(raw)) continue;
          final key = mrValueKey(raw);
          final c = byKey.putIfAbsent(key, () {
            order.add(key);
            return MrCategory(
                label: v.displayValue(raw), source: v.name, value: raw);
          });
          c.count++;
          nResponses++;
          any = true;
        }
        if (any) nCasesWithResponse++;
      }
      final sorted = [for (final k in order) byKey[k]!]..sort(_byValue);
      cats.addAll(sorted);
    }
    return MrSetFrequency(
      set: set,
      categories: cats,
      nResponses: nResponses,
      nCasesWithResponse: nCasesWithResponse,
      nCases: ds.nCases,
    );
  }

  /// 多选集 × 分类变量的交叉表
  static MrSetCrosstab crosstab(Dataset ds, MrSet set, String byVar) {
    final bi = ds.indexOf(byVar);
    if (bi < 0) throw ArgumentError('variable not found: $byVar');
    final by = ds.variables[bi];
    // 列：该变量非缺失的取值，按取值升序
    final cols = <String, int>{};
    final colValues = <Object>[];
    for (final row in ds.cases) {
      final raw = bi < row.length ? row[bi] : null;
      if (raw == null || by.isMissing(raw)) continue;
      final key = mrValueKey(raw);
      if (cols.containsKey(key)) continue;
      cols[key] = colValues.length;
      colValues.add(raw);
    }
    final order = List<int>.generate(colValues.length, (i) => i)
      ..sort((a, b) => _byValue(
            MrCategory(label: '', value: colValues[a]),
            MrCategory(label: '', value: colValues[b]),
          ));
    final colIndex = <String, int>{};
    final colLabels = <String>[];
    for (var k = 0; k < order.length; k++) {
      final v = colValues[order[k]];
      colIndex[mrValueKey(v)] = k;
      colLabels.add(by.displayValue(v));
    }

    final freq = frequencies(ds, set);
    final counts = [
      for (var r = 0; r < freq.categories.length; r++)
        List<int>.filled(colLabels.length, 0),
    ];
    final colResponses = List<int>.filled(colLabels.length, 0);
    final colCasesWithResponse = List<int>.filled(colLabels.length, 0);
    final colCases = List<int>.filled(colLabels.length, 0);
    final idxs = [for (final v in set.variables) ds.indexOf(v)];
    final countedKey = set.isDichotomy ? mrValueKey(set.counted!) : '';
    // 响应定位：MDGROUP 的行就是成员变量（按变量索引），MCGROUP 的行是取值
    final rowOfVar = <int, int>{};
    final rowOfValue = <String, int>{};
    for (var r = 0; r < freq.categories.length; r++) {
      final cat = freq.categories[r];
      if (set.isDichotomy) {
        rowOfVar[ds.indexOf(cat.source)] = r;
      } else {
        rowOfValue[mrValueKey(cat.value!)] = r;
      }
    }

    for (final row in ds.cases) {
      final raw = bi < row.length ? row[bi] : null;
      if (raw == null || by.isMissing(raw)) continue;
      final c = colIndex[mrValueKey(raw)];
      if (c == null) continue;
      colCases[c]++;
      var any = false;
      for (final i in idxs) {
        final cell = i < row.length ? row[i] : null;
        final v = ds.variables[i];
        if (cell == null || v.isMissing(cell)) continue;
        int? r;
        if (set.isDichotomy) {
          if (mrValueKey(cell) != countedKey) continue;
          r = rowOfVar[i];
        } else {
          r = rowOfValue[mrValueKey(cell)];
        }
        if (r == null) continue;
        counts[r][c]++;
        colResponses[c]++;
        any = true;
      }
      if (any) colCasesWithResponse[c]++;
    }
    return MrSetCrosstab(
      set: set,
      byVar: by.name,
      byLabel: by.label,
      colLabels: colLabels,
      rows: freq.categories,
      counts: counts,
      colResponses: colResponses,
      colCasesWithResponse: colCasesWithResponse,
      colCases: colCases,
    );
  }

  static int _byValue(MrCategory a, MrCategory b) {
    final x = a.value;
    final y = b.value;
    if (x is num && y is num) return x.compareTo(y);
    if (x != null && y != null) {
      final nx = num.tryParse(x.toString().trim());
      final ny = num.tryParse(y.toString().trim());
      if (nx != null && ny != null) return nx.compareTo(ny);
    }
    return '${x ?? ''}'.compareTo('${y ?? ''}');
  }
}

/// 显示宽度：CJK 等宽字符算 2 列，用于文本表格对齐。
int _wide(String s) {
  var w = 0;
  for (final r in s.runes) {
    w += _isWide(r) ? 2 : 1;
  }
  return w;
}

bool _isWide(int r) =>
    (r >= 0x1100 && r <= 0x115F) ||
    r == 0x2329 ||
    r == 0x232A ||
    (r >= 0x2E80 && r <= 0xA4CF && r != 0x303F) ||
    (r >= 0xAC00 && r <= 0xD7A3) ||
    (r >= 0xF900 && r <= 0xFAFF) ||
    (r >= 0xFE30 && r <= 0xFE6F) ||
    (r >= 0xFF00 && r <= 0xFF60) ||
    (r >= 0xFFE0 && r <= 0xFFE6);

String _pad(String s, int width, {bool right = false}) {
  final gap = width - _wide(s);
  if (gap <= 0) return s;
  final fill = ' ' * gap;
  return right ? '$fill$s' : '$s$fill';
}

String _pct(int part, int whole) =>
    whole <= 0 ? '-' : '${(100.0 * part / whole).toStringAsFixed(1)}%';

/// MRSETS 的纯文本输出（语法引擎与界面共用；表头保持中性英文，
/// 与其它数据层命令的输出风格一致）。
class MRSetsText {
  /// 集合定义表（PSPP `MRSETS /DISPLAY` 的属性：标签 / 类型 / 选中值 / 成员变量）
  static String display(List<MrSet> sets) {
    if (sets.isEmpty) return 'MRSETS /DISPLAY (no multiple response sets)';
    final buf = StringBuffer('Multiple Response Sets (${sets.length})\n');
    const wName = 14, wLabel = 22, wType = 12, wCounted = 12;
    buf.writeln('${_pad('Name', wName)}${_pad('Label', wLabel)}'
        '${_pad('Type', wType)}${_pad('Counted Value', wCounted)}'
        'Member Variables');
    for (final s in sets) {
      buf.writeln('${_pad(s.name, wName)}${_pad(s.label, wLabel)}'
          '${_pad(s.type.en, wType)}'
          '${_pad(s.counted == null ? '' : '${s.counted}', wCounted)}'
          '${s.variables.join(' ')}');
    }
    return buf.toString().trimRight();
  }

  /// 组内频数表
  static String frequencies(MrSetFrequency f) {
    final buf = StringBuffer('MRSETS /FREQUENCIES NAME=${f.set.name}'
        ' (${f.set.type.en}, ${f.set.variables.length} members)\n');
    if (f.set.label.isNotEmpty) {
      buf.writeln('Label: ${f.set.label}');
    }
    const wCat = 30, wCount = 8, wPct = 10;
    buf.writeln('${_pad('Category', wCat)}${_pad('Count', wCount, right: true)}'
        '${_pad('% of Responses', wPct, right: true)}'
        '${_pad('% of Cases', wPct, right: true)}');
    for (final c in f.categories) {
      buf.writeln('${_pad(c.label, wCat)}'
          '${_pad('${c.count}', wCount, right: true)}'
          '${_pad(_pct(c.count, f.nResponses), wPct, right: true)}'
          '${_pad(_pct(c.count, f.nCasesWithResponse), wPct, right: true)}');
    }
    buf.writeln('${_pad('Total responses', wCat)}'
        '${_pad('${f.nResponses}', wCount, right: true)}');
    buf.writeln('Cases with responses: ${f.nCasesWithResponse} / ${f.nCases}');
    return buf.toString().trimRight();
  }

  /// 交叉表（列变量各列 + 合计）
  static String crosstab(MrSetCrosstab c) {
    final head = c.byLabel.isEmpty ? c.byVar : c.byLabel;
    final buf = StringBuffer('MRSETS /CROSSTABS NAME=${c.set.name} '
        'BY ${c.byVar} ($head)\n');
    const wCat = 30, wCell = 12;
    buf.write(_pad('Category', wCat));
    for (final l in c.colLabels) {
      buf.write(_pad(l, wCell, right: true));
    }
    buf.writeln(_pad('Total', wCell, right: true));
    for (var r = 0; r < c.nRows; r++) {
      buf.write(_pad(c.rows[r].label, wCat));
      for (var k = 0; k < c.nCols; k++) {
        buf.write(_pad('${c.counts[r][k]}', wCell, right: true));
      }
      buf.writeln(_pad('${c.rowTotal(r)}', wCell, right: true));
    }
    void line(String label, List<int> values, int total) {
      buf.write(_pad(label, wCat));
      for (final v in values) {
        buf.write(_pad('$v', wCell, right: true));
      }
      buf.writeln(_pad('$total', wCell, right: true));
    }

    line('Responses', c.colResponses, c.totalResponses);
    line('Cases with responses', c.colCasesWithResponse,
        c.totalCasesWithResponse);
    line('Cases', c.colCases, c.totalCases);
    // 响应百分比（列内）
    buf.write(_pad('% of responses', wCat));
    for (final v in c.colResponses) {
      buf.write(_pad(_pct(v, c.totalResponses), wCell, right: true));
    }
    buf.writeln(_pad('100.0%', wCell, right: true));
    return buf.toString().trimRight();
  }
}
