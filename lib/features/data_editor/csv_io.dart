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

import '../../core/models/dataset.dart';
import '../../shared/dataset_store.dart';
import 'excel_io.dart';

Future<void> importCsvInteractive(BuildContext context, AppLocalizations l10n,
    {bool excelToo = false}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions:
          excelToo ? ['csv', 'tsv', 'txt', 'xlsx'] : ['csv', 'tsv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (excelToo && f.name.toLowerCase().endsWith('.xlsx')) {
      await importExcelBytes(messenger, l10n, f.name, f.bytes);
      return;
    }
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
        await Share.shareXFiles([XFile(file.path)],
            text: l10n.shareDataText);
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

String _escape(String s) {
  if (s.contains(',') || s.contains('"') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}
