/// 主页：工程列表入口（仪表盘式概览 + 最近工程 + 全部工程）。
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/project.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/brand_logo.dart';
import '../../shared/dataset_store.dart';
import '../../shared/locale_util.dart';
import '../../shared/project_store.dart';
import '../../shared/ui/ui.dart';
import '../settings/about_page.dart';
import 'project_workspace_page.dart';

class ProjectListPage extends StatefulWidget {
  /// true: embedded in global shell
  final bool embedded;
  const ProjectListPage({super.key, this.embedded = true});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    projectStore.addListener(_onStore);
    _init();
  }

  Future<void> _init() async {
    await projectStore.load();
    if (mounted) setState(() {});
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    projectStore.removeListener(_onStore);
    _search.dispose();
    super.dispose();
  }

  List<ProjectMeta> get _filtered {
    final q = _query.toLowerCase();
    return projectStore.projects
        .where((m) =>
            q.isEmpty ||
            m.name.toLowerCase().contains(q) ||
            (m.description ?? '').toLowerCase().contains(q))
        .toList();
  }

  List<ProjectMeta> get _recents {
    final all = [...projectStore.projects]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final list = _filtered;
    final wide = AppBreakpoints.isMedium(context);
    final showRecents = _query.isEmpty && projectStore.projects.length > 3;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              AppLocalizations.of(context).appTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: l10n.about,
                icon: const Icon(Icons.info_outline),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AboutPage()),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: ConstrainedContent(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x1,
                AppSpacing.x4,
                AppSpacing.x2,
              ),
              child: _Hero(
                onDemo: () => _createDialog(demo: true),
                onBlank: () => _createDialog(demo: false),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ConstrainedContent(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x2,
                AppSpacing.x4,
                0,
              ),
              child: Row(
                children: [
                  StatChip(
                    icon: Icons.folder_outlined,
                    label: l10n.tabProjects,
                    value: '${projectStore.projects.length}',
                    color: scheme.primaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  if (projectStore.rootPath.isNotEmpty)
                    Expanded(
                      child: Tooltip(
                        message: projectStore.rootPath,
                        child: Text(
                          projectStore.rootPath,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showRecents) ...[
            SliverToBoxAdapter(
              child: ConstrainedContent(
                padding: EdgeInsets.zero,
                child: SectionHeader(
                  title: l10n.projRecent,
                  icon: Icons.history,
                  dense: true,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x4,
                  ),
                  itemCount: _recents.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.x3),
                  itemBuilder: (_, i) => _RecentCard(
                    meta: _recents[i],
                    onTap: () => _open(_recents[i]),
                  ),
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: ConstrainedContent(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x4,
                AppSpacing.x4,
                0,
              ),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: l10n.projSearchHint,
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
            ),
          ),
          SliverToBoxAdapter(
            child: ConstrainedContent(
              padding: const EdgeInsets.only(left: AppSpacing.x2),
              child: SectionHeader(
                title: _query.isEmpty ? l10n.projAll : l10n.projSearchHint,
                dense: true,
                trailing: Text(
                  l10n.projCount(projectStore.projects.length),
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          if (!projectStore.loaded)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.x4),
                child: SkeletonList(count: 4),
              ),
            )
          else if (list.isEmpty)
            SliverToBoxAdapter(
              child: ConstrainedContent(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.x5),
                  child: projectStore.projects.isEmpty
                      ? EmptyState(
                          icon: Icons.folder_open,
                          title: l10n.projEmptyTitle,
                          message: l10n.projEmptyMsg,
                          actionLabel: l10n.projNewDemo,
                          actionIcon: Icons.science_outlined,
                          onAction: () => _createDialog(demo: true),
                        )
                      : EmptyState(
                          icon: Icons.search_off,
                          title: l10n.projNoMatchTitle,
                          message: l10n.projNoMatchMsg,
                          compact: true,
                        ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x1,
                AppSpacing.x4,
                AppSpacing.x7 + AppSpacing.x5,
              ),
              sliver: _buildList(list, wide),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createDialog(demo: true),
        icon: const Icon(Icons.add),
        label: Text(l10n.projNewProject),
      ),
    );
  }

  Widget _buildList(List<ProjectMeta> list, bool wide) {
    if (wide) {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 460,
          mainAxisExtent: 96,
          mainAxisSpacing: AppSpacing.x3,
          crossAxisSpacing: AppSpacing.x3,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _ProjectCard(
            meta: list[i],
            onOpen: () => _open(list[i]),
            onMenu: (a) => _onMenu(a, list[i]),
          ),
          childCount: list.length,
        ),
      );
    }
    return SliverList.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x3),
      itemBuilder: (context, i) => _ProjectCard(
        meta: list[i],
        onOpen: () => _open(list[i]),
        onMenu: (a) => _onMenu(a, list[i]),
      ),
    );
  }

  Future<void> _createDialog({required bool demo}) async {
    final l10n = AppLocalizations.of(context);
    final zh = isZhUi(context);
    final nameCtrl = TextEditingController(
      text: demo
          ? l10n.projDemoName
          : l10n.projDefaultName(projectStore.projects.length + 1),
    );
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(demo ? l10n.projNewDemoTitle : l10n.projNewBlankTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.projNameField),
            ),
            const SizedBox(height: AppSpacing.x3),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(labelText: l10n.projDescField),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.projCreate),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final p = await projectStore.create(
      name: nameCtrl.text.trim().isEmpty
          ? l10n.projUntitled
          : nameCtrl.text.trim(),
      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      withDemo: demo,
      demoZh: zh,
    );
    if (!mounted) return;
    datasetStore.onProjectChanged();
    await _open(p.meta);
  }

  Future<void> _open(ProjectMeta meta) async {
    final l10n = AppLocalizations.of(context);
    final p = await projectStore.open(meta.id);
    if (!mounted) return;
    if (p == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.projOpenFailed)),
      );
      return;
    }
    datasetStore.onProjectChanged();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProjectWorkspacePage(project: p)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _onMenu(String action, ProjectMeta meta) async {
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case 'open':
        await _open(meta);
        break;
      case 'rename':
        final ctrl = TextEditingController(text: meta.name);
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.projRenameTitle),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.projNameLabel),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.save),
              ),
            ],
          ),
        );
        if (ok == true && ctrl.text.trim().isNotEmpty) {
          await projectStore.rename(meta.id, ctrl.text.trim());
        }
        break;
      case 'duplicate':
        await projectStore.duplicate(
          meta.id,
          l10n.projCopySuffix(meta.name),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.projDuplicated)),
          );
        }
        break;
      case 'delete':
        final ok = await showConfirmDialog(
          context,
          title: l10n.projDeleteTitle,
          message: l10n.projDeleteMsg(meta.name),
          confirmLabel: l10n.projDeleteAction,
          danger: true,
          icon: Icons.delete_outline,
        );
        if (ok) await projectStore.delete(meta.id);
        break;
    }
  }
}

class _Hero extends StatelessWidget {
  final VoidCallback onDemo;
  final VoidCallback onBlank;

  const _Hero({required this.onDemo, required this.onBlank});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4 + 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer,
            Color.lerp(scheme.primaryContainer, scheme.tertiaryContainer, 0.75)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.rXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.projHeroTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                ),
              ),
              BrandLogo(size: 40, onPrimary: true),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            l10n.projHeroDesc,
            style: TextStyle(
              fontSize: AppFontSize.bodySm,
              height: 1.55,
              color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Wrap(
            spacing: AppSpacing.x3,
            runSpacing: AppSpacing.x2,
            children: [
              FilledButton.icon(
                onPressed: onDemo,
                icon: const Icon(Icons.science_outlined, size: 18),
                label: Text(l10n.projNewDemo),
              ),
              OutlinedButton.icon(
                onPressed: onBlank,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.projNewBlank),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final ProjectMeta meta;
  final VoidCallback onTap;

  const _RecentCard({required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('MM-dd HH:mm');
    return SizedBox(
      width: 190,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: AppRadius.rSm,
              ),
              child: const BrandLogo(size: 34, onPrimary: true),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  meta.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fmt.format(meta.updatedAt),
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectMeta meta;
  final VoidCallback onOpen;
  final ValueChanged<String> onMenu;

  const _ProjectCard({
    required this.meta,
    required this.onOpen,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final fmt = DateFormat('yyyy-MM-dd HH:mm');

    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(AppSpacing.x3 + 2),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: AppRadius.rMd,
            ),
            child: const BrandLogo(size: 48, onPrimary: true),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  meta.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.casesByVarsShort(meta.nCases, meta.nVars),
                  style: TextStyle(
                    fontSize: AppFontSize.bodySm,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  l10n.projUpdatedAt(fmt.format(meta.updatedAt)),
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.settings,
            onSelected: onMenu,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'open',
                child: _menuRow(Icons.folder_open, l10n.projOpen),
              ),
              PopupMenuItem(
                value: 'rename',
                child: _menuRow(Icons.edit_outlined, l10n.projRenameTitle),
              ),
              PopupMenuItem(
                value: 'duplicate',
                child: _menuRow(Icons.copy_all_outlined, l10n.projDuplicate),
              ),
              PopupMenuItem(
                value: 'delete',
                child: _menuRow(
                  Icons.delete_outline,
                  l10n.projDeleteAction,
                  color: scheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.x3),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
