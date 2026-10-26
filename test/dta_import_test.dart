/// Stata .dta 读取器测试：夹具由 pandas（Stata 写出参考实现）生成并随仓
/// 提交（test/fixtures/sample118.dta / sample114.dta / probe.dta），
/// 期望值冻结自原始 DataFrame。118 覆盖 byte/int16/double/字符串/缺失；
/// 114 为旧格式，应明确报不支持。
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/io/dta_io.dart';
import 'package:stats_flutter/core/models/dataset.dart';

void main() {
  test('118：数值 / 字符串 / 缺失与 pandas 原始数据一致', () {
    final bytes =
        File('test/fixtures/sample118.dta').readAsBytesSync();
    final ds = DtaReader.readBytes(bytes, name: 's118');
    expect(ds.nVars, 4);
    expect(ds.nCases, 3);
    expect(ds.variables.map((v) => v.name).toList(),
        ['id', 'score', 'gender', 'name']);
    expect(ds.columnByName('id'), [1.0, 2.0, 3.0]);
    expect(ds.columnByName('score')[0] as double, closeTo(85.5, 1e-9));
    expect(ds.columnByName('score')[2] as double, closeTo(78.25, 1e-9));
    expect(ds.columnByName('gender'), [1.0, 2.0, 1.0]);
    expect(ds.columnByName('name'), ['Alice', 'Bo', 'Bob']);
  });

  test('118：缺失值（byte/int16/double）读为 null', () {
    final bytes = File('test/fixtures/probe.dta').readAsBytesSync();
    final ds = DtaReader.readBytes(bytes, name: 'probe');
    expect(ds.nVars, 4);
    expect(ds.nCases, 3);
    // b: 1, 缺失, 3
    final b = ds.columnByName('b');
    expect(b[0], 1.0);
    expect(b[1], isNull);
    expect(b[2], 3.0);
    // i: 100, 200, 缺失
    final i = ds.columnByName('i');
    expect(i[0], 100.0);
    expect(i[1], 200.0);
    expect(i[2], isNull);
    // f: 0.5, 缺失, 2.5
    final f = ds.columnByName('f');
    expect(f[0] as double, closeTo(0.5, 1e-9));
    expect(f[1], isNull);
    expect(f[2] as double, closeTo(2.5, 1e-9));
    // s: 'a', 'bb', 空串 → null
    final s = ds.columnByName('s');
    expect(s[0], 'a');
    expect(s[1], 'bb');
    expect(s[2], isNull);
  });

  test('118：值标签（pandas Categorical 写出）挂到变量', () {
    final bytes = File('test/fixtures/labels118.dta').readAsBytesSync();
    final ds = DtaReader.readBytes(bytes, name: 'labels');
    final gender = ds.variables.firstWhere((v) => v.name == 'gender');
    expect(gender.valueLabels[0], '男');
    expect(gender.valueLabels[1], '女');
    // 数据码 0/1 与标签一致；名义尺度自动归位
    expect(gender.measure, MeasureLevel.nominal);
    // score 不受影响
    final score = ds.variables.firstWhere((v) => v.name == 'score');
    expect(score.valueLabels, isEmpty);
    expect(score.measure, MeasureLevel.scale);
  });

  test('旧格式 114 明确报不支持', () {
    final bytes = File('test/fixtures/sample114.dta').readAsBytesSync();
    expect(() => DtaReader.readBytes(bytes), throwsA(isA<DtaException>()));
  });

  test('非 .dta 文件报错', () {
    expect(() => DtaReader.readBytes(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<DtaException>()));
  });
}
