/// 分析项卡片：图标 + 标题 + 描述 + 标签/标记。
library;

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/theme/design_tokens.dart';
import 'focus_ring.dart';

class AnalysisTile extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final bool favorite;
  final VoidCallback? onToggleFavorite;
  final bool compact;

  const AnalysisTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.description,
    this.badge,
    this.favorite = false,
    this.onToggleFavorite,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // 键盘焦点环：描边变主题色 + 外扩焦点环，与 hover（仅底色微变）可区分。
    return FocusRing(
      builder: (context, focused) => Semantics(
        button: true,
        label: description == null ? title : '$title. $description',
        child: Material(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadius.rMd,
          child: InkWell(
            borderRadius: AppRadius.rMd,
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.rMd,
                border: Border.all(
                  color: focused
                      ? scheme.primary
                      : scheme.outlineVariant.withValues(alpha: 0.8),
                ),
                boxShadow: focused ? AppFocus.ring(scheme) : null,
              ),
              padding:
                  EdgeInsets.all(compact ? AppSpacing.x3 : AppSpacing.x3 + 2),
              child: _body(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: AppRadius.rSm,
          ),
          child: Icon(icon, size: 19, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: AppSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: AppSpacing.x2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description!,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onToggleFavorite != null)
          IconButton(
            tooltip: favorite
                ? AppLocalizations.of(context).removeFavorite
                : AppLocalizations.of(context).addFavorite,
            onPressed: onToggleFavorite,
            icon: Icon(
              favorite ? Icons.star_rounded : Icons.star_border_rounded,
              size: 20,
              color: favorite ? scheme.primary : scheme.outline,
            ),
          )
        else
          Icon(Icons.chevron_right, size: 20, color: scheme.outline),
      ],
    );
  }
}
