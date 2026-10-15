/// 关于页：信息 + 双语 README。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/app_info.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/brand_logo.dart';
import '../../shared/ui/ui.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  static const String _docsUrl = 'https://maicarons.github.io/stats-flutter/';

  late final TabController _tab;
  String _zh = '';
  String _en = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context);
    try {
      final zh = await rootBundle.loadString('assets/content/README.zh.md');
      final en = await rootBundle.loadString('assets/content/README.en.md');
      if (!mounted) return;
      setState(() {
        _zh = zh;
        _en = en;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _zh = l10n.abReadmeFailed('$e');
        _en = l10n.abReadmeFailed('$e');
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.about,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: l10n.abInfoTab),
            Tab(text: l10n.abReadmeZh),
            Tab(text: l10n.abReadmeEn),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildInfo(context, l10n),
          _buildReadme(_zh, l10n),
          _buildReadme(_en, l10n),
        ],
      ),
    );
  }

  Widget _buildInfo(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ConstrainedContent(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
      child: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.x5,
          bottom: AppSpacing.x6,
        ),
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                boxShadow: context.appColors.shadowMd,
              ),
              child: const BrandLogo(size: 96, onPrimary: true),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Center(
            child: Text(
              AppInfo.name,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              '${l10n.version} ${AppInfo.version}',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: AppFontSize.bodySm,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l10n.abIntroTitle),
                  subtitle: Text(
                    l10n.abIntroBody,
                    style: const TextStyle(height: 1.5),
                  ),
                  isThreeLine: true,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(l10n.abDocs),
                  subtitle: const Text(_docsUrl),
                  trailing: IconButton(
                    tooltip: l10n.copy,
                    icon: const Icon(Icons.copy_all_outlined, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(
                        const ClipboardData(text: _docsUrl),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.copiedToClipboard),
                          duration: const Duration(milliseconds: 1200),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.balance_outlined),
                  title: Text(l10n.abLicense),
                  subtitle: Text(l10n.abLicenseValue),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.favorite_outline,
                      color: Colors.redAccent),
                  title: Text(l10n.abStack),
                  subtitle: Text(l10n.abStackValue),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.memory, size: 18, color: scheme.primary),
                    const SizedBox(width: AppSpacing.x2),
                    Text(
                      l10n.abRuntime,
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x2),
                for (final line in [
                  l10n.abPlatform,
                  l10n.abKernel,
                  l10n.abUiLang,
                  l10n.abTheme,
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '· $line',
                      style: TextStyle(
                        fontSize: AppFontSize.bodySm,
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadme(String content, AppLocalizations l10n) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.x4),
        child: SkeletonList(count: 6),
      );
    }
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: SelectableText(
          content,
          style: const TextStyle(fontSize: 13.5, height: 1.6),
        ),
      ),
    );
  }
}
