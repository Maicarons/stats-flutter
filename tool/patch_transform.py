from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\lib\features\data_editor\data_editor_page.dart")
t = p.read_text(encoding="utf-8")

t = t.replace(
    "import 'csv_io.dart';",
    "import '../../transform/transform_page.dart';\nimport 'csv_io.dart';",
)

t = t.replace(
    "              PopupMenuItem(value: 'addcase', child: Text(l10n.addCase)),\n            ],",
    "              PopupMenuItem(value: 'addcase', child: Text(l10n.addCase)),\n              PopupMenuItem(value: 'transform', child: const Text('数据变换…')),\n            ],",
)

t = t.replace(
    "      case 'addcase':\n        _addCase(l10n);\n        break;\n    }",
    "      case 'addcase':\n        _addCase(l10n);\n        break;\n      case 'transform':\n        if (context.mounted) {\n          Navigator.of(context).push(\n            MaterialPageRoute(builder: (_) => const TransformPage()),\n          );\n        }\n        break;\n    }",
)

p.write_text(t, encoding="utf-8")
print("data editor patched")

# analysis_runner: add new cases
p = Path(r"F:\workspace\stats-flutter\lib\features\analysis\analysis_runner.dart")
t = p.read_text(encoding="utf-8")
if "case 'means':" not in t:
    t = t.replace(
        "        case 'bar':\n          _runBar();\n          break;",
        "        case 'bar':\n          _runBar();\n          break;\n        case 'means':\n          _runMeans();\n          break;\n        case 'normality':\n          _runNormality();\n          break;\n        case 'roc':\n          _runRoc();\n          break;\n        case 'tukey':\n          _runTukey();\n          break;",
    )
    p.write_text(t, encoding="utf-8")
    print("runner cases added")
else:
    print("runner already has cases")
