/// 显著性标记：星级 + 语义色 + 文字说明（不只用颜色表达）。
library;

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/theme/design_tokens.dart';

/// 按 p 值取语义色（与文字/星级冗余表达，色盲友好）。
Color pValueColor(BuildContext context, double? p) {
  if (p == null || p.isNaN) return Theme.of(context).colorScheme.onSurface;
  final app = context.appColors;
  final scheme = Theme.of(context).colorScheme;
  if (p < 0.001) return app.significance;
  if (p < 0.01) return app.significance;
  if (p < 0.05) return app.significance;
  return scheme.onSurfaceVariant;
}

/// 统计量的正负着色。
Color signedColor(BuildContext context, double value) {
  final app = context.appColors;
  if (value > 0) return app.positive;
  if (value < 0) return app.negative;
  return Theme.of(context).colorScheme.onSurface;
}

class SignificanceBadge extends StatelessWidget {
  /// p 值；用于取色。
  final double? p;

  /// 星级串（如 `***`），通常来自 statkit 的 `significanceStars`。
  final String? stars;

  /// 直接给定文案（优先于 stars）。
  final String? text;

  final bool small;

  const SignificanceBadge({
    super.key,
    this.p,
    this.stars,
    this.text,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = text ?? (stars ?? '').trim();
    if (label.isEmpty) return const SizedBox.shrink();
    final color = pValueColor(context, p);

    return Semantics(
      label: AppLocalizations.of(context).significanceLabel(label),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 5 : 7,
          vertical: small ? 0 : 1,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: small ? 10 : 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
