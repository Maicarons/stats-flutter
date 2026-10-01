/// 工程工作区：仅含 数据 / 分析 / 变换
library;

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/project.dart';
import '../../shared/project_store.dart';
import '../analysis/analysis_hub.dart';
import '../data_editor/csv_io.dart';
import '../data_editor/excel_io.dart';
import '../data_editor/sav_import.dart';
import '../../shared/dataset_store.dart';
import '../data_editor/data_editor_page.dart';
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
            ListTile(title: Text(l10n.importDataTitle)),
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
              leading: const Icon(Icons.science),
              title: Text(l10n.importDemoData),
              onTap: () => Navigator.pop(ctx, 'demo'),
            ),
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
    } else if (v == 'demo') {
      datasetStore.resetDemo();
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

  String _subtitle(AppLocalizations l10n) {
    final base = l10n.casesByVars(project.dataset.nCases, project.dataset.nVars);
    final savedAt = projectStore.lastSavedAt;
    if (savedAt != null && !projectStore.dirty) {
      final hh = savedAt.hour.toString().padLeft(2, '0');
      final mm = savedAt.minute.toString().padLeft(2, '0');
      return '$base · ${l10n.autoSavedAt('$hh:$mm')}';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      const DataEditorPage(),
      const AnalysisHub(),
      TransformPage(embedded: true),
    ];

    return Scaffold(
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
            Text(
              _subtitle(l10n),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.importCsvSav,
            icon: const Icon(Icons.file_open),
            onPressed: () => _importMenu(),
          ),
          IconButton(
            tooltip: l10n.exportCsv,
            icon: const Icon(Icons.save_alt),
            onPressed: () => _export(),
          ),
          IconButton(
            tooltip: l10n.saveProject,
            icon: const Icon(Icons.save_outlined),
            onPressed: _save,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'save') _save();
              if (v == 'exit') _exit();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'save', child: Text(l10n.saveProject)),
              PopupMenuItem(value: 'exit', child: Text(l10n.closeProject)),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.table_chart_outlined),
            selectedIcon: const Icon(Icons.table_chart),
            label: l10n.tabData,
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined),
            selectedIcon: const Icon(Icons.analytics),
            label: l10n.analysis,
          ),
          NavigationDestination(
            icon: const Icon(Icons.transform_outlined),
            selectedIcon: const Icon(Icons.transform),
            label: l10n.tabTransform,
          ),
        ],
      ),
    );
  }
}
