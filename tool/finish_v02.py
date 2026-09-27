from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\packages\statkit\lib\src\weights.dart")
t = p.read_text(encoding="utf-8")
for imp in ["import 'descriptives.dart';\n", "import 'regression.dart';\n"]:
    t = t.replace(imp, "")
p.write_text(t, encoding="utf-8")
print("weights cleaned")

p = Path(r"F:\workspace\stats-flutter\lib\features\analysis\analysis_runner.dart")
t = p.read_text(encoding="utf-8")
old = """    final map = <String, Descriptives>{};
    for (final name in _selectedVars) {
      map[name] = Descriptives.compute(ds.numericColumn(name));
    }
    if (map.isEmpty) throw '请至少选择一个变量';
    _report = reportDescriptives(map, datasetName: ds.name);"""
new = """    final map = <String, Descriptives>{};
    for (final name in _selectedVars) {
      map[name] = Descriptives.compute(ds.numericColumn(name));
    }
    if (map.isEmpty) throw '请至少选择一个变量';
    _report = reportDescriptives(map, datasetName: ds.name);
    final wName = ds.weightVariable;
    if (wName != null && wName.isNotEmpty) {
      final w = ds.numericColumn(wName);
      final notes = StringBuffer('WEIGHT CASES: ');
      notes.writeln(wName);
      for (final name in _selectedVars) {
        final v = ds.numericColumn(name);
        final ww = WeightedDescriptives.compute(v, w);
        notes.writeln(
            '\$name  weighted mean=\${ww.mean.toStringAsFixed(4)}  N_w=\${ww.nWeighted}');
      }
      final prev = _report!;
      _report = AnalysisReport(
        title: prev.title,
        subtitle: prev.subtitle,
        sections: [
          ...prev.sections,
          ReportSection(heading: 'WEIGHT CASES', body: notes.toString()),
        ],
      );
    }"""
if old in t:
    t = t.replace(old, new)
    print("analysis weight note")
else:
    print("analysis anchor miss")
p.write_text(t, encoding="utf-8")

# ROADMAP mark v0.2
p = Path(r"F:\workspace\stats-flutter\docs\ROADMAP.md")
t = p.read_text(encoding="utf-8")
t = t.replace(
    "### v0.2.0 — 权重与语义补全（statkit）",
    "### v0.2.0 — 权重与语义补全（statkit）✅ 已完成",
)
p.write_text(t, encoding="utf-8")
print("roadmap")
print("done")
