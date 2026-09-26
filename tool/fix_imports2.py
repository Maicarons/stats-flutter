from pathlib import Path

def rep(path, a, b, label):
    p = Path(path)
    t = p.read_text(encoding="utf-8")
    if a not in t:
        print("WARN", label, repr(a[:60]))
        return
    p.write_text(t.replace(a, b), encoding="utf-8")
    print("ok", label)

root = Path(r"F:\workspace\stats-flutter")

rep(
    root / r"lib\shared\project_store.dart",
    "import '../models/dataset.dart';",
    "import '../core/models/dataset.dart';",
    "ps dataset",
)
rep(
    root / r"lib\shared\project_store.dart",
    "import '../models/project.dart';",
    "import '../core/models/project.dart';",
    "ps project",
)
rep(
    root / r"lib\features\splash\splash_page.dart",
    "import '../shared/project_store.dart';",
    "import '../../shared/project_store.dart';",
    "splash store",
)

# project_list description null-safe
p = root / r"lib\features\projects\project_list_page.dart"
t = p.read_text(encoding="utf-8")
t = t.replace(
    "(m.description ?? '').toLowerCase().contains(q)",
    "(m.description ?? '').toLowerCase().contains(q)",
)
# maybe it's m.description.toLowerCase
t = t.replace(
    "m.description.toLowerCase()",
    "(m.description ?? '').toLowerCase()",
)
p.write_text(t, encoding="utf-8")
print("list desc")

# dataset_store import path
rep(
    root / r"lib\shared\dataset_store.dart",
    "import '../core/models/dataset.dart';",
    "import '../core/models/dataset.dart';",
    "ds dataset",
)

print("done")
