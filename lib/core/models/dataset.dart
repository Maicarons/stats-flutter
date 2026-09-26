/// 核心数据模型：变量字典 + 数据集（对应 PSPP 的 dict + case）
library;

/// 测量级别
enum MeasureLevel {
  scale('Scale', '标度'),
  ordinal('Ordinal', '有序'),
  nominal('Nominal', '名义');

  const MeasureLevel(this.en, this.zh);
  final String en;
  final String zh;
}

/// 变量类型
enum VarType {
  numeric('Numeric', '数值'),
  string('String', '字符串'),
  date('Date', '日期');

  const VarType(this.en, this.zh);
  final String en;
  final String zh;
}

/// 对齐方式
enum VarAlign {
  left,
  right,
  center;
}

/// 变量定义（对应 PSPP Variable）
class Variable {
  Variable({
    required this.name,
    this.label = '',
    this.type = VarType.numeric,
    this.measure = MeasureLevel.scale,
    this.decimals = 2,
    this.width = 8,
    this.align = VarAlign.right,
    Map<num, String>? valueLabels,
    List<num>? missingValues,
    this.missingRangeLow,
    this.missingRangeHigh,
  })  : valueLabels = valueLabels ?? {},
        missingValues = missingValues ?? [];

  String name;
  String label;
  VarType type;
  MeasureLevel measure;
  int decimals;
  int width;
  VarAlign align;

  /// 值标签：数值 → 显示文本
  Map<num, String> valueLabels;

  /// 离散缺失值
  List<num> missingValues;

  /// 连续缺失范围（可选）
  num? missingRangeLow;
  num? missingRangeHigh;

  bool get isNumeric => type == VarType.numeric;

  /// 是否为缺失值
  bool isMissing(Object? v) {
    if (v == null) return true;
    if (v is String) return v.trim().isEmpty;
    if (v is num) {
      if (missingValues.any((m) => (m - v).abs() < 1e-12)) return true;
      if (missingRangeLow != null &&
          missingRangeHigh != null &&
          v >= missingRangeLow! &&
          v <= missingRangeHigh!) {
        return true;
      }
    }
    return false;
  }

  String displayValue(Object? v) {
    if (v == null) return '';
    if (v is num && valueLabels.containsKey(v)) return valueLabels[v]!;
    if (v is num) {
      if (type == VarType.numeric) {
        return v == v.roundToDouble() && decimals == 0
            ? v.toInt().toString()
            : v.toStringAsFixed(decimals);
      }
    }
    return v.toString();
  }

  Variable copy() => Variable(
        name: name,
        label: label,
        type: type,
        measure: measure,
        decimals: decimals,
        width: width,
        align: align,
        valueLabels: Map.of(valueLabels),
        missingValues: List.of(missingValues),
        missingRangeLow: missingRangeLow,
        missingRangeHigh: missingRangeHigh,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'label': label,
        'type': type.name,
        'measure': measure.name,
        'decimals': decimals,
        'width': width,
        'align': align.name,
        'valueLabels': valueLabels.map((k, v) => MapEntry(k.toString(), v)),
        'missingValues': missingValues,
      };

  factory Variable.fromJson(Map<String, dynamic> j) => Variable(
        name: j['name'] as String,
        label: (j['label'] ?? '') as String,
        type: VarType.values.firstWhere((e) => e.name == j['type'],
            orElse: () => VarType.numeric),
        measure: MeasureLevel.values.firstWhere((e) => e.name == j['measure'],
            orElse: () => MeasureLevel.scale),
        decimals: (j['decimals'] ?? 2) as int,
        width: (j['width'] ?? 8) as int,
        valueLabels: ((j['valueLabels'] as Map?) ?? {}).map(
            (k, v) => MapEntry(num.parse(k.toString()), v as String)),
        missingValues: ((j['missingValues'] as List?) ?? [])
            .map((e) => e as num)
            .toList(),
      );
}

/// 数据集：变量字典 + 个案矩阵
class Dataset {
  Dataset({
    String? name,
    List<Variable>? variables,
    List<List<Object?>>? cases,
  })  : name = name ?? 'Untitled',
        variables = variables ?? [],
        cases = cases ?? [];

  String name;
  List<Variable> variables;
  List<List<Object?>> cases;

  /// 可选：文件路径 / 备注
  String? path;

  /// WEIGHT CASES
  String? weightVariable;

  /// SPLIT FILE
  String? splitVariable;

  int get nVars => variables.length;
  int get nCases => cases.length;

  /// 按列索引取某一变量的全部值
  List<Object?> column(int index) =>
      cases.map((r) => index < r.length ? r[index] : null).toList();

  /// 按变量名取列
  List<Object?> columnByName(String name) {
    final i = indexOf(name);
    return i < 0 ? [] : column(i);
  }

  int indexOf(String name) =>
      variables.indexWhere((v) => v.name.toLowerCase() == name.toLowerCase());

  /// 提取数值向量（跳过缺失）
  List<double> numericColumn(String name, {bool skipMissing = true}) {
    final i = indexOf(name);
    if (i < 0) return [];
    final v = variables[i];
    final out = <double>[];
    for (final row in cases) {
      final raw = i < row.length ? row[i] : null;
      if (skipMissing && v.isMissing(raw)) continue;
      if (raw is num) {
          out.add(raw.toDouble());
        }
      else if (raw is String) {
        final d = double.tryParse(raw);
        if (d != null) {
          out.add(d);
        }
      }
    }
    return out;
  }

  /// 提取原始向量（保留缺失标记为 null）
  List<Object?> rawColumn(String name) {
    final i = indexOf(name);
    return i < 0 ? [] : column(i);
  }

  void addVariable(Variable v) {
    variables.add(v);
    for (final row in cases) {
      row.add(null);
    }
  }

  void insertVariable(int index, Variable v) {
    variables.insert(index, v);
    for (final row in cases) {
      row.insert(index, null);
    }
  }

  void removeVariable(int index) {
    if (index < 0 || index >= variables.length) return;
    variables.removeAt(index);
    for (final row in cases) {
      if (index < row.length) row.removeAt(index);
    }
  }

  void addCase([List<Object?>? row]) {
    cases.add(row ?? List.filled(variables.length, null));
  }

  void insertCase(int index, [List<Object?>? row]) {
    cases.insert(index, row ?? List.filled(variables.length, null));
  }

  void removeCase(int index) {
    if (index >= 0 && index < cases.length) cases.removeAt(index);
  }

  /// 自动推断类型并创建数据集（用于 CSV 导入）
  factory Dataset.fromRows({
    required List<String> headers,
    required List<List<String>> rows,
    String name = 'Imported',
  }) {
    final vars = <Variable>[];
    for (var c = 0; c < headers.length; c++) {
      var allNumeric = true;
      var maxDec = 0;
      for (final r in rows) {
        final cell = c < r.length ? r[c].trim() : '';
        if (cell.isEmpty) continue;
        final d = double.tryParse(cell);
        if (d == null) {
          allNumeric = false;
          break;
        }
        final dot = cell.indexOf('.');
        if (dot >= 0) {
          final dec = cell.length - dot - 1;
          if (dec > maxDec) {
            maxDec = dec;
          }
        }
      }
      vars.add(Variable(
        name: headers[c].isEmpty ? 'V${c + 1}' : headers[c],
        type: allNumeric ? VarType.numeric : VarType.string,
        measure: allNumeric ? MeasureLevel.scale : MeasureLevel.nominal,
        decimals: maxDec > 6 ? 6 : maxDec,
      ));
    }
    final cases = rows
        .map((r) => List<Object?>.generate(headers.length, (c) {
              final cell = c < r.length ? r[c].trim() : '';
              if (cell.isEmpty) return null;
              final v = vars[c];
              if (v.type == VarType.numeric) return double.tryParse(cell);
              return cell;
            }))
        .toList();
    return Dataset(name: name, variables: vars, cases: cases);
  }

  /// 生成示例数据（成绩分析教学用）
  factory Dataset.demoScores() {
    final vars = [
      Variable(name: 'id', label: '学号', type: VarType.numeric, decimals: 0, measure: MeasureLevel.nominal),
      Variable(name: 'gender', label: '性别', type: VarType.numeric, decimals: 0, measure: MeasureLevel.nominal)
        ..valueLabels.addAll({1: '男', 2: '女'}),
      Variable(name: 'method', label: '教学法', type: VarType.numeric, decimals: 0, measure: MeasureLevel.nominal)
        ..valueLabels.addAll({1: '讲授', 2: '探究', 3: '混合'}),
      Variable(name: 'pre', label: '前测', type: VarType.numeric, measure: MeasureLevel.scale),
      Variable(name: 'post', label: '后测', type: VarType.numeric, measure: MeasureLevel.scale),
      Variable(name: 'hours', label: '周学习时长', type: VarType.numeric, measure: MeasureLevel.scale),
    ];
    // 确定性伪随机，保证测试可重复
    var seed = 42;
    double rnd() {
      seed = (1103515245 * seed + 12345) % 0x7fffffff;
      return seed / 0x7fffffff;
    }

    final cases = <List<Object?>>[];
    for (var i = 0; i < 30; i++) {
      final method = (i % 3) + 1;
      final gender = (i % 2) + 1;
      final pre = 55 + rnd() * 30 + (method == 3 ? 5 : 0);
      final lift = method == 1 ? 6.0 : method == 2 ? 11.0 : 14.0;
      final post = pre + lift + rnd() * 10 - 3;
      final hours = 2 + rnd() * 8 + (method == 3 ? 2 : 0);
      cases.add([
        1001 + i,
        gender.toDouble(),
        method.toDouble(),
        double.parse(pre.toStringAsFixed(1)),
        double.parse(post.toStringAsFixed(1)),
        double.parse(hours.toStringAsFixed(1)),
      ]);
    }
    return Dataset(name: 'demo_scores', variables: vars, cases: cases);
  }

  Dataset copy() => Dataset(
        name: name,
        variables: variables.map((v) => v.copy()).toList(),
        cases: cases.map((r) => List<Object?>.of(r)).toList(),
      )..path = path;
}
