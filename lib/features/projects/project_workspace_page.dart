/// 工程工作区：数据 / 分析 / 变换。
/// 窄屏底部导航，宽屏侧栏；标题区含自动保存状态。
library;

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/project.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/dataset_store.dart';
import '../../shared/locale_util.dart';
import '../../shared/project_store.dart';
import '../../shared/ui/ui.dart';
import '../analysis/analysis_hub.dart';
import '../data_editor/csv_io.dart';
import '../data_editor/data_editor_page.dart';
import '../data_editor/excel_io.dart';
import '../data_editor/sav_import.dart';
import '../transform/transform_page.dart';

class ProjectWorkspacePage extends StatefulWidget {
  final Project project;
  const ProjectWorkspacePage({super.key, required this.project});

  @override
  State<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState extends State<ProjectWorkspacePage> {
  int _index = 0;

  Project get project => widget.project;

  Future<void> _importMenu() async {
    final l10n = AppLocalizations.of(context);
    final v = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x1,
                AppSpacing.x4,
                AppSpacing.x2,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.importDataTitle,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.file_open),
              title: Text(l10n.importCsv),
              onTap: () => Navigator.pop(ctx, 'csv'),
            ),
            ListTile(
              leading: const Icon(Icons.grid_on),
              title: Text(l10n.importExcel),
              onTap: () => Navigator.pop(ctx, 'excel'),
            ),
            ListTile(
              leading: const Icon(Icons.table_rows),
              title: Text(l10n.importSav),
              onTap: () => Navigator.pop(ctx, 'sav'),
            ),
            ListTile(
              leading: const Icon(Icons.stairs),
              title: Text(l10n.importDta),
              onTap: () => Navigator.pop(ctx, 'dta'),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.importOds),
              onTap: () => Navigator.pop(ctx, 'ods'),
            ),
            ListTile(
              leading: const Icon(Icons.science),
              title: Text(l10n.importDemoData),
              onTap: () => Navigator.pop(ctx, 'demo'),
            ),
            const SizedBox(height: AppSpacing.x2),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (v == 'csv') {
      await importCsvInteractive(context, l10n);
    } else if (v == 'excel') {
      await importExcelInteractive(context, l10n);
    } else if (v == 'sav') {
      await importSavInteractive(context);
    } else if (v == 'dta') {
      await importDtaInteractive(context);
    } else if (v == 'ods') {
      await importOdsInteractive(context);
    } else if (v == 'demo') {
      datasetStore.resetDemo(zh: isZhUi(context));
    }
    if (mounted) setState(() {});
  }

  Future<void> _export() async {
    await exportCsvInteractive(context, AppLocalizations.of(context));
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    await projectStore.saveCurrent();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).projectSaved),
        duration: const Duration(milliseconds: 1200),
      ),
    );
    setState(() {});
  }

  Future<void> _exit() async {
    await projectStore.saveCurrent();
    if (!mounted) return;
    projectStore.closeCurrent();
    Navigator.of(context).pop();
  }

  Future<void> _onMenu(String v) async {
    switch (v) {
      case 'export':
        await _export();
        break;
      case 'save':
        await _save();
        break;
      case 'close':
        await _exit();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: projectStore,
      builder: (context, _) => AdaptiveNavScaffold(
        index: _index,
        onIndexChanged: (i) => setState(() => _index = i),
        items: [
          NavItem(
            icon: Icons.table_chart_outlined,
            selectedIcon: Icons.table_chart,
            label: l10n.tabData,
          ),
          NavItem(
            icon: Icons.analytics_outlined,
            selectedIcon: Icons.analytics,
            label: l10n.analysis,
          ),
          NavItem(
            icon: Icons.transform_outlined,
            selectedIcon: Icons.transform,
            label: l10n.tabTransform,
          ),
        ],
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.saveAndBack,
            icon: const Icon(Icons.arrow_back),
            onPressed: _exit,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                project.meta.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Text(
                      l10n.casesByVarsShort(
                        project.dataset.nCases,
                        project.dataset.nVars,
                      ),
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    _SavePill(
                      dirty: projectStore.dirty,
                      savedAt: projectStore.lastSavedAt,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: l10n.importCsvSav,
              icon: const Icon(Icons.file_open),
              onPressed: _importMenu,
            ),
            IconButton(
              tooltip: l10n.saveProject,
              icon: const Icon(Icons.save_outlined),
              onPressed: _save,
            ),
            PopupMenuButton<String>(
              tooltip: l10n.settings,
              onSelected: _onMenu,
              itemBuilder: (_) => [
                PopupMenuItem(value: 'export', child: Text(l10n.exportData)),
                PopupMenuItem(value: 'save', child: Text(l10n.saveProject)),
                PopupMenuItem(value: 'close', child: Text(l10n.closeProject)),
              ],
            ),
            const SizedBox(width: AppSpacing.x1),
          ],
        ),
        body: IndexedStack(
          index: _index,
          children: [
            const DataEditorPage(),
            // active：只有当前可见的标签页才允许抢焦点 / 响应页面快捷键
            AnalysisHub(active: _index == 1),
            const TransformPage(embedded: true),
          ],
        ),
      ),
    );
  }
}

/// 自动保存状态胶囊：已保存 / 未保存，颜色 + 文案双重表达。
class _SavePill extends StatelessWidget {
  final bool dirty;
  final DateTime? savedAt;
  final AppLocalizations l10n;

  const _SavePill({
    required this.dirty,
    required this.savedAt,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = context.appColors;
    final color = dirty ? app.warning : app.success;

    String text;
    if (dirty) {
      text = l10n.unsaved;
    } else if (savedAt != null) {
      final hh = savedAt!.hour.toString().padLeft(2, '0');
      final mm = savedAt!.minute.toString().padLeft(2, '0');
      text = l10n.autoSavedAt('$hh:$mm');
    } else {
      text = l10n.saveProject;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
