/// 分析中心：搜索 + 最近 + 收藏 + 可折叠分类。
library;

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/theme/design_tokens.dart';
import '../../shared/analysis_prefs.dart';
import '../../shared/ui/ui.dart';
import 'analysis_catalog.dart';
import 'analysis_runner.dart';

class AnalysisHub extends StatefulWidget {
  final bool embedded;
  const AnalysisHub({super.key, this.embedded = true});

  @override
  State<AnalysisHub> createState() => _AnalysisHubState();
}

class _AnalysisHubState extends State<AnalysisHub> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    analysisPrefs.addListener(_onPrefs);
    analysisPrefs.load();
  }

  void _onPrefs() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    analysisPrefs.removeListener(_onPrefs);
    _search.dispose();
    super.dispose();
  }

  List<AnalysisItem> get _matches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final l10n = AppLocalizations.of(context);
    final out = <AnalysisItem>[];
    for (final c in analysisCatalog) {
      for (final it in c.items) {
        if (it.title(l10n).toLowerCase().contains(q) ||
            it.desc(l10n).toLowerCase().contains(q) ||
            it.id.contains(q)) {
          out.add(it);
        }
      }
    }
    return out;
  }

  Future<void> _open(AnalysisItem item) async {
    await analysisPrefs.markUsed(item.id);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisRunner(
          analysisId: item.id,
          title: item.title(l10n),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final searching = _query.trim().isNotEmpty;
    final matches = _matches;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(
                l10n.tabAnalysis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      body: ConstrainedContent(
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x4,
            AppSpacing.x3,
            AppSpacing.x4,
            AppSpacing.x6,
          ),
          children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.anSearchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.cancel,
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.x3),
            if (searching)
              ..._buildSearchResults(matches)
            else ...[
              ..._buildQuickSections(l10n),
              for (var i = 0; i < analysisCatalog.length; i++)
                _CategorySection(
                  category: analysisCatalog[i],
                  initiallyExpanded: i == 0,
                  onTap: _open,
                  onToggleFavorite: (id) => analysisPrefs.toggleFavorite(id),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSearchResults(List<AnalysisItem> matches) {
    final l10n = AppLocalizations.of(context);
    if (matches.isEmpty) {
      return [
        const SizedBox(height: AppSpacing.x5),
        EmptyState(
          icon: Icons.search_off,
          title: l10n.anNoMatch,
          message: l10n.projNoMatchMsg,
          compact: true,
        ),
      ];
    }
    return [
      SectionHeader(
        title: l10n.anResults,
        dense: true,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x1,
          AppSpacing.x2,
          AppSpacing.x1,
          AppSpacing.x2,
        ),
        trailing: Text(
          '${matches.length}',
          style: TextStyle(
            fontSize: AppFontSize.caption,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      for (final it in matches)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.x2),
          child: AnalysisTile(
            title: it.title(l10n),
            description: it.desc(l10n),
            icon: it.icon,
            compact: true,
            favorite: analysisPrefs.isFavorite(it.id),
            onToggleFavorite: () => analysisPrefs.toggleFavorite(it.id),
            onTap: () => _open(it),
          ),
        ),
    ];
  }

  List<Widget> _buildQuickSections(AppLocalizations l10n) {
    final recents = analysisPrefs.recents
        .map(analysisById)
        .whereType<AnalysisItem>()
        .toList();
    final favs = analysisPrefs.favorites
        .map(analysisById)
        .whereType<AnalysisItem>()
        .toList();

    return [
      if (recents.isNotEmpty) ...[
        SectionHeader(
          title: l10n.anRecent,
          icon: Icons.history,
          dense: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x1,
            AppSpacing.x2,
            AppSpacing.x1,
            AppSpacing.x2,
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recents.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.x2),
            itemBuilder: (_, i) => ActionChip(
              avatar: Icon(recents[i].icon, size: 16),
              label: Text(recents[i].title(l10n)),
              onPressed: () => _open(recents[i]),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
      ],
      if (favs.isNotEmpty) ...[
        SectionHeader(
          title: l10n.anFavorites,
          icon: Icons.star_rounded,
          dense: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x1,
            AppSpacing.x1,
            AppSpacing.x1,
            AppSpacing.x2,
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: favs.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.x2),
            itemBuilder: (_, i) => ActionChip(
              avatar: Icon(favs[i].icon, size: 16),
              label: Text(favs[i].title(l10n)),
              onPressed: () => _open(favs[i]),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
      ],
    ];
  }
}

class _CategorySection extends StatelessWidget {
  final AnalysisCategory category;
  final bool initiallyExpanded;
  final void Function(AnalysisItem) onTap;
  final void Function(String) onToggleFavorite;

  const _CategorySection({
    required this.category,
    required this.initiallyExpanded,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.x1),
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.x2),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(category.icon, size: 20, color: scheme.primary),
        title: Text(
          category.title(l10n),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${category.items.length}',
          style: TextStyle(
            fontSize: AppFontSize.caption,
            color: scheme.onSurfaceVariant,
          ),
        ),
        children: [
          for (final it in category.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x2),
              child: AnalysisTile(
                title: it.title(l10n),
                description: it.desc(l10n),
                icon: it.icon,
                badge: it.advanced ? l10n.anAdvanced : null,
                favorite: analysisPrefs.isFavorite(it.id),
                onToggleFavorite: () => onToggleFavorite(it.id),
                onTap: () => onTap(it),
              ),
            ),
        ],
      ),
    );
  }
}
