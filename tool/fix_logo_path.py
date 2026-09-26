import re
from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\docs\.vitepress\config.mts")
t = p.read_text(encoding="utf-8")
t = re.sub(r"logo: .*\n", "logo: '/logo.svg',\n", t, count=1)
p.write_text(t, encoding="utf-8")
for i, l in enumerate(t.splitlines(), 1):
    if "logo" in l:
        print(i, l)
print("ok")
