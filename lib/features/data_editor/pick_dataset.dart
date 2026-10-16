/// 选择并读取一个数据集文件（.sav / .csv / .tsv / .txt / .xlsx）。
///
/// 与 `csv_io.dart` / `sav_import.dart` 的「导入并替换当前数据集」不同：这里
/// 只**读出一份 Dataset**（不改动当前数据集），供 COMBINE FILES 的
/// 「另一个文件」以及语法编辑器的「附加数据集」使用。
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/io/sav_io.dart';
import '../../core/models/dataset.dart';
import 'excel_io.dart';

/// 选中的文件：文件名（含扩展名）、路径与读出的数据集
class PickedDataset {
  PickedDataset(this.fileName, this.path, this.dataset);

  final String fileName;
  final String? path;
  final Dataset dataset;
}

/// 弹出文件选择框并读出一个数据集；用户取消或读不出数据时返回 null。
Future<PickedDataset?> pickDatasetFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['sav', 'csv', 'tsv', 'txt', 'xlsx'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final f = result.files.first;
  final lower = f.name.toLowerCase();
  Uint8List? bytes = f.bytes;
  if (bytes == null && f.path != null) {
    bytes = await File(f.path!).readAsBytes();
  }
  if (bytes == null) return null;
  final base = f.name.replaceAll(RegExp(r'\.(sav|csv|tsv|txt|xlsx)$'), '');
  final Dataset ds;
  if (lower.endsWith('.sav')) {
    ds = readSavBytes(bytes, name: base);
  } else if (lower.endsWith('.xlsx')) {
    ds = datasetFromExcelBytes(bytes, name: base);
  } else {
    final text = utf8.decode(bytes, allowMalformed: true);
    final rows = const CsvToListConverter(shouldParseNumbers: false)
        .convert(text, eol: '\n')
        .map((r) => r.map((e) => e.toString().trim()).toList())
        .toList();
    if (rows.isEmpty) return null;
    ds = Dataset.fromRows(
      headers: rows.first,
      rows: rows.skip(1).toList(),
      name: base,
    );
  }
  return PickedDataset(f.name, f.path, ds);
}
