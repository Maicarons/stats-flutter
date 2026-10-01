/// Excel (.xlsx) 导入
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/dataset.dart';
import '../../shared/dataset_store.dart';

/// 弹出文件选择并导入 xlsx
Future<void> importExcelInteractive(
    BuildContext context, AppLocalizations l10n) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    await importExcelBytes(messenger, l10n, f.name, f.bytes, path: f.path);
  } catch (e) {
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.importFailed(e.toString()))));
  }
}

/// 从字节（或路径）导入 xlsx，取第一个工作表
Future<void> importExcelBytes(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  String fileName,
  Uint8List? bytes, {
  String? path,
}) async {
  try {
    Uint8List data;
    if (bytes != null && bytes.isNotEmpty) {
      data = bytes;
    } else if (path != null) {
      data = await File(path).readAsBytes();
    } else {
      return;
    }
    final ds = datasetFromExcelBytes(data,
        name: fileName.replaceAll(RegExp(r'\.xlsx$', caseSensitive: false), ''));
    datasetStore.replace(ds);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.importSuccess(ds.nCases, ds.nVars))),
    );
  } catch (e) {
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.importFailed(e.toString()))));
  }
}

/// 解析 xlsx 字节为数据集（纯函数，便于测试）
Dataset datasetFromExcelBytes(Uint8List data, {String name = 'Excel'}) {
  final excel = Excel.decodeBytes(data);
  if (excel.tables.isEmpty) {
    throw const FormatException('empty workbook');
  }
  final sheetName = excel.tables.keys.first;
  final sheet = excel.tables[sheetName]!;
  final rows = <List<String>>[];
  for (final row in sheet.rows) {
    rows.add([
      for (final cell in row) _cellText(cell),
    ]);
  }
  // 去除末尾连续空行
  while (rows.isNotEmpty && rows.last.every((c) => c.isEmpty)) {
    rows.removeLast();
  }
  if (rows.isEmpty) {
    throw const FormatException('empty sheet');
  }
  final headers = rows.first
      .map((h) => h.trim().isEmpty ? '' : h.trim())
      .toList();
  final body = rows.skip(1).map((r) {
    // 补齐行宽
    while (r.length < headers.length) {
      r.add('');
    }
    return r.sublist(0, headers.length);
  }).toList();
  return Dataset.fromRows(headers: headers, rows: body, name: name);
}

String _cellText(Data? cell) {
  if (cell == null) return '';
  final v = cell.value;
  if (v == null) return '';
  final s = switch (v) {
    TextCellValue(:final value) => value.text ?? '',
    IntCellValue(:final value) => value.toString(),
    DoubleCellValue(:final value) => value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString(),
    BoolCellValue(:final value) => value ? '1' : '0',
    DateCellValue(:final year, :final month, :final day) =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
    _ => v.toString(),
  };
  return s.trim();
}
