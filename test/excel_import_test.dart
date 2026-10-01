import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/features/data_editor/excel_io.dart';

/// 用 excel 包构造一个真实的 xlsx 字节流再解析，形成端到端用例
Uint8List buildXlsx() {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];
  sheet.appendRow([TextCellValue('name'), TextCellValue('score')]);
  sheet.appendRow([TextCellValue('alice'), DoubleCellValue(88.5)]);
  sheet.appendRow([TextCellValue('bob'), DoubleCellValue(92.0)]);
  sheet.appendRow([TextCellValue(''), TextCellValue('')]); // 尾部空行
  final bytes = excel.encode()!;
  return Uint8List.fromList(bytes);
}

void main() {
  test('datasetFromExcelBytes parses first sheet with type inference', () {
    final ds = datasetFromExcelBytes(buildXlsx(), name: 't');
    expect(ds.nVars, 2);
    expect(ds.nCases, 2); // 尾部空行被剔除
    expect(ds.variables[0].type, VarType.string);
    expect(ds.variables[1].type, VarType.numeric);
    expect(ds.cases[0][0], 'alice');
    expect(ds.cases[0][1], 88.5);
  });
}
