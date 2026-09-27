from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\lib\core\io\sav_io.dart")
t = p.read_text(encoding="utf-8")
t = t.replace(
    "    final weightIndex = bd.getInt32(76, Endian.little);",
    "    // weightIndex at 76 unused in reader",
)
t = t.replace("    final creationDate = readStr(92, 9);", "    // creationDate at 92")
t = t.replace("    final creationTime = readStr(101, 8);", "    // creationTime at 101")
p.write_text(t, encoding="utf-8")
print("sav clean")

p = Path(r"F:\workspace\stats-flutter\lib\features\syntax\syntax_editor_page.dart")
t = p.read_text(encoding="utf-8")
if "file_picker" not in t:
    t = t.replace(
        "import 'package:flutter/material.dart';",
        "import 'dart:io';\n\nimport 'package:file_picker/file_picker.dart';\nimport 'package:path_provider/path_provider.dart';\nimport 'package:flutter/material.dart';",
    )
old_actions = """        actions: [
          IconButton(
            tooltip: '运行',
            icon: const Icon(Icons.play_arrow),
            onPressed: _run,
          ),
        ],"""
new_actions = """        actions: [
          IconButton(
            tooltip: 'Open .sps',
            icon: const Icon(Icons.folder_open),
            onPressed: _openSyntax,
          ),
          IconButton(
            tooltip: 'Save .sps',
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveSyntax,
          ),
          IconButton(
            tooltip: 'Run',
            icon: const Icon(Icons.play_arrow),
            onPressed: _run,
          ),
        ],"""
if old_actions in t:
    t = t.replace(old_actions, new_actions)
    print("actions")

methods = """
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
        dir.path + '/syntax_' + DateTime.now().millisecondsSinceEpoch.toString() + '.sps';
    await File(path).writeAsString(_codeCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved: ' + path)),
    );
  }

"""
if "void _saveSyntax" not in t:
    t = t.replace("  void _run() {", methods + "  void _run() {", 1)
    print("methods")
p.write_text(t, encoding="utf-8")
print("syntax done")
