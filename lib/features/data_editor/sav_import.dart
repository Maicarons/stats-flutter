/// SPSS .sav 导入
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/io/sav_io.dart';
import '../../shared/dataset_store.dart';

Future<void> importSavInteractive(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  try {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['sav'],
    );
    if (f == null) return;
    Uint8List bytes;
    try {
      bytes = await f.readAsBytes();
    } catch (_) {
      return;
    }
    final info = SavReader.readBytes(bytes, name: f.name.replaceAll('.sav', ''));
    datasetStore.replace(info.dataset);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.savImported(
            info.dataset.nCases,
            info.dataset.nVars,
            info.header.productName,
          )),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.savImportFailed('$e'))),
      );
    }
  }
}
