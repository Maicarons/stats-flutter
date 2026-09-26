from pathlib import Path

def fix(path, old, new, label=""):
    p = Path(path)
    t = p.read_text(encoding="utf-8")
    if old not in t:
        print(f"WARN not found [{label}]: {old[:50]!r}")
        return
    p.write_text(t.replace(old, new, encoding="utf-8") if False else t.replace(old, new), encoding="utf-8")
    print(f"fixed [{label}]")

root = Path(r"F:\workspace\stats-flutter")

fix(
    root / r"lib\core\syntax\syntax_engine.dart",
    "import 'transforms/transforms.dart';",
    "import '../transforms/transforms.dart';",
    "syntax import",
)

# analysis_runner add dart:math
p = root / r"lib\features\analysis\analysis_runner.dart"
t = p.read_text(encoding="utf-8")
if "import 'dart:math'" not in t:
    t = t.replace(
        "import 'package:fl_chart/fl_chart.dart';",
        "import 'dart:math' as math;\n\nimport 'package:fl_chart/fl_chart.dart';",
    )
    p.write_text(t, encoding="utf-8")
    print("math import")

# splash import
fix(
    root / r"lib\features\splash\splash_page.dart",
    "import '../features/home/home_shell.dart';",
    "import '../home/home_shell.dart';",
    "splash import",
)

# about unused
fix(
    root / r"lib\features\settings\about_page.dart",
    "import '../../shared/app_settings.dart';\n",
    "",
    "about unused",
)

# factor_logistic
p = root / r"packages\statkit\lib\src\factor_logistic.dart"
t = p.read_text(encoding="utf-8")
t = t.replace("import 'distributions.dart';\n", "")
# fix List<num> issue - means/stds fold
t = t.replace(
    "final means = List.filled(p, 0.0);",
    "final means = List<double>.filled(p, 0);",
)
p.write_text(t, encoding="utf-8")
print("factor fixed")

# syntax engine unnecessary services import in syntax page - optional
p = root / r"lib\features\syntax\syntax_editor_page.dart"
t = p.read_text(encoding="utf-8")
t = t.replace("import 'package:flutter/services.dart';\n", "")
p.write_text(t, encoding="utf-8")
print("syntax page import")
