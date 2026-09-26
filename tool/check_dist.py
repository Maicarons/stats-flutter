import re
from pathlib import Path

idx = Path(r"F:\workspace\stats-flutter\docs\.vitepress\dist\index.html")
t = idx.read_text(encoding="utf-8")
for m in re.findall(r'(href|src)="([^"]+)"', t)[:25]:
    print(m)
print("---")
# check css asset path inside
for p in Path(r"F:\workspace\stats-flutter\docs\.vitepress\dist\assets").glob("*.html"):
    print("html in assets", p)
print("dist ok")
