/// 统一卡片容器：细描边 / 微阴影 / 可选强调条 / 可点态。
library;

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool elevated;
  final Color? accent;
  final Color? color;
  final BorderRadius? radius;
  final bool dense;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.onTap,
    this.elevated = false,
    this.accent,
    this.color,
    this.radius,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = context.appColors;
    final r = radius ?? AppRadius.rLg;
    final hasAccent = accent != null;

    final row = Row(
      // 强调条需要撑满卡片高度；无强调条时用 center，避免在无界高度
      // （如 ListView）下把无限约束传给子节点。
      crossAxisAlignment:
          hasAccent ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
      children: [
        if (hasAccent)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.x3),
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );

    Widget content = Padding(
      padding: padding,
      // IntrinsicHeight 让 stretch 在高度无界时仍然成立。
      child: hasAccent ? IntrinsicHeight(child: row) : row,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: r,
        child: content,
      );
    }

    final decoration = BoxDecoration(
      color: color ?? scheme.surfaceContainerLow,
      borderRadius: r,
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.8)),
      boxShadow: elevated ? app.shadowSm : null,
    );

    return DecoratedBox(
      decoration: decoration,
      child: content,
    );
  }
}
