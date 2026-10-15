import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/theme/design_tokens.dart';
import '../../shared/ui/ui.dart';
import 'learn_content.dart';
import 'learn_page.dart' show isZhLocale;

class LessonDetailPage extends StatelessWidget {
  final LearnLesson lesson;
  const LessonDetailPage({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final zh = isZhLocale(context);
    final formulas = lesson.formulasFor(zh);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lesson.titleFor(zh),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ConstrainedContent(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.x4,
            bottom: AppSpacing.x6,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.x3),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: AppRadius.rMd,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Text(
                      lesson.summaryFor(zh),
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            for (var i = 0; i < lesson.sections.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: AppRadius.rSm,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2 + 2),
                  Expanded(
                    child: Text(
                      lesson.sections[i].headingFor(zh),
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  lesson.sections[i].bodyFor(zh),
                  style: text.bodyMedium?.copyWith(height: 1.7),
                ),
              ),
              const SizedBox(height: AppSpacing.x4),
            ],
            if (formulas.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.functions, size: 18, color: scheme.primary),
                  const SizedBox(width: AppSpacing.x2),
                  Text(
                    l10n.keyFormulas,
                    style:
                        text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),
              AppCard(
                color: scheme.surfaceContainerHigh,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in formulas)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.x2,
                        ),
                        child: SelectableText(
                          f,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontFamilyFallback: const ['monospace'],
                            fontSize: 13.5,
                            height: 1.6,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
