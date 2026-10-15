/// 指标块 / 统计胶囊：主值（等宽数字）+ 单位 + 标签。
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// 竖排指标块，用于概览区。
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final String? unit;
  final IconData? icon;
  final Color? valueColor;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.unit,
    this.icon,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AppCardPadding(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x1 + 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.tabularText(
                    text.headlineSmall?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ) ??
                        const TextStyle(),
                  ).copyWith(color: valueColor),
                ),
              ),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Text(
                    unit!,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 横排小胶囊：`个案 128`，用于工具栏概览。
class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.surfaceContainerHigh;
    final onBg = _onColor(bg, scheme);

    return Semantics(
      label: '$label $value',
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x1 + 3,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.rSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: onBg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: AppFontSize.caption,
                fontWeight: FontWeight.w500,
                color: onBg.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: AppTheme.tabularText(
                TextStyle(
                  fontSize: AppFontSize.label,
                  fontWeight: FontWeight.w800,
                  color: onBg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _onColor(Color bg, ColorScheme scheme) {
    final c = ThemeData.estimateBrightnessForColor(bg);
    return c == Brightness.dark ? Colors.white : const Color(0xFF12161C);
  }
}

/// AppCard 的紧凑版：仅容器 + 可选点按（供 StatTile 复用，避免循环依赖）。
class AppCardPadding extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const AppCardPadding({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.x3),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainerLow,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.8)),
      ),
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: AppRadius.rMd,
              child: content,
            ),
    );
  }
}
