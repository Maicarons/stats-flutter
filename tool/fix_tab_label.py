from pathlib import Path

# ARB
p = Path(r"F:\workspace\stats-flutter\lib\l10n\app_en.arb")
t = p.read_text(encoding="utf-8")
if "tabProjects" not in t:
    t = t.replace('"tabData": "Data",', '"tabData": "Data",\n  "tabProjects": "Projects",')
    p.write_text(t, encoding="utf-8")
    print("en arb")

p = Path(r"F:\workspace\stats-flutter\lib\l10n\app_zh.arb")
t = p.read_text(encoding="utf-8")
if "tabProjects" not in t:
    t = t.replace('"tabData": "数据",', '"tabData": "数据",\n  "tabProjects": "工程",')
    p.write_text(t, encoding="utf-8")
    print("zh arb")

# home label
p = Path(r"F:\workspace\stats-flutter\lib\features\home\home_shell.dart")
t = p.read_text(encoding="utf-8")
t = t.replace(
    "label: l10n.tabData == '数据' ? '工程' : 'Projects',",
    "label: l10n.tabProjects,",
)
p.write_text(t, encoding="utf-8")
print("home label")

print("done")
