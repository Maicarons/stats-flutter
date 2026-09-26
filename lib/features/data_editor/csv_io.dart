/// CSV 导入 / 导出
library;

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/dataset.dart';
import '../../shared/dataset_store.dart';

Future<void> importCsvInteractive(BuildContext context) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'tsv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    String text;
    if (f.bytes != null) {
      text = utf8.decode(f.bytes!, allowMalformed: true);
    } else if (f.path != null) {
      text = await File(f.path!).readAsString();
    } else {
      return;
    }
    final rows = const CsvToListConverter(shouldParseNumbers: false)
        .convert(text, eol: '\n')
        .map((r) => r.map((e) => e.toString().trim()).toList())
        .toList();
    if (rows.isEmpty) return;
    final headers = rows.first;
    final body = rows.skip(1).toList();
    final ds = Dataset.fromRows(
      headers: headers,
      rows: body,
      name: f.name.replaceAll(RegExp(r'\.(csv|tsv|txt)$'), ''),
    );
    datasetStore.replace(ds);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导入 ${ds.nCases} 个案 × ${ds.nVars} 变量')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导入失败：$e')));
    }
  }
}

Future<void> exportCsvInteractive(BuildContext context) async {
  try {
    final ds = datasetStore.data;
    final buffer = StringBuffer();
    buffer.writeln(ds.variables.map((v) => v.name).join(','));
    for (final row in ds.cases) {
      final cells = <String>[];
      for (var i = 0; i < ds.nVars; i++) {
        final v = i < row.length ? row[i] : null;
        cells.add(v == null ? '' : v.toString());
      }
      buffer.writeln(cells.map(_escape).join(','));
    }
    final content = buffer.toString();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${ds.name}.csv');
    await file.writeAsString(content);

    if (context.mounted) {
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save),
                title: Text('已保存到 ${file.path}'),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('分享文件'),
                onTap: () => Navigator.pop(ctx, 'share'),
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('复制到剪贴板'),
                onTap: () => Navigator.pop(ctx, 'copy'),
              ),
            ],
          ),
        ),
      );
      if (action == 'share') {
        await Share.shareXFiles([XFile(file.path)], text: 'StatLab 数据导出');
      } else if (action == 'copy') {
        await Clipboard.setData(ClipboardData(text: content));
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('已复制')));
        }
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导出失败：$e')));
    }
  }
}

String _escape(String s) {
  if (s.contains(',') || s.contains('"') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}
