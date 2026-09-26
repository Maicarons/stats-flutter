from pathlib import Path

root = Path(r"F:\workspace\stats-flutter\lib")
for p in root.rglob("*.dart"):
    t = p.read_text(encoding="utf-8")
    if "AppLocalizations.of(context)!" in t:
        t = t.replace("AppLocalizations.of(context)!", "AppLocalizations.of(context)")
        p.write_text(t, encoding="utf-8")
        print("fixed", p.name)

p = root / "main.dart"
t = p.read_text(encoding="utf-8")
t = t.replace("import 'shared/dataset_store.dart';\n", "")
p.write_text(t, encoding="utf-8")
print("cleaned main")
