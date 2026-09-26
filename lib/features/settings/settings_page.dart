import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import 'about_page.dart';

import '../../shared/app_settings.dart';
import '../../shared/dataset_store.dart';

class SettingsPage extends StatelessWidget {
  final bool embedded;
  const SettingsPage({super.key, this.embedded = true});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: Text(l10n.settings,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
      body: ListenableBuilder(
        listenable: Listenable.merge([appSettings, datasetStore]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _SectionCard(
                title: l10n.appearance,
                children: [
                  _SettingsTile(
                    icon: Icons.brightness_6_outlined,
                    title: l10n.themeMode,
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        for (final (mode, label) in [
                          (ThemeMode.system, l10n.themeSystem),
                          (ThemeMode.light, l10n.themeLight),
                          (ThemeMode.dark, l10n.themeDark),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: appSettings.themeMode == mode,
                            onSelected: (_) => appSettings.setThemeMode(mode),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    title: l10n.themeColor,
                    trailing: SizedBox(
                      width: 200,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          for (final c in AppSettings.presetColors)
                            GestureDetector(
                              onTap: () => appSettings.setSeedColor(c),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: appSettings.seedColor == c
                                        ? scheme.onSurface
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                child: appSettings.seedColor == c
                                    ? const Icon(Icons.check,
                                        size: 16, color: Colors.white)
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: l10n.language,
                children: [
                  _SettingsTile(
                    icon: Icons.language,
                    title: l10n.language,
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        for (final (code, label) in [
                          ('system', l10n.langSystem),
                          ('en', l10n.langEnglish),
                          ('zh', l10n.langChinese),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: (appSettings.locale?.languageCode ??
                                    'system') ==
                                code,
                            onSelected: (_) => appSettings.setLocale(
                              code == 'system' ? null : Locale(code),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: l10n.about,
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.aboutTitle),
                    subtitle: Text(l10n.aboutDesc),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.verified_outlined),
                    title: Text(l10n.version),
                    trailing: const Text('1.0.0+1'),
                  ),
                  ListTile(
                    leading: Icon(Icons.restore, color: scheme.error),
                    title: Text(
                      l10n.reset,
                      style: TextStyle(color: scheme.error),
                    ),
                    onTap: () => _confirmReset(context, l10n),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmReset(
      BuildContext context, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reset),
        content: Text(l10n.resetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await appSettings.reset();
    datasetStore.resetDemo();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resetDone)),
      );
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 10),
          Text(title),
          const SizedBox(width: 12),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}
