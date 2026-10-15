/// 全局导航壳：工程 / 学习 / 测试 / 设置。
/// 窄屏底部 NavigationBar，宽屏自动切换 NavigationRail。
/// 数据、分析、变换在「工程工作区」内（ProjectWorkspacePage）。
library;

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../shared/ui/ui.dart';
import '../learn/learn_page.dart';
import '../projects/project_list_page.dart';
import '../quiz/quiz_page.dart';
import '../settings/settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const pages = [
      ProjectListPage(embedded: true),
      LearnPage(embedded: true),
      QuizPage(embedded: true),
      SettingsPage(embedded: true),
    ];

    return AdaptiveNavScaffold(
      index: _index,
      onIndexChanged: (i) => setState(() => _index = i),
      items: [
        NavItem(
          icon: Icons.folder_outlined,
          selectedIcon: Icons.folder,
          label: l10n.tabProjects,
        ),
        NavItem(
          icon: Icons.school_outlined,
          selectedIcon: Icons.school,
          label: l10n.tabLearn,
        ),
        NavItem(
          icon: Icons.quiz_outlined,
          selectedIcon: Icons.quiz,
          label: l10n.tabQuiz,
        ),
        NavItem(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: l10n.tabSettings,
        ),
      ],
      body: IndexedStack(index: _index, children: pages),
    );
  }
}
