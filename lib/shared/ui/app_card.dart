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

    Widget content = Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (accent != null)
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
      ),
    );

    if (onTap != null && !dense) {
      content = InkWell(
        onTap: onTap,
        borderRadius: r,
        child: content,
      );
    } else if (onTap != null) {
      content = InkWell(onTap: onTap, borderRadius: r, child: content);
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
