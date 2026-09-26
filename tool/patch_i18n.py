from pathlib import Path

def patch(path, pairs):
    p = Path(path)
    t = p.read_text(encoding="utf-8")
    for a, b in pairs:
        if a not in t:
            print(f"WARN not found in {path}: {a[:60]!r}")
        t = t.replace(a, b)
    p.write_text(t, encoding="utf-8")
    print(f"patched {path}")

root = Path(r"F:\workspace\stats-flutter")

patch(root / r"lib\features\analysis\analysis_hub.dart", [
    (
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:flutter_gen/gen_l10n/app_localizations.dart';",
    ),
    (
        "title: const Text('统计分析',\n            style: TextStyle(fontWeight: FontWeight.w600)),",
        "title: Text(AppLocalizations.of(context)!.tabAnalysis,\n            style: const TextStyle(fontWeight: FontWeight.w600)),",
    ),
])

patch(root / r"lib\features\learn\learn_page.dart", [
    (
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:flutter_gen/gen_l10n/app_localizations.dart';",
    ),
    (
        "title: const Text('统计学习', style: TextStyle(fontWeight: FontWeight.w600)),",
        "title: Text(AppLocalizations.of(context)!.learnTitle,\n            style: const TextStyle(fontWeight: FontWeight.w600)),",
    ),
    (
        "Text('从概念到公式',",
        "Text(AppLocalizations.of(context)!.learnTagline,",
    ),
])

patch(root / r"lib\features\quiz\quiz_page.dart", [
    (
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:flutter_gen/gen_l10n/app_localizations.dart';",
    ),
    (
        "title: const Text('统计测试', style: TextStyle(fontWeight: FontWeight.w600)),",
        "title: Text(AppLocalizations.of(context)!.quizTitle,\n            style: const TextStyle(fontWeight: FontWeight.w600)),",
    ),
    (
        "const Text('交卷')",
        "Text(AppLocalizations.of(context)!.submit)",
    ),
    (
        "const Text('上一题')",
        "Text(AppLocalizations.of(context)!.prev)",
    ),
    (
        "Text(_current < _paper.length - 1 ? '下一题' : '交卷')",
        "Text(_current < _paper.length - 1\n                            ? AppLocalizations.of(context)!.next\n                            : AppLocalizations.of(context)!.submit)",
    ),
])
print("all done")
