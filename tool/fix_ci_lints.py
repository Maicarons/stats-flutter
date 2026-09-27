import re
from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\lib\features\syntax\syntax_editor_page.dart")
t = p.read_text(encoding="utf-8")
t = re.sub(
    r"final path =\s*dir\.path \+ '/syntax_' \+ DateTime\.now\(\)\.millisecondsSinceEpoch\.toString\(\) \+ '\.sps';",
    "final path =\n        '\${dir.path}/syntax_\${DateTime.now().millisecondsSinceEpoch}.sps';",
    t,
)
t = t.replace(
    "dir.path + '/syntax_' + DateTime.now().millisecondsSinceEpoch.toString() + '.sps'",
    "'\${dir.path}/syntax_\${DateTime.now().millisecondsSinceEpoch}.sps'",
)
t = t.replace("Text('Saved: ' + path)", "Text('Saved: \$path')")
p.write_text(t, encoding="utf-8")
print("syntax")

p = Path(r"F:\workspace\stats-flutter\tool\test_sav.dart")
if p.exists():
    t = p.read_text(encoding="utf-8")
    if "ignore_for_file" not in t:
        p.write_text("// ignore_for_file: avoid_print\n" + t, encoding="utf-8")
    print("test_sav")

p = Path(r"F:\workspace\stats-flutter\analysis_options.yaml")
t = p.read_text(encoding="utf-8")
if "tool/" not in t:
    t = t.replace("    - docs/**", "    - docs/**\n    - tool/**")
    p.write_text(t, encoding="utf-8")
print("analysis_options")
