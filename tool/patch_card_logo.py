from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\lib\features\projects\project_list_page.dart")
t = p.read_text(encoding="utf-8")
old = """              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.table_chart,
                    color: Colors.white, size: 24),
              ),"""
new = """              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const BrandLogo(size: 48, onPrimary: true),
              ),"""
if old in t:
    t = t.replace(old, new)
    print("card logo")
else:
    print("card miss")

if "brand_logo.dart" not in t:
    t = t.replace(
        "import 'project_workspace_page.dart';",
        "import '../../shared/brand_logo.dart';\nimport 'project_workspace_page.dart';",
    )
    print("import")
p.write_text(t, encoding="utf-8")
print("done")
