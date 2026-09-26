import re
from pathlib import Path

PAGES = "https://maicarons.github.io/stats-flutter/"
REPO = "https://github.com/Maicarons/stats-flutter"

# Update homepage links in README, about content, app settings
files = [
    Path(r"F:\workspace\stats-flutter\README.md"),
    Path(r"F:\workspace\stats-flutter\README_zh.md"),
    Path(r"F:\workspace\stats-flutter\assets\content\README.en.md"),
    Path(r"F:\workspace\stats-flutter\assets\content\README.zh.md"),
]

for p in files:
    if not p.exists():
        continue
    t = p.read_text(encoding="utf-8")
    # point docs link to Pages if still saying docs/ locally only - add if missing
    if "maicarons.github.io/stats-flutter" not in t:
        # insert after first heading block
        lines = t.splitlines()
        for i, l in enumerate(lines):
            if l.startswith("**GitHub**") or "github.com/Maicarons/stats-flutter" in l and i < 15:
                lines.insert(i + 1, f"\n**Docs site:** {PAGES}\n")
                break
        t = "\n".join(lines) + "\n"
        p.write_text(t, encoding="utf-8")
        print("added pages link", p.name)
    else:
        print("has pages link", p.name)

# about_page local docs hint -> Pages
p = Path(r"F:\workspace\stats-flutter\lib\features\settings\about_page.dart")
t = p.read_text(encoding="utf-8")
t = t.replace(
    "subtitle: const Text('docs/ · VitePress 中英双语'),",
    "subtitle: const Text('https://maicarons.github.io/stats-flutter/'),",
)
t = t.replace(
    "content: Text('请在仓库 docs/ 目录运行 npm run docs:dev'),",
    "content: Text('文档站：https://maicarons.github.io/stats-flutter/'),",
)
p.write_text(t, encoding="utf-8")
print("about page link")

print("done")
