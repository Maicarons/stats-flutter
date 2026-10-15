import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/theme/design_tokens.dart';
import '../../shared/locale_util.dart';
import '../../shared/ui/ui.dart';
import 'learn_content.dart';
import 'lesson_detail_page.dart';

class LearnPage extends StatelessWidget {
  final bool embedded;
  const LearnPage({super.key, this.embedded = true});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final zh = isZhUi(context);

    // 按类别分组，保持内容中首次出现的顺序。
    final byCat = <String, List<LearnLesson>>{};
    for (final l in learnLessons) {
      byCat.putIfAbsent(l.categoryFor(zh), () => []).add(l);
    }

    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: Text(
                l10n.learnTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      body: ConstrainedContent(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.x3,
            bottom: AppSpacing.x6,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.x4),
              decoration: BoxDecoration(
                borderRadius: AppRadius.rXl,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primaryContainer,
                    Color.alphaBlend(
                      scheme.tertiary.withValues(alpha: 0.22),
                      scheme.primaryContainer,
                    ),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 20,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.x2),
                      Expanded(
                        child: Text(
                          l10n.learnTagline,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    l10n.learnIntroBody,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.9),
                      fontSize: AppFontSize.bodySm,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            for (final entry in byCat.entries) ...[
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.x5,
                  bottom: AppSpacing.x2,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Text(
                      entry.key,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: AppRadius.rSm,
                      ),
                      child: Text(
                        '${entry.value.length}',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final l in entry.value)
                _LessonCard(lesson: l, zh: zh),
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LearnLesson lesson;
  final bool zh;
  const _LessonCard({required this.lesson, required this.zh});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: AppCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonDetailPage(lesson: lesson),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: AppRadius.rMd,
              ),
              child: Icon(
                Icons.menu_book_outlined,
                color: scheme.onPrimaryContainer,
                size: 21,
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.titleFor(zh),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lesson.summaryFor(zh),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: AppFontSize.bodySm,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
