from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\lib\features\home\home_shell.dart")
t = p.read_text(encoding="utf-8")
t = t.replace("l10n?.", "l10n.")
t = t.replace("final l10n = AppLocalizations.of(context);", "final l10n = AppLocalizations.of(context);")
# make l10n non-nullable usage
t = t.replace("l10n.tabData ?? '数据'", "l10n.tabData")
t = t.replace("l10n.tabAnalysis ?? '分析'", "l10n.tabAnalysis")
t = t.replace("l10n.tabLearn ?? '学习'", "l10n.tabLearn")
t = t.replace("l10n.tabQuiz ?? '测试'", "l10n.tabQuiz")
t = t.replace("l10n.tabSettings ?? '设置'", "l10n.tabSettings")
p.write_text(t, encoding="utf-8")

p = Path(r"F:\workspace\stats-flutter\lib\features\projects\project_list_page.dart")
t = p.read_text(encoding="utf-8")
t = t.replace("import '../../core/models/dataset.dart';\n", "")
p.write_text(t, encoding="utf-8")
print("cleaned")
