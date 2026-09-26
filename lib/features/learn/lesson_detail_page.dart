import 'package:flutter/material.dart';

import 'learn_content.dart';

class LessonDetailPage extends StatelessWidget {
  final LearnLesson lesson;
  const LessonDetailPage({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(lesson.summary,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: scheme.outline)),
          const SizedBox(height: 16),
          for (final s in lesson.sections) ...[
            Text(s.heading,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(s.body, style: const TextStyle(height: 1.55)),
            const SizedBox(height: 14),
          ],
          if (lesson.formulas.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('核心公式',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  for (final f in lesson.formulas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(f,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13.5,
                            color: scheme.onSurface,
                          )),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
