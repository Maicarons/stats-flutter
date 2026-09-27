from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\packages\statkit\lib\src\factor_advanced.dart")
t = p.read_text(encoding="utf-8")
if "distributions.dart" not in t:
    t = t.replace(
        "import 'correlation.dart';",
        "import 'correlation.dart';\nimport 'distributions.dart';",
    )
t = t.replace(
    "final df = p * (p - 1) ~/ 2;",
    "final df = (p * (p - 1) / 2).toDouble();",
)
t = t.replace("  final r = base.correlation;\n", "")
p.write_text(t, encoding="utf-8")
print("factor ok")

p = Path(r"F:\workspace\stats-flutter\packages\statkit\lib\src\examine.dart")
t = p.read_text(encoding="utf-8")
t = t.replace("  final d = Descriptives.compute(v);\n  final out = <QQPoint>[];", "  final out = <QQPoint>[];")
t = t.replace("W2", "w2")
p.write_text(t, encoding="utf-8")
print("examine ok")
