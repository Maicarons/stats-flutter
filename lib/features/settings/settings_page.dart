import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import 'about_page.dart';

import '../../core/app_info.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/app_settings.dart';
import '../../shared/dataset_store.dart';
import '../../shared/project_store.dart';
import '../../shared/ui/ui.dart';

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
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
      body: ListenableBuilder(
        listenable: Listenable.merge([appSettings, datasetStore, projectStore]),
        builder: (context, _) {
          return ConstrainedContent(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
            child: ListView(
              padding: const EdgeInsets.only(
                top: AppSpacing.x3,
                bottom: AppSpacing.x6,
              ),
              children: [
                _SectionCard(
                  title: l10n.appearance,
                  icon: Icons.palette_outlined,
                  children: [
                    _SettingsTile(
                      icon: Icons.brightness_6_outlined,
                      title: l10n.themeMode,
                      trailing: Wrap(
                        spacing: AppSpacing.x1 + 2,
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
                    const SizedBox(height: AppSpacing.x2),
                    _SettingsTile(
                      icon: Icons.color_lens_outlined,
                      title: l10n.themeColor,
                      trailing: SizedBox(
                        width: 210,
                        child: Wrap(
                          spacing: AppSpacing.x2,
                          runSpacing: AppSpacing.x2,
                          alignment: WrapAlignment.end,
                          children: [
                            for (final c in AppSettings.presetColors)
                              _Swatch(
                                color: c,
                                selected: appSettings.seedColor == c,
                                onTap: () => appSettings.setSeedColor(c),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x3),
                _SectionCard(
                  title: l10n.language,
                  icon: Icons.translate,
                  children: [
                    _SettingsTile(
                      icon: Icons.language,
                      title: l10n.language,
                      trailing: Wrap(
                        spacing: AppSpacing.x1 + 2,
                        children: [
                          for (final (code, label) in [
                            ('system', l10n.langSystem),
                            ('en', l10n.langEnglish),
                            ('zh', l10n.langChinese),
                          ])
                            ChoiceChip(
                              label: Text(label),
                              selected:
                                  (appSettings.locale?.languageCode ??
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
                const SizedBox(height: AppSpacing.x3),
                _SectionCard(
                  title: l10n.stCurrentDataset,
                  icon: Icons.dataset_outlined,
                  children: [
                    const SizedBox(height: AppSpacing.x1),
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            icon: Icons.table_rows_outlined,
                            label: l10n.cases,
                            value: '${datasetStore.data.nCases}',
                            onTap: null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        Expanded(
                          child: StatTile(
                            icon: Icons.view_column_outlined,
                            label: l10n.variables,
                            value: '${datasetStore.data.nVars}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.folder_outlined, size: 20),
                      title: Text(
                        l10n.stStorage,
                        style: const TextStyle(
                          fontSize: AppFontSize.bodySm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        projectStore.rootPath.isEmpty
                            ? '—'
                            : projectStore.rootPath,
                        style: const TextStyle(fontSize: AppFontSize.caption),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: l10n.copy,
                        icon: const Icon(Icons.copy_all_outlined, size: 18),
                        onPressed: projectStore.rootPath.isEmpty
                            ? null
                            : () async {
                                await Clipboard.setData(
                                  ClipboardData(text: projectStore.rootPath),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.copiedToClipboard),
                                    duration:
                                        const Duration(milliseconds: 1200),
                                  ),
                                );
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x3),
                _SectionCard(
                  title: l10n.about,
                  icon: Icons.info_outline,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.auto_stories_outlined),
                      title: Text(l10n.aboutTitle),
                      subtitle: Text(
                        l10n.aboutDesc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutPage()),
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.verified_outlined),
                      title: Text(l10n.version),
                      trailing: Text(
                        AppInfo.version,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
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
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmReset(
      BuildContext context, AppLocalizations l10n) async {
    final ok = await showConfirmDialog(
      context,
      title: l10n.reset,
      message: l10n.resetConfirm,
      confirmLabel: l10n.ok,
      icon: Icons.restore,
      danger: true,
    );
    if (!ok) return;
    await appSettings.reset();
    datasetStore.resetDemo();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resetDone)),
      );
    }
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.onSurface : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x3,
        AppSpacing.x4,
        AppSpacing.x3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.x2),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x1),
          ...children,
        ],
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1 + 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.x3),
          Text(title),
          const SizedBox(width: AppSpacing.x3),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}
