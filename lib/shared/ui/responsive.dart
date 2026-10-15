/// 响应式断点 + 自适应导航脚手架（窄屏底部栏 / 宽屏侧栏）。
library;

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

abstract final class AppBreakpoints {
  /// 紧凑（手机竖屏）
  static const double compact = 600;

  /// 中等（平板竖屏）
  static const double medium = 840;

  /// 宽（桌面 / 平板横屏）
  static const double expanded = 1200;

  /// 内容最大宽度（防止超宽屏文字行长过长）
  static const double contentMaxWidth = 960;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => width(context) < compact;
  static bool isMedium(BuildContext context) =>
      width(context) >= compact && width(context) < expanded;
  static bool isExpanded(BuildContext context) => width(context) >= expanded;

  /// 660 以上使用侧栏（留出安全余量，避免紧绷）
  static bool useRail(BuildContext context) => width(context) >= 660;
}

/// 导航项定义（同时驱动底部栏与侧栏）。
class NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// 自适应导航脚手架。
class AdaptiveNavScaffold extends StatelessWidget {
  final int index;
  final ValueChanged<int> onIndexChanged;
  final List<NavItem> items;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const AdaptiveNavScaffold({
    super.key,
    required this.index,
    required this.onIndexChanged,
    required this.items,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final useRail = AppBreakpoints.useRail(context);
    final scheme = Theme.of(context).colorScheme;

    if (!useRail) {
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onIndexChanged,
          destinations: [
            for (final it in items)
              NavigationDestination(
                icon: Icon(it.icon),
                selectedIcon: Icon(it.selectedIcon),
                label: it.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: onIndexChanged,
            labelType: NavigationRailLabelType.all,
            backgroundColor: scheme.surfaceContainerLow,
            destinations: [
              for (final it in items)
                NavigationRailDestination(
                  icon: Icon(it.icon),
                  selectedIcon: Icon(it.selectedIcon),
                  label: Text(it.label),
                ),
            ],
          ),
          VerticalDivider(width: 1, color: scheme.outlineVariant),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// 宽屏居中 + 最大宽度约束的内容容器。
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  const ConstrainedContent({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
    this.maxWidth = AppBreakpoints.contentMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
