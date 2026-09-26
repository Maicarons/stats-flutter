from pathlib import Path

# Splash: use BrandLogo
p = Path(r"F:\workspace\stats-flutter\lib\features\splash\splash_page.dart")
t = p.read_text(encoding="utf-8")

# replace logo container with BrandLogo
import re
t2 = re.sub(
    r"// Logo\n.*?child: CustomPaint\(painter: _LogoPainter\(\)\),\n              \),",
    "// Logo\n                const BrandLogo(size: 112, onPrimary: true),",
    t,
    count=1,
    flags=re.S,
)
if t2 == t:
    # try simpler replace
    start = t.find("// Logo")
    end = t.find("_LogoPainter")
    print("logo region", start, end)
else:
    t = t2
    print("splash logo replaced")

if "brand_logo.dart" not in t:
    t = t.replace(
        "import '../home/home_shell.dart';",
        "import '../../shared/brand_logo.dart';\nimport '../home/home_shell.dart';",
    )

# remove _LogoPainter class if present
idx = t.find("class _LogoPainter")
if idx > 0:
    t = t[:idx].rstrip() + "\n"
    print("removed painter")

p.write_text(t, encoding="utf-8")
print("splash done")

# About page: replace icon container
p = Path(r"F:\workspace\stats-flutter\lib\features\settings\about_page.dart")
t = p.read_text(encoding="utf-8")
old = """        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.bar_chart, color: Colors.white, size: 48),
          ),
        ),"""
new = """        Center(
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const BrandLogo(size: 104, onPrimary: true),
          ),
        ),"""
if old in t:
    t = t.replace(old, new)
    print("about icon")
else:
    print("about anchor miss")

if "brand_logo.dart" not in t:
    t = t.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\n\nimport '../../shared/brand_logo.dart';",
    )
p.write_text(t, encoding="utf-8")

print("done")
