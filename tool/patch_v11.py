from pathlib import Path

# 1) CSV menu: add sav import and html export
p = Path(r"F:\workspace\stats-flutter\lib\features\data_editor\data_editor_page.dart")
t = p.read_text(encoding="utf-8")
if "importSav" not in t:
    t = t.replace(
        "import 'csv_io.dart';",
        "import 'csv_io.dart';\nimport 'sav_import.dart';",
    )
    t = t.replace(
        "                  PopupMenuItem(value: 'import', child: Text(l10n.importCsv)),",
        "                  PopupMenuItem(value: 'import', child: Text(l10n.importCsv)),\n                  const PopupMenuItem(value: 'import_sav', child: Text('导入 SPSS .sav…')),",
    )
    t = t.replace(
        "      case 'import':\n        await importCsvInteractive(context);",
        "      case 'import':\n        await importCsvInteractive(context);\n        break;\n      case 'import_sav':\n        await importSavInteractive(context);",
    )
    p.write_text(t, encoding="utf-8")
    print("data menu sav")

# 2) analysis_runner: HTML export action + MissingAware
p = Path(r"F:\workspace\stats-flutter\lib\features\analysis\analysis_runner.dart")
t = p.read_text(encoding="utf-8")
if "reportToHtml" not in t:
    t = t.replace(
        "import '../output/report_builder.dart';",
        "import '../../core/io/missing_aware.dart';\nimport '../output/report_builder.dart';\nimport '../output/report_export.dart';",
    )
    t = t.replace(
        """          if (_report != null)
            IconButton(
              tooltip: '分享报告',
              icon: const Icon(Icons.share),
              onPressed: () => Share.share(_report!.toPlainText(),
                  subject: _report!.title),
            ),""",
        """          if (_report != null)
            IconButton(
              tooltip: '分享报告',
              icon: const Icon(Icons.share),
              onPressed: () => Share.share(_report!.toPlainText(),
                  subject: _report!.title),
            ),
          if (_report != null)
            IconButton(
              tooltip: '导出 HTML',
              icon: const Icon(Icons.html),
              onPressed: () => _exportHtml(),
            ),""",
    )
    # add _exportHtml method near _run
    if "Future<void> _exportHtml" not in t:
        marker = "  Future<void> _run() async {"
        method = '''  Future<void> _exportHtml() async {
    final r = _report;
    if (r == null) return;
    final html = reportToHtml(r);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('\${dir.path}/\${r.title.replaceAll(RegExp(r"\\s+"), "_")}.html');
      await f.writeAsString(html);
      await Share.shareXFiles([XFile(f.path)], subject: r.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: \$e')),
        );
      }
    }
  }

'''
        t = t.replace(marker, method + marker, 1)
        # imports for file io
        if "dart:io" not in t:
            t = t.replace(
                "import 'dart:math' as math;",
                "import 'dart:io';\nimport 'dart:math' as math;",
            )
        if "path_provider" not in t:
            t = t.replace(
                "import 'package:share_plus/share_plus.dart';",
                "import 'package:path_provider/path_provider.dart';\nimport 'package:share_plus/share_plus.dart';",
            )
        print("export html")

    # Use MissingAware in _runDescriptives
    t = t.replace(
        "map[name] = Descriptives.compute(ds.numericColumn(name));",
        "map[name] = Descriptives.compute(MissingAware.numeric(ds, name));",
    )
    p.write_text(t, encoding="utf-8")
    print("runner missing-aware")

# 3) sav import helper
Path(r"F:\workspace\stats-flutter\lib\features\data_editor\sav_import.dart").write_text(
    r'''/// SPSS .sav 导入
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/io/sav_io.dart';
import '../../shared/dataset_store.dart';

Future<void> importSavInteractive(BuildContext context) async {
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
          content: Text(
              '已导入 ${info.dataset.nCases} 个案 × ${info.dataset.nVars} 变量 (${info.header.productName})'),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导入 .sav 失败：$e')));
    }
  }
}
''',
    encoding="utf-8",
)
print("sav_import")
print("done")
