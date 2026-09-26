from pathlib import Path

# 1) Fix transform import path
p = Path(r"F:\workspace\stats-flutter\lib\features\data_editor\data_editor_page.dart")
t = p.read_text(encoding="utf-8")
t = t.replace(
    "import '../../transform/transform_page.dart';",
    "import '../transform/transform_page.dart';",
)
p.write_text(t, encoding="utf-8")
print("import fixed")

# 2) Insert runner impl if truly missing
p = Path(r"F:\workspace\stats-flutter\lib\features\analysis\analysis_runner.dart")
t = p.read_text(encoding="utf-8")
if "void _runMeans()" not in t:
    impl = Path(r"F:\workspace\stats-flutter\tool\runner_impl.dart.txt").read_text(encoding="utf-8")
    anchor = "  AnalysisReport _nonparamReport(NonparametricResult r) {"
    t = t.replace(anchor, impl + "\n" + anchor, 1)
    p.write_text(t, encoding="utf-8")
    print("impl inserted")
else:
    print("impl ok")
