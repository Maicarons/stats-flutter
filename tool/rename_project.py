from pathlib import Path

root = Path(r"F:\workspace\stats-flutter")

# Android label
p = root / r"android\app\src\main\AndroidManifest.xml"
t = p.read_text(encoding="utf-8")
t = t.replace('android:label="StatLab"', 'android:label="Stats-flutter"')
p.write_text(t, encoding="utf-8")

# iOS
p = root / r"ios\Runner\Info.plist"
t = p.read_text(encoding="utf-8")
t = t.replace("<string>StatLab</string>", "<string>Stats-flutter</string>")
p.write_text(t, encoding="utf-8")

# macOS
p = root / r"macos\Runner\Configs\AppInfo.xcconfig"
t = p.read_text(encoding="utf-8")
t = t.replace("PRODUCT_NAME = StatLab", "PRODUCT_NAME = Stats-flutter")
p.write_text(t, encoding="utf-8")

# Windows rc
p = root / r"windows\runner\Runner.rc"
t = p.read_text(encoding="utf-8")
t = t.replace('"StatLab"', '"Stats-flutter"')
p.write_text(t, encoding="utf-8")

# Windows main.cpp window title if present
p = root / r"windows\runner\main.cpp"
if p.exists():
    t = p.read_text(encoding="utf-8")
    t = t.replace("StatLab", "Stats-flutter").replace("stats_flutter", "Stats-flutter")
    p.write_text(t, encoding="utf-8")

# pubspec description
p = root / "pubspec.yaml"
t = p.read_text(encoding="utf-8")
t = t.replace(
    'description: "StatLab — 移动优先的统计分析套件，灵感来自 GNU PSPP，含学习与测试模块。"',
    'description: "Stats-flutter — 移动优先的统计分析套件，灵感来自 GNU PSPP，含学习与测试模块。"',
)
p.write_text(t, encoding="utf-8")

print("renamed")
