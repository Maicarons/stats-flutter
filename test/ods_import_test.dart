/// ODS 读取器测试：夹具由 pandas（odfpy 引擎）生成并随仓提交。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/io/ods_io.dart';

void main() {
  test('ODS：首表读出，数值/字符串推断与原始 DataFrame 一致', () {
    final bytes = File('test/fixtures/sample.ods').readAsBytesSync();
    final ds = readOdsBytes(bytes, name: 's');
    expect(ds.nVars, 3);
    expect(ds.nCases, 3);
    expect(ds.variables.map((v) => v.name).toList(),
        ['id', 'score', 'name']);
    expect(ds.variables[0].isNumeric, isTrue);
    expect(ds.variables[1].isNumeric, isTrue);
    expect(ds.variables[2].isNumeric, isFalse);
    expect(ds.columnByName('id'), [1.0, 2.0, 3.0]);
    expect(ds.columnByName('score')[0] as double, closeTo(85.5, 1e-9));
    expect(ds.columnByName('score')[2] as double, closeTo(78.25, 1e-9));
    expect(ds.columnByName('name'), ['Alice', 'Bo', 'Cat']);
  });

  test('非 ODS 文件报错', () {
    expect(
        () => readOdsBytes([1, 2, 3]), throwsA(isA<OdsException>()));
  });
}
