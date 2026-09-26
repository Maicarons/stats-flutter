from pathlib import Path

for f in [
    r"F:\workspace\stats-flutter\lib\l10n\app_en.arb",
    r"F:\workspace\stats-flutter\lib\l10n\app_zh.arb",
]:
    p = Path(f)
    t = p.read_text(encoding="utf-8")
    t = t.replace('"appTitle": "StatLab"', '"appTitle": "Stats-flutter"')
    p.write_text(t, encoding="utf-8")
print("l10n ok")

p = Path(r"F:\workspace\stats-flutter\README.md")
t = p.read_text(encoding="utf-8")
t = t.replace("# StatLab（stats-flutter）", "# Stats-flutter").replace(
    "# StatLab", "# Stats-flutter"
)
lines = t.splitlines()
if "Stats-flutter" not in lines[0]:
    t = "# Stats-flutter\n\n" + t
p.write_text(t, encoding="utf-8")
print("readme ok")
