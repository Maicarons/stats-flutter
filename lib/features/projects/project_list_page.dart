/// 主页：工程列表入口
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/project.dart';
import '../../shared/project_store.dart';
import '../../shared/brand_logo.dart';
import 'project_workspace_page.dart';
import '../settings/about_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = _filtered;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶栏
          SliverAppBar(
            pinned: true,
            title: const Text(
              'Stats-flutter',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: '关于',
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  );
                },
              ),
            ],
          ),
          // 欢迎横幅
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primaryContainer,
                      scheme.tertiaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '工程列表',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '每个工程是一份独立统计表。新建、打开、复制或删除工程，进入后可做数据编辑与统计分析。',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () => _createDialog(demo: true),
                          icon: const Icon(Icons.science_outlined, size: 18),
                          label: const Text('示例工程'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () => _createDialog(demo: false),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('新建空白'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 搜索
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: '搜索工程…',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
          // 统计条
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    '共 ${projectStore.projects.length} 个工程',
                    style: TextStyle(
                        fontSize: 12, color: scheme.outline),
                  ),
                  const Spacer(),
                  if (projectStore.rootPath.isNotEmpty)
                    Flexible(
                      child: Text(
                        projectStore.rootPath,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10, color: scheme.outline),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 列表
          if (!projectStore.loaded)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open,
                        size: 64, color: scheme.outlineVariant),
                    const SizedBox(height: 12),
                    Text(
                      projectStore.projects.isEmpty
                          ? '还没有工程\n点击上方「示例工程」或「新建空白」开始'
                          : '没有匹配的工程',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.outline),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _ProjectCard(
                  meta: list[i],
                  onOpen: () => _open(list[i]),
                  onMenu: (a) => _onMenu(a, list[i]),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createDialog(demo: true),
        icon: const Icon(Icons.add),
        label: const Text('新建工程'),
      ),
    );
  }

  Future<void> _createDialog({required bool demo}) async {
    final nameCtrl = TextEditingController(
      text: demo
          ? '示例·成绩分析'
          : '工程 ${projectStore.projects.length + 1}',
    );
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(demo ? '新建示例工程' : '新建空白工程'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '工程名称'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final p = await projectStore.create(
      name: nameCtrl.text.trim().isEmpty ? 'Untitled' : nameCtrl.text.trim(),
      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      withDemo: demo,
    );
    if (!mounted) return;
    await _open(p.meta);
  }

  Future<void> _open(ProjectMeta meta) async {
    final p = await projectStore.open(meta.id);
    if (!mounted) return;
    if (p == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('打开工程失败')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectWorkspacePage(project: p),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _onMenu(String action, ProjectMeta meta) async {
    switch (action) {
      case 'open':
        await _open(meta);
        break;
      case 'rename':
        final ctrl = TextEditingController(text: meta.name);
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('重命名工程'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('保存'),
              ),
            ],
          ),
        );
        if (ok == true && ctrl.text.trim().isNotEmpty) {
          await projectStore.rename(meta.id, ctrl.text.trim());
        }
        break;
      case 'duplicate':
        await projectStore.duplicate(meta.id, '${meta.name} 副本');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已复制工程')),
          );
        }
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除工程'),
            content: Text('确定删除「${meta.name}」？此操作不可恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        if (ok == true) await projectStore.delete(meta.id);
        break;
    }
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
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const BrandLogo(size: 48, onPrimary: true),
              ),
              const SizedBox(width: 12),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 4),
                    Text(
                      '${meta.nCases} 个案 · ${meta.nVars} 变量',
                      style:
                          TextStyle(fontSize: 12, color: scheme.outline),
                    ),
                    Text(
                      '更新于 ${fmt.format(meta.updatedAt)}',
                      style: TextStyle(
                          fontSize: 11, color: scheme.outlineVariant),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onMenu,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'open', child: Text('打开')),
                  PopupMenuItem(value: 'rename', child: Text('重命名')),
                  PopupMenuItem(value: 'duplicate', child: Text('复制')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('删除', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
