import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import 'learn_content.dart';
import 'lesson_detail_page.dart';

class LearnPage extends StatelessWidget {
  final bool embedded;
  const LearnPage({super.key, this.embedded = true});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final byCat = <String, List<LearnLesson>>{};
    for (final l in learnLessons) {
      byCat.putIfAbsent(l.category, () => []).add(l);
    }
    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: Text(AppLocalizations.of(context).learnTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).learnTagline,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer)),
                  const SizedBox(height: 6),
                  Text(
                    '用短课掌握描述统计、假设检验、回归、非参数与信度等核心方法。'
                    '每课含要点与核心公式，学完可直接去「测试」练手。',
                    style: TextStyle(
                        color:
                            scheme.onPrimaryContainer.withValues(alpha: 0.85),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          for (final entry in byCat.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Text(entry.key,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            ...entry.value.map((l) => _LessonCard(lesson: l)),
          ],
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LearnLesson lesson;
  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LessonDetailPage(lesson: lesson),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.menu_book,
                      color: scheme.onPrimaryContainer, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lesson.title,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(lesson.summary,
                          style: TextStyle(
                              color: scheme.outline, fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
