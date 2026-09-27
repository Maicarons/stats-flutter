from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\lib\features\syntax\syntax_editor_page.dart")
t = p.read_text(encoding="utf-8")
t = t.replace("\\$", "$")
p.write_text(t, encoding="utf-8")
idx = t.find("_saveSyntax")
print(t[idx : idx + 280])
