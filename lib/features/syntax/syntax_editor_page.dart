/// 语法编辑器（带语法高亮）
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/dataset.dart';
import '../../core/syntax/syntax_engine.dart';
import '../../shared/dataset_store.dart';
import 'syntax_highlight_controller.dart';

class SyntaxEditorPage extends StatefulWidget {
  const SyntaxEditorPage({super.key});

  @override
  State<SyntaxEditorPage> createState() => _SyntaxEditorPageState();
}

class _SyntaxEditorPageState extends State<SyntaxEditorPage> {
  late final SyntaxHighlightController _codeCtrl;
  final _outCtrl = TextEditingController();
  bool _ran = false;

  Dataset get ds => datasetStore.data;

  @override
  void initState() {
    super.initState();
    _codeCtrl = SyntaxHighlightController(text: '''
* Stats-flutter syntax demo
DESCRIPTIVES pre post hours.
FREQUENCIES gender method.
T-TEST /TESTVAL=60 /VARIABLES=post.
CORRELATIONS /VARIABLES=pre post hours.
COMPUTE gain = post - pre.
LIST.
''');
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _outCtrl.dispose();
    super.dispose();
  }


  Future<void> _openSyntax() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sps', 'txt'],
      withData: true,
    );
    if (r == null || r.files.isEmpty) return;
    final f = r.files.first;
    String text;
    if (f.bytes != null) {
      text = String.fromCharCodes(f.bytes!);
    } else if (f.path != null) {
      text = await File(f.path!).readAsString();
    } else {
      return;
    }
    setState(() => _codeCtrl.text = text);
  }

  Future<void> _saveSyntax() async {
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/syntax_${DateTime.now().millisecondsSinceEpoch}.sps';
    await File(path).writeAsString(_codeCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              AppLocalizations.of(context).savedTo(path))),
    );
  }

  void _run() {
    final l10n = AppLocalizations.of(context);
    final results = SyntaxExecutor.run(_codeCtrl.text, ds);
    final buf = StringBuffer();
    var ok = 0, fail = 0;
    for (final r in results) {
      buf.writeln('─' * 40);
      buf.writeln(r.ok ? '✓ ${r.command}' : '✗ ${r.command}');
      buf.writeln(r.output);
      if (r.ok) {
        ok++;
      } else {
        fail++;
      }
    }
    buf.writeln('═' * 40);
    buf.writeln(l10n.syntaxDone(ok, fail));
    setState(() {
      _outCtrl.text = buf.toString();
      _ran = true;
    });
    datasetStore.touch();
  }

  void _insertTemplate(String code) {
    final sel = _codeCtrl.selection;
    final text = _codeCtrl.text;
    if (sel.isValid && sel.start >= 0) {
      _codeCtrl.text = text.replaceRange(sel.start, sel.end, code);
      _codeCtrl.selection = TextSelection.collapsed(offset: sel.start + code.length);
    } else {
      _codeCtrl.text = text + code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.syntaxTitle),
        actions: [
          IconButton(
            tooltip: l10n.openSps,
            icon: const Icon(Icons.folder_open),
            onPressed: _openSyntax,
          ),
          IconButton(
            tooltip: l10n.saveSps,
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveSyntax,
          ),
          IconButton(
            tooltip: l10n.run,
            icon: const Icon(Icons.play_arrow),
            onPressed: _run,
          ),
        ],
      ),
      body: Column(
        children: [
          // 模板工具条
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                for (final (label, code) in [
                  ('DESCRIPTIVES', 'DESCRIPTIVES pre post.\n'),
                  ('T-TEST', 'T-TEST /TESTVAL=60 /VARIABLES=post.\n'),
                  ('COMPUTE', 'COMPUTE gain = post - pre.\n'),
                  ('SORT', 'SORT CASES BY post.\n'),
                  ('SELECT IF', 'SELECT IF post >= 70.\n'),
                  ('RECODE', 'RECODE gender (1=0) (2=1) INTO sex.\n'),
                  ('CORR', 'CORRELATIONS /VARIABLES=pre post.\n'),
                  ('HELP', 'HELP.\n'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(label, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _insertTemplate(code),
                    ),
                  ),
              ],
            ),
          ),
          // 代码区
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: TextField(
                  controller: _codeCtrl,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.45,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                    hintText: l10n.syntaxHint,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 输出区
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _ran
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          _outCtrl.text,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          l10n.outputHere,
                          style: TextStyle(color: scheme.outline),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _run,
        icon: const Icon(Icons.play_arrow),
        label: Text(l10n.runSyntax),
      ),
    );
  }
}
