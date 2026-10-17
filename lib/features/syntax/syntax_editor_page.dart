/// 语法编辑器（带语法高亮）
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/dataset.dart';
import '../../core/syntax/syntax_engine.dart';
import '../../shared/dataset_store.dart';
import '../../shared/locale_util.dart';
import '../data_editor/pick_dataset.dart';
import 'sps_codec.dart';
import 'syntax_highlight_controller.dart';

class SyntaxEditorPage extends StatefulWidget {
  const SyntaxEditorPage({super.key});

  @override
  State<SyntaxEditorPage> createState() => _SyntaxEditorPageState();
}

class _SyntaxEditorPageState extends State<SyntaxEditorPage> {
  late final SyntaxHighlightController _codeCtrl;
  final _codeFocus = FocusNode();
  bool _ran = false;
  int _ok = 0;
  int _fail = 0;

  /// 最近一次运行的结果（按原始位置排序；`file == null` 的可点击跳转）
  List<SyntaxResult> _results = const [];
  String _attachedNote = '';

  /// 当前打开的 `.sps` 路径（保存时覆盖它；`INCLUDE` 相对它解析）
  String? _spsPath;

  /// 打开的 `.sps` 所在目录 / 应用文档目录（都带尾部分隔符），
  /// 用于解析 `INCLUDE` 的相对路径。
  String? _spsDir;
  String? _docsDir;

  /// ADD FILES / MATCH FILES 引用的其它数据集（键：文件路径与文件名）
  final Map<String, Dataset> _attached = {};

  Dataset get ds => datasetStore.data;

  @override
  void initState() {
    super.initState();
    _codeCtrl = SyntaxHighlightController(text: '''
* Stats-flutter syntax demo.
DESCRIPTIVES pre post hours.
FREQUENCIES gender method.
T-TEST /TESTVAL=60 /VARIABLES=post.
CORRELATIONS /VARIABLES=pre post hours.
COMPUTE gain = post - pre.
LIST.
''');
    _initDocsDir();
  }

  /// 记录应用文档目录，作为未打开 `.sps` 时 `INCLUDE` 的兜底搜索位置
  Future<void> _initDocsDir() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (!mounted) return;
      setState(() => _docsDir = _withSep(dir.path));
    } catch (_) {
      // 拿不到就只按当前目录搜索
    }
  }

  static String _withSep(String dir) =>
      dir.endsWith('/') || dir.endsWith('\\')
          ? dir
          : '$dir${Platform.pathSeparator}';

  static String? _dirOf(String? path) {
    if (path == null) return null;
    final i = path.lastIndexOf(RegExp(r'[\\/]'));
    return i < 0 ? null : path.substring(0, i + 1);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  // ── 文件读写（M3.5）───────────────────────────────────────────────

  /// 默认文件名：`syntax_yyyyMMdd_HHmm.sps`
  String _defaultSpsName() {
    final t = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'syntax_${t.year}${two(t.month)}${two(t.day)}'
        '_${two(t.hour)}${two(t.minute)}.sps';
  }

  Future<void> _openSyntax() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sps', 'txt'],
      withData: true,
    );
    if (r == null || r.files.isEmpty) return;
    final f = r.files.first;
    var bytes = f.bytes;
    if (bytes == null && f.path != null) {
      bytes = await File(f.path!).readAsBytes();
    }
    if (bytes == null) return;
    final decoded = SpsCodec.decode(bytes);
    if (!mounted) return;
    setState(() {
      _codeCtrl.text = decoded.text;
      _spsPath = f.path;
      _spsDir = _dirOf(f.path);
      _ran = false;
      _results = const [];
      _ok = 0;
      _fail = 0;
    });
    if (decoded.replaced) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.spsDecodeReplaced)),
      );
    }
  }

  /// 保存：「保存」优先覆盖当前文件，否则弹「另存为」；两者都拿不到路径时
  /// 落到应用文档目录（保证在移动端也一定保存成功）。
  Future<void> _saveSyntax({bool saveAs = false}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var path = saveAs ? null : _spsPath;
    if (path == null) {
      try {
        path = await FilePicker.platform.saveFile(
          dialogTitle: l10n.spsSaveAs,
          fileName: _defaultSpsName(),
          type: FileType.custom,
          allowedExtensions: const ['sps'],
        );
      } catch (_) {
        path = null; // 该平台没有「另存为」对话框
      }
    }
    if (path == null || path.trim().isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      path = '${dir.path}/${_defaultSpsName()}';
    } else if (!path.toLowerCase().endsWith('.sps')) {
      path = '$path.sps';
    }
    await File(path).writeAsBytes(SpsCodec.encode(_codeCtrl.text));
    if (!mounted) return;
    setState(() {
      _spsPath = path;
      _spsDir = _dirOf(path);
    });
    messenger.showSnackBar(SnackBar(content: Text(l10n.savedTo(path))));
  }

  /// `INCLUDE` 的文件解析器（core 不碰 `dart:io`）：依次尝试相对当前
  /// `.sps` 目录、当前工作目录、应用文档目录。
  String? _resolveInclude(String path) {
    final f = File(path);
    final candidates = <File>[
      if (f.isAbsolute)
        f
      else ...[
        if (_spsDir != null) File('$_spsDir$path'),
        File(path),
        if (_docsDir != null) File('$_docsDir$path'),
      ],
    ];
    for (final c in candidates) {
      try {
        if (c.existsSync()) return SpsCodec.decode(c.readAsBytesSync()).text;
      } catch (_) {
        // 该候选读不到就换下一个
      }
    }
    return null;
  }

  /// 附加一个数据集文件，供 ADD FILES / MATCH FILES 引用
  Future<void> _attachDataset() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await pickDatasetFile();
    if (picked == null) return;
    setState(() {
      _attached[picked.fileName] = picked.dataset;
      if (picked.path != null) _attached[picked.path!] = picked.dataset;
    });
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.syntaxAttached(picked.fileName))),
    );
  }

  void _run() {
    final l10n = AppLocalizations.of(context);
    final results = SyntaxExecutor.run(
      _codeCtrl.text,
      ds,
      messages: isZhUi(context) ? SyntaxMessages.zh : SyntaxMessages.en,
      files: _attached,
      include: _resolveInclude,
    );
    var ok = 0, fail = 0;
    for (final r in results) {
      if (r.ok) {
        ok++;
      } else {
        fail++;
      }
    }
    var note = '';
    if (_attached.isNotEmpty) {
      final names = <String>{};
      for (final e in _attached.entries) {
        names.add(e.key.split(RegExp(r'[\\/]')).last);
      }
      note = l10n.syntaxAttachedList(names.join(', '));
    }
    setState(() {
      _results = results;
      _ok = ok;
      _fail = fail;
      _attachedNote = note;
      _ran = true;
    });
    datasetStore.touch();
  }

  /// 点击日志跳回源码：仅主脚本的结果（`INCLUDE` 进来的是别的文件）
  void _jumpTo(SyntaxResult r) {
    final text = _codeCtrl.text;
    final start = (r.start ?? 0).clamp(0, text.length);
    final end = (r.end ?? start).clamp(start, text.length);
    _codeFocus.requestFocus();
    _codeCtrl.selection = TextSelection(baseOffset: start, extentOffset: end);
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

  /// 光标所在行列（1-based）
  (int, int) _lineCol(int offset) {
    final text = _codeCtrl.text;
    final at = offset.clamp(0, text.length);
    var line = 1, col = 1;
    for (var i = 0; i < at; i++) {
      if (text.codeUnitAt(i) == 0x0A) {
        line++;
        col = 1;
      } else {
        col++;
      }
    }
    return (line, col);
  }

  // ── 界面 ────────────────────────────────────────────────────────

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
            tooltip: l10n.spsSaveAs,
            icon: const Icon(Icons.save_as_outlined),
            onPressed: () => _saveSyntax(saveAs: true),
          ),
          IconButton(
            tooltip: l10n.syntaxAttach,
            icon: const Icon(Icons.library_add_outlined),
            onPressed: _attachDataset,
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
                  ('RECODE', 'RECODE gender (1=0) (2=1) INTO sex.\n'),
                  ('CORR', 'CORRELATIONS /VARIABLES=pre post.\n'),
                  (
                    'DEFINE',
                    'DEFINE !desc(!POSITIONAL !TOKENS(1))\n'
                        '  DESCRIPTIVES !1.\n'
                        '!ENDDEFINE.\n'
                        '!desc pre.\n'
                  ),
                  ('INCLUDE', "INCLUDE 'macros.sps'.\n"),
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
                  focusNode: _codeFocus,
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
          // 光标位置 / 当前文件
          ListenableBuilder(
            listenable: _codeCtrl,
            builder: (context, _) {
              final (line, col) = _lineCol(_codeCtrl.selection.baseOffset);
              final name = _spsPath?.split(RegExp(r'[\\/]')).last;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    Text(
                      l10n.syntaxCursor(line, col),
                      style: TextStyle(fontSize: 11, color: scheme.outline),
                    ),
                    const Spacer(),
                    if (name != null)
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 11, color: scheme.outline),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // 输出区：每条命令一块，可点跳转
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
                    ? _output(scheme)
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

  Widget _output(ColorScheme scheme) {
    final l10n = AppLocalizations.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _results.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_attachedNote.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _attachedNote,
                      style: TextStyle(fontSize: 11, color: scheme.outline),
                    ),
                  ),
                Text(
                  l10n.syntaxDone(_ok, _fail),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          );
        }
        return _resultTile(_results[i - 1], l10n, scheme);
      },
    );
  }

  Widget _resultTile(
      SyntaxResult r, AppLocalizations l10n, ColorScheme scheme) {
    final canJump = r.file == null && r.start != null;
    final color =
        r.hint ? scheme.tertiary : (r.ok ? scheme.primary : scheme.error);
    final icon = r.hint
        ? Icons.info_outline
        : (r.ok ? Icons.check_circle_outline : Icons.error_outline);
    final badge = r.line == null
        ? null
        : (r.file != null
            ? '${r.file!.split(RegExp(r'[\\/]')).last}:${r.line}'
            : l10n.syntaxAtLine(r.line!));
    return InkWell(
      onTap: canJump ? () => _jumpTo(r) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                if (badge != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      r.hint ? l10n.hintTitle : badge,
                      style: TextStyle(fontSize: 10, color: color),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    r.command,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (canJump)
                  Icon(Icons.my_location, size: 13, color: scheme.outline),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 3, 0, 0),
              child: SelectableText(
                r.output,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.35,
                  color: r.ok ? scheme.onSurface : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
