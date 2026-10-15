import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/theme/design_tokens.dart';
import '../../shared/locale_util.dart';
import '../../shared/ui/ui.dart';
import 'quiz_bank.dart';

class QuizPage extends StatefulWidget {
  final bool embedded;
  const QuizPage({super.key, this.embedded = true});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _count = 10;
  List<QuizQuestion> _paper = [];
  int _current = 0;
  final List<int?> _answers = [];
  bool _started = false;
  bool _finished = false;

  /// 每套试卷随机打乱选项顺序（含正确答案下标迁移）。
  List<QuizQuestion> _shuffleOptions(List<QuizQuestion> src, Random rng) {
    return src.map((q) {
      final idx = List<int>.generate(q.options.length, (i) => i)..shuffle(rng);
      final opts = [for (final i in idx) q.options[i]];
      final optsEn = [for (final i in idx) q.optionsEn[i]];
      return QuizQuestion(
        id: q.id,
        topic: q.topic,
        topicEn: q.topicEn,
        stem: q.stem,
        stemEn: q.stemEn,
        options: opts,
        optionsEn: optsEn,
        answerIndex: idx.indexOf(q.answerIndex),
        explanation: q.explanation,
        explanationEn: q.explanationEn,
      );
    }).toList();
  }

  void _start() {
    final rng = Random();
    final all = List<QuizQuestion>.from(quizBank)
      ..shuffle(rng);
    _paper = _shuffleOptions(all.take(_count).toList(), rng);
    _answers
      ..clear()
      ..addAll(List.filled(_paper.length, null));
    _current = 0;
    _started = true;
    _finished = false;
    setState(() {});
  }

  int get _score {
    var s = 0;
    for (var i = 0; i < _paper.length; i++) {
      if (_answers[i] == _paper[i].answerIndex) s++;
    }
    return s;
  }

  int get _unanswered => _answers.where((a) => a == null).length;

  Future<void> _submit(AppLocalizations l10n) async {
    if (_unanswered > 0) {
      final ok = await showConfirmDialog(
        context,
        title: l10n.submit,
        message: l10n.quizUnanswered(_unanswered),
        confirmLabel: l10n.submit,
      );
      if (!ok || !mounted) return;
    }
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(
                l10n.quizTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              actions: [
                if (_started && !_finished)
                  TextButton(
                    onPressed: () => _submit(l10n),
                    child: Text(l10n.submit),
                  ),
              ],
            ),
      body: ConstrainedContent(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
        child: !_started
            ? _buildSetup(context, l10n, scheme, text)
            : _finished
                ? _buildResult(context, l10n, scheme, text)
                : _buildQuiz(context, l10n, scheme, text),
      ),
    );
  }

  // ---------------------------------------------------------------- 设置

  Widget _buildSetup(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme,
    TextTheme text,
  ) {
    return ListView(
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
                scheme.tertiaryContainer,
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.20),
                  scheme.tertiaryContainer,
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
                    Icons.quiz_outlined,
                    size: 20,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Text(
                      l10n.quizSetupTitle,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                l10n.quizSetupBody(quizBank.length),
                style: TextStyle(
                  color: scheme.onTertiaryContainer.withValues(alpha: 0.9),
                  fontSize: AppFontSize.bodySm,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x5),
        Text(
          l10n.quizCount,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.x2),
        Wrap(
          spacing: AppSpacing.x2,
          runSpacing: AppSpacing.x2,
          children: [
            for (final n in [5, 10, 15, 20])
              ChoiceChip(
                label: Text(l10n.quizNQuestions(n)),
                selected: _count == n,
                onSelected: (_) => setState(() => _count = n),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.x5),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.quizStart),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- 答题

  Widget _buildQuiz(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme,
    TextTheme text,
  ) {
    final q = _paper[_current];
    final zh = isZhUi(context);
    final options = q.optionsFor(zh);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.x3,
            bottom: AppSpacing.x2,
          ),
          child: Row(
            children: [
              Text(
                l10n.quizProgress(_current + 1, _paper.length),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x2,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: AppRadius.rSm,
                ),
                child: Text(
                  q.topicFor(zh),
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: AppRadius.rSm,
          child: LinearProgressIndicator(
            value: (_current + 1) / _paper.length,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHigh,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(
              top: AppSpacing.x4,
              bottom: AppSpacing.x4,
            ),
            children: [
              Text(
                q.stemFor(zh),
                style: text.titleMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: AppSpacing.x4),
              for (var i = 0; i < options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                  child: _OptionTile(
                    label: String.fromCharCode(65 + i),
                    text: options[i],
                    selected: _answers[_current] == i,
                    onTap: () => setState(() => _answers[_current] = i),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _current == 0
                      ? null
                      : () => setState(() => _current--),
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: Text(l10n.prev),
                ),
                const Spacer(),
                if (_current < _paper.length - 1)
                  FilledButton.icon(
                    onPressed: () => setState(() => _current++),
                    icon: const Icon(Icons.chevron_right, size: 18),
                    label: Text(l10n.next),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => _submit(l10n),
                    icon: const Icon(Icons.done_all, size: 18),
                    label: Text(l10n.submit),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- 结果

  Widget _buildResult(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme,
    TextTheme text,
  ) {
    final zh = isZhUi(context);
    final score = _score;
    final total = _paper.length;
    final pct = total == 0 ? 0.0 : score / total;
    final color = pct >= 0.6 ? scheme.primary : scheme.error;
    final feedback = pct >= 0.8
        ? l10n.quizFeedbackHigh
        : pct >= 0.6
            ? l10n.quizFeedbackMid
            : l10n.quizFeedbackLow;

    return ListView(
      padding: const EdgeInsets.only(
        top: AppSpacing.x4,
        bottom: AppSpacing.x6,
      ),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.x5),
          child: Column(
            children: [
              SizedBox(
                width: 116,
                height: 116,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 116,
                      height: 116,
                      child: CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 9,
                        backgroundColor: scheme.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score / $total',
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        Text(
                          '${(pct * 100).round()}%',
                          style: TextStyle(
                            fontSize: AppFontSize.bodySm,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x4),
              Text(
                l10n.quizScoreLabel,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                feedback,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSize.bodySm,
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.replay, size: 18),
                label: Text(l10n.quizTryAgain),
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _started = false;
                  _finished = false;
                }),
                icon: const Icon(Icons.tune, size: 18),
                label: Text(l10n.quizBackToSetup),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x5),
        Text(
          l10n.quizReview,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.x2),
        for (var i = 0; i < _paper.length; i++)
          _ReviewTile(
            index: i,
            q: _paper[i],
            answer: _answers[i],
            l10n: l10n,
            zh: zh,
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.65)
          : scheme.surfaceContainerLow,
      borderRadius: AppRadius.rMd,
      child: InkWell(
        borderRadius: AppRadius.rMd,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x3),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rMd,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      selected ? scheme.primary : scheme.surfaceContainerHighest,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFontSize.label,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final int index;
  final QuizQuestion q;
  final int? answer;
  final AppLocalizations l10n;
  final bool zh;

  const _ReviewTile({
    required this.index,
    required this.q,
    required this.answer,
    required this.l10n,
    required this.zh,
  });

  @override
  Widget build(BuildContext context) {
    final correct = answer == q.answerIndex;
    final scheme = Theme.of(context).colorScheme;
    final options = q.optionsFor(zh);

    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(
          correct ? Icons.check_circle : Icons.cancel,
          color: correct ? scheme.primary : scheme.error,
        ),
        title: Text(
          l10n.quizItemTopic(index + 1, q.topicFor(zh)),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          q.stemFor(zh),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          0,
          AppSpacing.x4,
          AppSpacing.x3,
        ),
        children: [
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    i == q.answerIndex
                        ? Icons.check
                        : (answer == i ? Icons.close : Icons.circle_outlined),
                    size: 15,
                    color: i == q.answerIndex
                        ? scheme.primary
                        : (answer == i
                            ? scheme.error
                            : scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Text(
                      '${String.fromCharCode(65 + i)}. ${options[i]}'
                      '${i == q.answerIndex ? '  · ${l10n.quizCorrect}' : ''}'
                      '${answer == i && i != q.answerIndex ? '  · ${l10n.quizYourChoice}' : ''}',
                      style: TextStyle(
                        height: 1.4,
                        color: i == q.answerIndex
                            ? scheme.primary
                            : (answer == i ? scheme.error : null),
                        fontWeight:
                            i == q.answerIndex ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.x2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.x3),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: AppRadius.rMd,
            ),
            child: Text(
              l10n.quizExplanation(q.explanationFor(zh)),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: AppFontSize.bodySm,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
