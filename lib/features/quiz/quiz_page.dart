import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

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

  void _start() {
    final rng = Random();
    final all = List<QuizQuestion>.from(quizBank)..shuffle(rng);
    _paper = all.take(_count).toList();
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actions = [
      if (_started && !_finished)
        TextButton(
          onPressed: _submit,
          child: Text(AppLocalizations.of(context).submit),
        ),
    ];
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(AppLocalizations.of(context).quizTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              actions: actions,
            ),
      body: !_started
          ? _buildSetup(scheme)
          : _finished
              ? _buildResult(scheme)
              : _buildQuiz(scheme),
    );
  }

  Widget _buildSetup(ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: scheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('随机抽题 · 即时判分',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onTertiaryContainer)),
                const SizedBox(height: 6),
                Text(
                  '题库共 ${quizBank.length} 题，覆盖描述统计、t 检验、ANOVA、相关、回归、卡方、非参数与信度。'
                  '交卷后可查看解析与错题。',
                  style: TextStyle(
                      color: scheme.onTertiaryContainer.withValues(alpha: 0.85),
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('题目数量', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [5, 10, 15, 20]
              .map((n) => ChoiceChip(
                    label: Text('$n 题'),
                    selected: _count == n,
                    onSelected: (_) => setState(() => _count = n),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow),
          label: const Text('开始测试'),
        ),
      ],
    );
  }

  Widget _buildQuiz(ColorScheme scheme) {
    final q = _paper[_current];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Text('第 ${_current + 1} / ${_paper.length} 题',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(q.topic, style: TextStyle(color: scheme.outline, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (_current + 1) / _paper.length),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(q.stem,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(height: 1.45)),
              const SizedBox(height: 16),
              for (var i = 0; i < q.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _OptionTile(
                    label: String.fromCharCode(65 + i),
                    text: q.options[i],
                    selected: _answers[_current] == i,
                    onTap: () => setState(() => _answers[_current] = i),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: _current == 0
                      ? null
                      : () => setState(() => _current--),
                  child: Text(AppLocalizations.of(context).prev),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    if (_current < _paper.length - 1) {
                      setState(() => _current++);
                    } else {
                      _submit();
                    }
                  },
                  child: Text(_current < _paper.length - 1
                            ? AppLocalizations.of(context).next
                            : AppLocalizations.of(context).submit),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(ColorScheme scheme) {
    final score = _score;
    final total = _paper.length;
    final pct = total == 0 ? 0.0 : score / total;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: pct >= 0.8
              ? scheme.primaryContainer
              : pct >= 0.6
                  ? scheme.tertiaryContainer
                  : scheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('本次得分',
                    style: TextStyle(
                        color: pct >= 0.8
                            ? scheme.onPrimaryContainer
                            : pct >= 0.6
                                ? scheme.onTertiaryContainer
                                : scheme.onErrorContainer)),
                const SizedBox(height: 8),
                Text('$score / $total',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: pct >= 0.8
                            ? scheme.onPrimaryContainer
                            : pct >= 0.6
                                ? scheme.onTertiaryContainer
                                : scheme.onErrorContainer)),
                const SizedBox(height: 4),
                Text(
                  pct >= 0.8
                      ? '非常棒！可以挑战更高题量或去数据分析里实践。'
                      : pct >= 0.6
                          ? '还不错，建议复习错题解析。'
                          : '建议先到「学习」模块巩固概念再来测试。',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.replay),
          label: const Text('再来一套'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => setState(() {
            _started = false;
            _finished = false;
          }),
          child: const Text('返回设置'),
        ),
        const SizedBox(height: 20),
        Text('答题回顾', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (var i = 0; i < _paper.length; i++) _ReviewTile(index: i, q: _paper[i], answer: _answers[i]),
      ],
    );
  }

  void _submit() {
    setState(() => _finished = true);
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
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? scheme.primary : scheme.surfaceContainerHighest,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
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
  const _ReviewTile({required this.index, required this.q, required this.answer});

  @override
  Widget build(BuildContext context) {
    final correct = answer == q.answerIndex;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        shape: const Border(),
        leading: Icon(
          correct ? Icons.check_circle : Icons.cancel,
          color: correct ? scheme.primary : scheme.error,
        ),
        title: Text('第${index + 1}题 · ${q.topic}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(q.stem, maxLines: 2, overflow: TextOverflow.ellipsis),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < q.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${String.fromCharCode(65 + i)}. ${q.options[i]}'
                      '${i == q.answerIndex ? '  ✓ 正确' : ''}'
                      '${answer == i && i != q.answerIndex ? '  ✗ 你的选择' : ''}',
                      style: TextStyle(
                        color: i == q.answerIndex
                            ? scheme.primary
                            : (answer == i ? scheme.error : null),
                        fontWeight: i == q.answerIndex ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text('解析：${q.explanation}',
                    style: TextStyle(color: scheme.outline, fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
