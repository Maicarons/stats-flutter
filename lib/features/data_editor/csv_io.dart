/// CSV / Excel 导入、CSV 导出
library;

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/io/sav_write.dart';
import '../../core/models/dataset.dart';
import '../../shared/dataset_store.dart';
import 'excel_io.dart';

Future<void> importCsvInteractive(BuildContext context, AppLocalizations l10n,
    {bool excelToo = false}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions:
          excelToo ? ['csv', 'tsv', 'txt', 'xlsx'] : ['csv', 'tsv', 'txt'],
    );
    if (f == null) return;
    if (excelToo && f.name.toLowerCase().endsWith('.xlsx')) {
      await importExcelBytes(messenger, l10n, f.name, await f.readAsBytes());
      return;
    }
    Uint8List bytes;
    try {
      bytes = await f.readAsBytes();
    } catch (_) {
      return;
    }
    final text = utf8.decode(bytes, allowMalformed: true);
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
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.importSuccess(ds.nCases, ds.nVars))),
    );
  } catch (e) {
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.importFailed(e.toString()))));
  }
}

Future<void> exportCsvInteractive(
    BuildContext context, AppLocalizations l10n) async {
  final messenger = ScaffoldMessenger.of(context);
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
                title: Text(l10n.savedTo(file.path)),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(l10n.shareFile),
                onTap: () => Navigator.pop(ctx, 'share'),
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(l10n.copyToClipboard),
                onTap: () => Navigator.pop(ctx, 'copy'),
              ),
            ],
          ),
        ),
      );
      if (action == 'share') {
        await SharePlus.instance.share(ShareParams(
            files: [XFile(file.path)], text: l10n.shareDataText));
      } else if (action == 'copy') {
        await Clipboard.setData(ClipboardData(text: content));
        messenger
            .showSnackBar(SnackBar(content: Text(l10n.copied)));
      }
    }
  } catch (e) {
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))));
  }
}

/// 导出为 SPSS 系统文件（.sav）：写到应用文档目录后提供分享。
Future<void> exportSavInteractive(
    BuildContext context, AppLocalizations l10n) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final ds = datasetStore.data;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${ds.name}.sav');
    await file.writeAsBytes(
        SavWriter.writeBytes(ds, fileLabel: ds.name), flush: true);
    if (context.mounted) {
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save),
                title: Text(l10n.savedTo(file.path)),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(l10n.shareFile),
                onTap: () => Navigator.pop(ctx, 'share'),
              ),
            ],
          ),
        ),
      );
      if (action == 'share') {
        await SharePlus.instance.share(ShareParams(
            files: [XFile(file.path)], text: l10n.shareDataText));
      }
    }
  } catch (e) {
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))));
  }
}

String _escape(String s) {
  if (s.contains(',') || s.contains('"') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}
