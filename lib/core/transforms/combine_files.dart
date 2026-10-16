/// COMBINE FILES：`ADD FILES`（按变量名纵向拼接）与 `MATCH FILES`（按键横向匹配）。
///
/// 语义对齐 PSPP 2.1.2（`src/language/commands/combine-files.c` 与
/// `doc/combining.texi`）：
/// - 变量按**名字**匹配（大小写不敏感），文件各自的 `/RENAME=(旧=新)` 先应用；
///   某个文件缺少的变量在输出里是系统缺失（数值 null / 字符串 null）；
/// - 变量定义取**第一个给出该变量的文件**，后续文件只补缺口
///   （PSPP `merge_dictionaries`）：字符串宽度取最大者，值标签 / 缺失值 /
///   变量标签在结果里还空着时由后续文件补上 —— 因此合并后变量标签与值标签不丢；
///   同名变量类型不一致（数值 / 字符串）直接报错；
/// - `/IN=名字` 为每个文件生成 0/1 指示变量，标记该个案来自哪个文件；
/// - **ADD FILES**：`/BY` 缺省时按文件顺序依次追加全部个案；给出 `/BY` 时，
///   各文件须已按 BY 变量升序（PSPP 要求 `SORT`，本应用直接报错提示先排序），
///   输出的 BY 组按升序排列，等值组按文件顺序依次输出；
/// - **MATCH FILES**：第一个文件是主文件（`FILE`），其余是查表文件（`TABLE`）。
///   给出 `/BY` 时按 BY 取值匹配（查表文件一个个案可对多个主文件个案；同键重复时
///   取第一个，与 PSPP `scan_table` 一致）；不给 `/BY` 时按**个案序号**逐个对齐，
///   文件较短时后续个案不再贡献（PSPP 文档口径）。只在查表文件里出现的 BY 取值
///   会以主文件变量缺失的形式追加到末尾，并在提示里报告条数；
/// - 与 PSPP 的差异（已在文档与界面提示里注明）：按键匹配用哈希连接，
///   不要求输入已排序；不支持 `/SORT`、`/FIRST`、`/LAST`、`/MAP`。
library;

import '../models/dataset.dart';

/// 一个输入文件及其选项
class CombineInput {
  CombineInput(this.dataset, {Map<String, String>? rename, this.inVar})
      : rename = rename ?? const {};

  final Dataset dataset;

  /// 该文件的 `/RENAME=(旧=新)`，按名字大小写不敏感
  final Map<String, String> rename;

  /// 该文件的 `/IN=` 指示变量名（null 表示不生成）
  final String? inVar;
}

/// 合并结果：新数据集 + 一行提示
class CombineResult {
  CombineResult(this.dataset, this.message);

  final Dataset dataset;
  final String message;
}

/// 归一化后的输入文件：`名字 → 列号`（已应用 RENAME）
class _File {
  _File(this.ds, Map<String, String> rename, this.inVar) : _rename = rename {
    for (var i = 0; i < ds.nVars; i++) {
      final name = _renamed(ds.variables[i].name);
      names.add(name);
      colByLower[name.toLowerCase()] = i;
    }
  }

  final Dataset ds;
  final Map<String, String> _rename;
  final String? inVar;
  final List<String> names = [];
  final Map<String, int> colByLower = {};

  String _renamed(String name) {
    for (final e in _rename.entries) {
      if (e.key.toLowerCase() == name.toLowerCase()) return e.value;
    }
    return name;
  }

  int? col(String name) => colByLower[name.toLowerCase()];

  Object? cell(int col, int row) {
    final r = ds.cases[row];
    return col < r.length ? r[col] : null;
  }
}

/// 合并的公共部分：变量并集、定义合并、行投影
class _Merge {
  _Merge(this.files,
      {List<String>? keep, List<String>? drop, List<String>? by}) {
    byVars = by == null || by.isEmpty ? null : List.of(by);
    if (byVars != null) {
      for (final f in files) {
        for (final b in byVars!) {
          if (f.col(b) == null) {
            throw ArgumentError('BY variable $b is not present in all files');
          }
        }
      }
    }
    // 1) 变量并集：按文件顺序，每个名字只出现一次
    for (final f in files) {
      for (final n in f.names) {
        final key = n.toLowerCase();
        if (nameByLower.containsKey(key)) continue;
        nameByLower[key] = n;
        names.add(n);
      }
    }
    // 2) /IN= 指示变量
    for (final f in files) {
      final iv = f.inVar;
      if (iv == null) continue;
      if (nameByLower.containsKey(iv.toLowerCase())) {
        throw ArgumentError(
            'IN variable $iv duplicates an existing variable name');
      }
      nameByLower[iv.toLowerCase()] = iv;
      names.add(iv);
    }
    // 3) /KEEP= 与 /DROP=
    if (keep != null && keep.isNotEmpty) {
      final wanted = {for (final k in keep) k.toLowerCase()};
      for (final k in keep) {
        if (!nameByLower.containsKey(k.toLowerCase())) {
          throw ArgumentError('KEEP variable $k does not exist');
        }
      }
      names.removeWhere((n) => !wanted.contains(n.toLowerCase()));
    }
    if (drop != null && drop.isNotEmpty) {
      final gone = {for (final d in drop) d.toLowerCase()};
      for (final d in drop) {
        if (!nameByLower.containsKey(d.toLowerCase())) {
          throw ArgumentError('DROP variable $d does not exist');
        }
      }
      names.removeWhere((n) => gone.contains(n.toLowerCase()));
    }
    // 4) 变量定义：第一个给出该变量的文件为准，后续只补缺口
    variables = [for (final n in names) _mergeVar(n)];
    // 5) 列计划：(IN 变量所属文件索引, 变量名)，索引 -1 表示普通变量
    plan = [for (final n in names) (_inOwner(n), n)];
  }

  final List<_File> files;
  List<String>? byVars;
  final List<String> names = [];
  final Map<String, String> nameByLower = {};
  late final List<Variable> variables;
  late final List<(int, String)> plan;

  int _inOwner(String name) {
    for (var j = 0; j < files.length; j++) {
      if (files[j].inVar?.toLowerCase() == name.toLowerCase()) return j;
    }
    return -1;
  }

  bool isInColumn(int c) => plan[c].$1 >= 0;

  /// PSPP `merge_dictionaries`：第一个定义该变量的文件提供类型与格式，
  /// 后续文件在结果还空着时补值标签 / 缺失值 / 变量标签，字符串宽度取最大。
  Variable _mergeVar(String name) {
    Variable? out;
    for (final f in files) {
      final ci = f.col(name);
      if (ci == null) continue;
      final v = f.ds.variables[ci];
      if (out == null) {
        out = v.copy();
        continue;
      }
      if (out.type != v.type) {
        throw ArgumentError(
            'variable $name has different types in different files');
      }
      if (v.width > out.width) out.width = v.width;
      if (out.valueLabels.isEmpty && v.valueLabels.isNotEmpty) {
        out.valueLabels = Map.of(v.valueLabels);
      }
      if (out.missingValues.isEmpty &&
          out.missingRangeLow == null &&
          (v.missingValues.isNotEmpty || v.missingRangeLow != null)) {
        out.missingValues = List.of(v.missingValues);
        out.missingRangeLow = v.missingRangeLow;
        out.missingRangeHigh = v.missingRangeHigh;
      }
      if (out.label.isEmpty && v.label.isNotEmpty) out.label = v.label;
    }
    // IN 变量不在任何文件里，按 0/1 名义变量生成
    return out ??
        Variable(
          name: name,
          label: 'IN variable',
          decimals: 0,
          measure: MeasureLevel.nominal,
        );
  }

  /// 第 [k] 个文件第 [row] 行投影到输出列（该文件贡献的个案整行取自它）
  List<Object?> rowOf(int k, int row) {
    final f = files[k];
    final src = f.ds.cases[row];
    final out = List<Object?>.filled(plan.length, null);
    for (var c = 0; c < plan.length; c++) {
      final (owner, name) = plan[c];
      if (owner >= 0) {
        out[c] = owner == k ? 1 : 0;
        continue;
      }
      final ci = f.col(name);
      out[c] = ci == null || ci >= src.length ? null : src[ci];
    }
    return out;
  }

  /// 输出行骨架：IN 变量预置 0，其它为系统缺失
  List<Object?> blankRow() => [
        for (final (owner, _) in plan) owner >= 0 ? 0 : null,
      ];

  /// 把 [src] 里非缺失的值填进 [out]（PSPP `apply_nonmissing_case`）
  void blend(List<Object?> out, List<Object?> src) {
    for (var c = 0; c < out.length; c++) {
      if (plan[c].$1 >= 0) continue;
      if (src[c] != null) out[c] = src[c];
    }
  }

  /// 标记第 [k] 个文件贡献了当前个案
  void markIn(List<Object?> out, int k) {
    for (var c = 0; c < out.length; c++) {
      if (plan[c].$1 == k) out[c] = 1;
    }
  }

  /// BY 键的分量（每个分量已按类型规范化）
  List<String> keyParts(int k, int row) {
    final f = files[k];
    return [
      for (final b in byVars!)
        _partOf(f.cell(f.col(b)!, row)),
    ];
  }

  String keyString(int k, int row) => keyParts(k, row).join('\u0001');

  static String _partOf(Object? v) {
    if (v == null) return 'k:';
    return v is num ? 'n:${v.toDouble()}' : 's:${v.toString().trim()}';
  }

  /// 两个 BY 键的大小比较（数值按大小、字符串按字典序）
  static int compareKey(List<String> a, List<String> b) {
    for (var i = 0; i < a.length; i++) {
      final c = _comparePart(a[i], b[i]);
      if (c != 0) return c;
    }
    return 0;
  }

  static int _comparePart(String a, String b) {
    final an = a.startsWith('n:') ? double.tryParse(a.substring(2)) : null;
    final bn = b.startsWith('n:') ? double.tryParse(b.substring(2)) : null;
    if (an != null && bn != null) return an.compareTo(bn);
    return a.compareTo(b);
  }

  /// 结果数据集；权重 / 拆分变量若仍在结果里则保留（取第一个文件的设置）
  Dataset build(List<List<Object?>> rows, String name) {
    final ds = Dataset(name: name);
    for (final v in variables) {
      ds.addVariable(v);
    }
    for (final r in rows) {
      ds.addCase(r);
    }
    final first = files.first;
    final w = first.ds.weightVariable;
    if (w != null && ds.indexOf(w) >= 0) ds.weightVariable = w;
    final s = first.ds.splitVariable;
    if (s != null && ds.indexOf(s) >= 0) ds.splitVariable = s;
    return ds;
  }
}

/// COMBINE FILES 的数据层实现
class CombineFiles {
  /// `ADD FILES`：把多个数据集纵向拼接
  static CombineResult addFiles(
    List<CombineInput> inputs, {
    List<String>? by,
    List<String>? keep,
    List<String>? drop,
  }) {
    if (inputs.isEmpty) {
      throw ArgumentError('ADD FILES requires at least one file');
    }
    final files = [
      for (final i in inputs) _File(i.dataset, i.rename, i.inVar),
    ];
    final m = _Merge(files, keep: keep, drop: drop, by: by);
    final rows = <List<Object?>>[];
    if (m.byVars == null) {
      for (var k = 0; k < files.length; k++) {
        for (var r = 0; r < files[k].ds.nCases; r++) {
          rows.add(m.rowOf(k, r));
        }
      }
    } else {
      // 每个文件切成 BY 组，要求组按键升序（PSPP 无 SORT 时的要求）
      final groups = <List<List<int>>>[];
      for (var k = 0; k < files.length; k++) {
        final gs = <List<int>>[];
        for (var r = 0; r < files[k].ds.nCases; r++) {
          if (gs.isEmpty ||
              _Merge.compareKey(
                      m.keyParts(k, r), m.keyParts(k, gs.last.first)) !=
                  0) {
            gs.add(<int>[]);
          }
          gs.last.add(r);
        }
        for (var g = 1; g < gs.length; g++) {
          if (_Merge.compareKey(
                  m.keyParts(k, gs[g].first), m.keyParts(k, gs[g - 1].first)) <
              0) {
            throw ArgumentError(
                'ADD FILES /BY requires each file to be sorted by the BY variables');
          }
        }
        groups.add(gs);
      }
      // 按 BY 键升序把各文件的等值组依次输出
      final ptr = List<int>.filled(files.length, 0);
      while (true) {
        List<String>? minKey;
        for (var k = 0; k < files.length; k++) {
          if (ptr[k] >= groups[k].length) continue;
          final key = m.keyParts(k, groups[k][ptr[k]].first);
          if (minKey == null || _Merge.compareKey(key, minKey) < 0) {
            minKey = key;
          }
        }
        if (minKey == null) break;
        for (var k = 0; k < files.length; k++) {
          if (ptr[k] >= groups[k].length) continue;
          if (_Merge.compareKey(m.keyParts(k, groups[k][ptr[k]].first), minKey) !=
              0) {
            continue;
          }
          for (final r in groups[k][ptr[k]]) {
            rows.add(m.rowOf(k, r));
          }
          ptr[k]++;
        }
      }
    }
    final ds = m.build(rows, files.first.ds.name);
    return CombineResult(
      ds,
      'ADD FILES: ${files.length} file(s), '
      '${ds.nCases} cases x ${ds.nVars} variables',
    );
  }

  /// `MATCH FILES`：主文件 + 查表文件的横向匹配
  static CombineResult matchFiles(
    CombineInput main,
    List<CombineInput> tables, {
    List<String>? by,
    List<String>? keep,
    List<String>? drop,
  }) {
    final files = [
      _File(main.dataset, main.rename, main.inVar),
      for (final t in tables) _File(t.dataset, t.rename, t.inVar),
    ];
    final m = _Merge(files, keep: keep, drop: drop, by: by);
    final rows = <List<Object?>>[];
    var duplicates = 0;
    var onlyInTables = 0;
    if (m.byVars == null) {
      // 按个案序号对齐：第 i 个输出个案取各文件的第 i 个个案
      var n = 0;
      for (final f in files) {
        if (f.ds.nCases > n) n = f.ds.nCases;
      }
      for (var r = 0; r < n; r++) {
        final out = m.blankRow();
        for (var k = 0; k < files.length; k++) {
          if (r >= files[k].ds.nCases) continue;
          m.blend(out, m.rowOf(k, r));
          m.markIn(out, k);
        }
        rows.add(out);
      }
    } else {
      // 查表文件：BY 键 → 首个行号
      final maps = <Map<String, int>>[];
      for (var k = 1; k < files.length; k++) {
        final map = <String, int>{};
        for (var r = 0; r < files[k].ds.nCases; r++) {
          final key = m.keyString(k, r);
          if (map.containsKey(key)) {
            duplicates++;
            continue;
          }
          map[key] = r;
        }
        maps.add(map);
      }
      final matched = [for (var k = 1; k < files.length; k++) <String>{}];
      for (var r = 0; r < files[0].ds.nCases; r++) {
        final out = m.blankRow();
        m.blend(out, m.rowOf(0, r));
        m.markIn(out, 0);
        final key = m.keyString(0, r);
        for (var k = 1; k < files.length; k++) {
          final tr = maps[k - 1][key];
          if (tr == null) continue;
          matched[k - 1].add(key);
          m.blend(out, m.rowOf(k, tr));
          m.markIn(out, k);
        }
        rows.add(out);
      }
      // 只在查表文件里出现的键：追加，主文件变量为缺失
      for (var k = 1; k < files.length; k++) {
        for (final e in maps[k - 1].entries) {
          if (matched[k - 1].contains(e.key)) continue;
          final out = m.blankRow();
          m.blend(out, m.rowOf(k, e.value));
          m.markIn(out, k);
          rows.add(out);
          onlyInTables++;
        }
      }
    }
    final ds = m.build(rows, files.first.ds.name);
    final notes = <String>[];
    if (duplicates > 0) {
      notes.add('$duplicates duplicated key(s) in table file(s), first used');
    }
    if (onlyInTables > 0) {
      notes.add('$onlyInTables key(s) only in table file(s) appended missing');
    }
    return CombineResult(
      ds,
      'MATCH FILES: ${files.length} file(s), '
      '${ds.nCases} cases x ${ds.nVars} variables'
      '${notes.isEmpty ? '' : '; ${notes.join('; ')}'}',
    );
  }
}
