/// 空状态 / 错误状态：图标 + 标题 + 说明 + 主行动。
library;

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final Widget? extra;
  final bool compact;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.extra,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.x4 : AppSpacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 60 : 84,
              height: compact ? 60 : 84,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 28 : 38,
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: compact ? AppSpacing.x3 : AppSpacing.x4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.x2),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ],
            if (extra != null) ...[
              const SizedBox(height: AppSpacing.x4),
              extra!,
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.x5),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 就地错误提示（替代裸文字 throw）。
class InlineError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const InlineError({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: AppRadius.rMd,
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: scheme.error),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: AppFontSize.bodySm, color: scheme.onErrorContainer),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.x2),
            TextButton(
              onPressed: onRetry,
              child: Text(retryLabel ?? 'Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
