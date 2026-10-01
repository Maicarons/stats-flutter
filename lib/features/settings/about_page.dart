/// 关于页：多语言 README
library;

import 'package:flutter/material.dart';

import '../../shared/brand_logo.dart';
import 'package:flutter/services.dart' show rootBundle;


class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
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
    try {
      final zh = await rootBundle.loadString('assets/content/README.zh.md');
      final en = await rootBundle.loadString('assets/content/README.en.md');
      setState(() {
        _zh = zh;
        _en = en;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _zh = '加载 README 失败：$e';
        _en = 'Failed to load README: $e';
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于 / About'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '信息'),
            Tab(text: '中文 README'),
            Tab(text: 'English README'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildInfo(scheme),
          _buildReadme(_zh),
          _buildReadme(_en),
        ],
      ),
    );
  }

  Widget _buildInfo(ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const BrandLogo(size: 104, onPrimary: true),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Stats-flutter',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Center(
          child: Text(
            '版本 1.0.0+1',
            style: TextStyle(color: scheme.outline),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.description),
                title: Text('项目简介'),
                subtitle: Text(
                  '工程化统计分析套件，覆盖数据编辑、统计过程、'
                  '数据变换、学习与测试。统计内核为独立纯 Dart 包 statkit。',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('文档站'),
                subtitle: const Text('https://maicarons.github.io/stats-flutter/'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('文档站：https://maicarons.github.io/stats-flutter/'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('开源许可'),
                subtitle: const Text('AGPL-3.0 · 开源项目'),
              ),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.redAccent),
                title: const Text('技术栈'),
                subtitle: const Text('Flutter · Dart'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('本机运行时',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Flutter 应用 · 平台：Windows / macOS / Linux / Android / iOS',
                    style: TextStyle(fontSize: 12.5, color: scheme.outline)),
                Text('统计内核：packages/statkit（纯 Dart，13 组测试）',
                    style: TextStyle(fontSize: 12.5, color: scheme.outline)),
                Text('界面语言：中文 / English（可在设置中切换）',
                    style: TextStyle(fontSize: 12.5, color: scheme.outline)),
                Text('主题：浅色 / 深色 / 跟随系统 · 8 种主题色',
                    style: TextStyle(fontSize: 12.5, color: scheme.outline)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadme(String content) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          content,
          style: const TextStyle(fontSize: 13.5, height: 1.55),
        ),
      ),
    );
  }
}
