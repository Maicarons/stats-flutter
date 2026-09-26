from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\lib\features\data_editor\data_editor_page.dart")
t = p.read_text(encoding="utf-8")
t = t.replace("\\${e.key}", "${e.key}")
t = t.replace("\\${e.value}", "${e.value}")
p.write_text(t, encoding="utf-8")
for i, l in enumerate(t.splitlines(), 1):
    if "e.key" in l and "Text(" in l:
        print(i, l.strip())
print("done")
