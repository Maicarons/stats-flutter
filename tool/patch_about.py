from pathlib import Path

# settings about -> AboutPage
p = Path(r"F:\workspace\stats-flutter\lib\features\settings\settings_page.dart")
t = p.read_text(encoding="utf-8")
if "about_page.dart" not in t:
    t = t.replace(
        "import 'package:flutter_gen/gen_l10n/app_localizations.dart';",
        "import 'package:flutter_gen/gen_l10n/app_localizations.dart';\n\nimport 'about_page.dart';",
    )
# also handle the new import path
if "about_page.dart" not in t:
    t = t.replace(
        "import 'package:stats_flutter/l10n/app_localizations.dart';",
        "import 'package:stats_flutter/l10n/app_localizations.dart';\n\nimport 'about_page.dart';",
    )

t = t.replace(
    """                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.aboutTitle),
                    subtitle: Text(l10n.aboutDesc),
                  ),""",
    """                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.aboutTitle),
                    subtitle: Text(l10n.aboutDesc),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutPage()),
                      );
                    },
                  ),""",
)
p.write_text(t, encoding="utf-8")
print("settings about linked")
