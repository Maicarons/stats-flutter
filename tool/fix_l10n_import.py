from pathlib import Path

root = Path(r"F:\workspace\stats-flutter")
old = "package:flutter_gen/gen_l10n/app_localizations.dart"
new = "package:stats_flutter/l10n/app_localizations.dart"

for p in root.rglob("*.dart"):
    s = str(p)
    if "_ref" in s or "\\packages\\" in s or "/packages/" in s:
        continue
    t = p.read_text(encoding="utf-8")
    if old in t:
        p.write_text(t.replace(old, new), encoding="utf-8")
        print("fixed", p)
print("done")
