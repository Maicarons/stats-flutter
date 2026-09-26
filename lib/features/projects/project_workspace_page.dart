/// 工程工作区：仅含 数据 / 分析 / 变换
library;

import 'package:flutter/material.dart';

import '../../core/models/project.dart';
import '../../shared/project_store.dart';
import '../analysis/analysis_hub.dart';
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

  Future<void> _save() async {
    await projectStore.saveCurrent();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('工程已保存'),
        duration: Duration(milliseconds: 1200),
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

  @override
  Widget build(BuildContext context) {
    final pages = const [
      DataEditorPage(),
      AnalysisHub(),
      TransformPage(embedded: true),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '保存并返回',
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
              '${project.dataset.nCases} 个案 × ${project.dataset.nVars} 变量',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '保存工程',
            icon: const Icon(Icons.save_outlined),
            onPressed: _save,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'save') _save();
              if (v == 'exit') _exit();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'save', child: Text('保存工程')),
              PopupMenuItem(value: 'exit', child: Text('关闭工程')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.table_chart_outlined),
            selectedIcon: Icon(Icons.table_chart),
            label: '数据',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: '分析',
          ),
          NavigationDestination(
            icon: Icon(Icons.transform_outlined),
            selectedIcon: Icon(Icons.transform),
            label: '变换',
          ),
        ],
      ),
    );
  }
}
