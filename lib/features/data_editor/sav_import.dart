/// SPSS .sav 导入
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/io/sav_io.dart';
import '../../shared/dataset_store.dart';

Future<void> importSavInteractive(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sav'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    Uint8List? bytes = f.bytes;
    if (bytes == null && f.path != null) {
      bytes = await File(f.path!).readAsBytes();
    }
    if (bytes == null) return;
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
