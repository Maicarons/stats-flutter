from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\packages\statkit\lib\src\glm.dart")
lines = p.read_text(encoding="utf-8").splitlines()
# delete lines 194-196 (1-indexed) = index 193-195
del lines[193:196]
# also remove unused import descriptives
out = []
for l in lines:
    if l.strip() == "import 'descriptives.dart';":
        continue
    out.append(l)
p.write_text("\n".join(out) + "\n", encoding="utf-8")
print("glm cleaned")

p = Path(r"F:\workspace\stats-flutter\packages\statkit\lib\src\logistic_full.dart")
t = p.read_text(encoding="utf-8")
t = t.replace(
    "final labels = ['(Constant)', ...?names ?? [for (var j = 0; j < p; j++) 'X${j + 1}']];",
    "final nameList = (names != null && names.length == p)\n      ? names!\n      : [for (var j = 0; j < p; j++) 'X${j + 1}'];\n  final labels = ['(Constant)', ...nameList];",
)
p.write_text(t, encoding="utf-8")
print("logistic names")
