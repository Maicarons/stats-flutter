/// 大数据基准测试（10 万行）
///
/// 运行：dart run tool/benchmark.dart
library;

import 'dart:convert';

import 'package:statkit/statkit.dart';

import '../lib/core/models/dataset.dart';


void step(String name, String Function() fn) {
  // Stopwatch 在部分定制 SDK 环境下异常，改用墙钟计时
  final t0 = DateTime.now();
  final r = fn();
  final ms = DateTime.now().difference(t0).inMilliseconds;
  print('$name: $ms ms  $r');
}

List<List<String>> _makeRows(int n) => List.generate(n, (i) {
      return [
        '${100000 + i}',
        '${i % 4}',
        '${i % 2}',
        (50 + (i % 50) * 0.7).toStringAsFixed(1),
        (55 + (i % 60) * 0.9).toStringAsFixed(1),
        (1 + (i % 10) * 0.5).toStringAsFixed(1),
        ((i % 100) * 1.1).toStringAsFixed(2),
        (18 + i % 30).toString(),
      ];
    });

void main() {
  const n = 100000;
  const headers = [
    'id', 'group', 'gender', 'pre', 'post', 'hours', 'score', 'age',
  ];

  final rows = _makeRows(n);

  late Dataset ds;
  step('Dataset.fromRows ($n × 8, type inference)', () {
    ds = Dataset.fromRows(headers: headers, rows: rows, name: 'bench');
    return '(${ds.nCases} × ${ds.nVars})';
  });

  step('dataset.copy() (undo snapshot)', () {
    final c = ds.copy();
    return '(${c.nCases} rows copied)';
  });

  step('toJson + encode (autosave persist)', () {
    final json = const JsonEncoder().convert(_miniProjectJson(ds));
    return '${(json.length / 1024 / 1024).toStringAsFixed(1)} MB';
  });

  step('Descriptives.compute (post, 100k)', () {
    final d = Descriptives.compute(ds.numericColumn('post'));
    return 'mean=${d.mean.toStringAsFixed(3)} sd=${d.sd.toStringAsFixed(3)}';
  });

  step('TTest.independentSamples (post by group)', () {
    final g = <int, List<double>>{};
    final gi = ds.indexOf('group');
    final vi = ds.indexOf('post');
    for (final row in ds.cases) {
      g
          .putIfAbsent((row[gi] as double).toInt(), () => [])
          .add(row[vi] as double);
    }
    final keys = g.keys.toList();
    final r = TTest.independentSamples(g[keys[0]]!, g[keys[1]]!);
    return 't=${r.t.toStringAsFixed(3)} p=${r.pTwoTail.toStringAsFixed(4)}';
  });

  step('Correlation.pearson (pre × post, 100k)', () {
    final r = Correlation.pearson(
        ds.numericColumn('pre'), ds.numericColumn('post'));
    return 'r=${r.r.toStringAsFixed(4)}';
  });

  step('Regression.simple (post ~ pre)', () {
    final r =
        Regression.simple(ds.numericColumn('pre'), ds.numericColumn('post'));
    return 'R²=${r.r2.toStringAsFixed(4)}';
  });
}

/// 轻量版工程 JSON（模拟自动保存写盘体积）
Map<String, dynamic> _miniProjectJson(Dataset ds) => {
      'meta': {'name': ds.name},
      'dataset': {
        'variables': [for (final v in ds.variables) v.toJson()],
        'cases': [
          for (final row in ds.cases) [for (final cell in row) cell],
        ],
      },
    };
