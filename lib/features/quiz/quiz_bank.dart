/// 题库（中英双语）
library;

class QuizQuestion {
  final String id;
  final String topic;
  final String topicEn;
  final String stem;
  final String stemEn;
  final List<String> options;
  final List<String> optionsEn;
  final int answerIndex;
  final String explanation;
  final String explanationEn;

  const QuizQuestion({
    required this.id,
    required this.topic,
    required this.topicEn,
    required this.stem,
    required this.stemEn,
    required this.options,
    required this.optionsEn,
    required this.answerIndex,
    required this.explanation,
    required this.explanationEn,
  });

  String topicFor(bool zh) => zh ? topic : topicEn;
  String stemFor(bool zh) => zh ? stem : stemEn;
  List<String> optionsFor(bool zh) => zh ? options : optionsEn;
  String explanationFor(bool zh) => zh ? explanation : explanationEn;
}

const quizBank = <QuizQuestion>[
  QuizQuestion(
    id: 'q1',
    topic: '描述统计',
    topicEn: 'Descriptive statistics',
    stem: '样本标准差 s 的自由度是？',
    stemEn: 'What are the degrees of freedom of the sample standard deviation s?',
    options: ['n', 'n−1', 'n−2', '√n'],
    optionsEn: ['n', 'n−1', 'n−2', '√n'],
    answerIndex: 1,
    explanation: '样本方差用 n−1 做无偏校正（Bessel 校正），故 s 的自由度为 n−1。',
    explanationEn:
        'The sample variance uses n−1 for its unbiased (Bessel) correction, so s '
        'has n−1 degrees of freedom.',
  ),
  QuizQuestion(
    id: 'q2',
    topic: '描述统计',
    topicEn: 'Descriptive statistics',
    stem: '右偏分布通常满足？',
    stemEn: 'A right-skewed distribution usually satisfies:',
    options: ['均值 < 中位数', '均值 > 中位数', '均值 = 中位数', '标准差 = 0'],
    optionsEn: [
      'mean < median',
      'mean > median',
      'mean = median',
      'standard deviation = 0',
    ],
    answerIndex: 1,
    explanation: '右侧长尾把均值拉高，故均值大于中位数。',
    explanationEn:
        'The long right tail pulls the mean up, so the mean exceeds the median.',
  ),
  QuizQuestion(
    id: 'q3',
    topic: 't 检验',
    topicEn: 't-tests',
    stem: '独立样本 t 检验前的 Levene 检验 p=0.40，应如何处理？',
    stemEn:
        "Levene's test before an independent-samples t-test gives p = 0.40. What should you do?",
    options: [
      '拒绝做 t 检验',
      '假定方差齐性，使用合并方差 t 检验',
      '必须用 Welch 校正',
      '改用卡方检验',
    ],
    optionsEn: [
      'Refuse to run a t-test',
      'Assume equal variances and use the pooled-variance t-test',
      'You must use the Welch correction',
      'Switch to a chi-square test',
    ],
    answerIndex: 1,
    explanation: 'Levene p>0.05 不能拒绝方差齐性，可使用合并方差版本的 t 检验。',
    explanationEn:
        'Levene p > 0.05 means equal variances cannot be rejected, so the '
        'pooled-variance t-test is appropriate.',
  ),
  QuizQuestion(
    id: 'q4',
    topic: 't 检验',
    topicEn: 't-tests',
    stem: '同一组学生前后测成绩比较，最合适的检验是？',
    stemEn:
        'Comparing pre- and post-test scores of the same students: which test fits best?',
    options: ['独立样本 t', '配对样本 t', '单因素 ANOVA', '卡方独立性'],
    optionsEn: [
      'Independent-samples t',
      'Paired-samples t',
      'One-way ANOVA',
      'Chi-square test of independence',
    ],
    answerIndex: 1,
    explanation: '同一对象两次测量，观测不独立，应对差值做配对 t（等价单样本）。',
    explanationEn:
        'Two measurements on the same subjects are not independent; run a paired '
        't-test on the differences (equivalent to a one-sample test).',
  ),
  QuizQuestion(
    id: 'q5',
    topic: 't 检验',
    topicEn: 't-tests',
    stem: 'Cohen d ≈ 0.8 通常表示？',
    stemEn: "Cohen's d ≈ 0.8 usually indicates:",
    options: ['小效应', '中等效应', '大效应', '无效应'],
    optionsEn: ['small effect', 'medium effect', 'large effect', 'no effect'],
    answerIndex: 2,
    explanation: '惯例：0.2 小、0.5 中、0.8 大。',
    explanationEn: 'Convention: 0.2 small, 0.5 medium, 0.8 large.',
  ),
  QuizQuestion(
    id: 'q6',
    topic: '方差分析',
    topicEn: 'ANOVA',
    stem: '单因素 ANOVA 的 F 显著说明？',
    stemEn: 'A significant F in one-way ANOVA means:',
    options: [
      '所有组均值都不同',
      '至少有两组均值不同',
      '方差齐性成立',
      '数据服从正态',
    ],
    optionsEn: [
      'all group means differ',
      'at least two group means differ',
      'equal variances hold',
      'the data are normal',
    ],
    answerIndex: 1,
    explanation: 'F 显著只说明至少一对有差异，具体哪对需事后多重比较。',
    explanationEn:
        'A significant F only shows that at least one pair differs; post-hoc '
        'comparisons are needed to say which.',
  ),
  QuizQuestion(
    id: 'q7',
    topic: '方差分析',
    topicEn: 'ANOVA',
    stem: 'η² = 0.14 表示？',
    stemEn: 'What does η² = 0.14 mean?',
    options: [
      '模型解释了 14% 的变异',
      'p=0.14',
      '有 14 个组',
      '效应不存在',
    ],
    optionsEn: [
      'the model explains 14% of the variation',
      'p = 0.14',
      'there are 14 groups',
      'there is no effect',
    ],
    answerIndex: 0,
    explanation: 'η² 是组间平方和占总平方和比例，即解释方差比例。',
    explanationEn:
        'η² is the between-group sum of squares as a share of the total, i.e. the '
        'proportion of variance explained.',
  ),
  QuizQuestion(
    id: 'q8',
    topic: '相关',
    topicEn: 'Correlation',
    stem: 'Pearson r = −0.6 表示？',
    stemEn: 'Pearson r = −0.6 means:',
    options: [
      '强正相关',
      '中等负相关',
      '无相关',
      '因果关系',
    ],
    optionsEn: [
      'strong positive correlation',
      'moderate negative correlation',
      'no correlation',
      'causation',
    ],
    answerIndex: 1,
    explanation: '负号表方向，|r|=0.6 约中等强度；相关不能推因果。',
    explanationEn:
        'The sign gives the direction and |r| = 0.6 is moderate; correlation does '
        'not imply causation.',
  ),
  QuizQuestion(
    id: 'q9',
    topic: '相关',
    topicEn: 'Correlation',
    stem: '数据有明显异常值时更稳健的相关是？',
    stemEn: 'With clear outliers, which correlation is more robust?',
    options: ['Pearson', 'Spearman', 'φ 系数', 'η²'],
    optionsEn: ['Pearson', 'Spearman', 'the φ coefficient', 'η²'],
    answerIndex: 1,
    explanation: 'Spearman 基于秩，对异常值不敏感。',
    explanationEn: 'Spearman is rank-based and insensitive to outliers.',
  ),
  QuizQuestion(
    id: 'q10',
    topic: '回归',
    topicEn: 'Regression',
    stem: '回归中 VIF=12 提示？',
    stemEn: 'VIF = 12 in a regression indicates:',
    options: [
      '模型完美',
      '存在多重共线性风险',
      '残差不正态',
      '样本量过大',
    ],
    optionsEn: [
      'a perfect model',
      'a multicollinearity risk',
      'non-normal residuals',
      'too large a sample',
    ],
    answerIndex: 1,
    explanation: 'VIF>10 通常认为自变量间共线性较强，系数可能不稳。',
    explanationEn:
        'VIF > 10 usually means strong collinearity among predictors, so the '
        'coefficients may be unstable.',
  ),
  QuizQuestion(
    id: 'q11',
    topic: '回归',
    topicEn: 'Regression',
    stem: 'R²=0.64 意味着？',
    stemEn: 'R² = 0.64 means:',
    options: [
      '相关系数是 0.64',
      '模型解释了 64% 的 Y 变异',
      '预测误差 64%',
      '样本量 64',
    ],
    optionsEn: [
      'the correlation is 0.64',
      'the model explains 64% of the variation in Y',
      'the prediction error is 64%',
      'the sample size is 64',
    ],
    answerIndex: 1,
    explanation: 'R² 为决定系数，即解释方差比例；简单回归中 R²=r²。',
    explanationEn:
        'R² is the coefficient of determination, the proportion of variance '
        'explained; in simple regression R² = r².',
  ),
  QuizQuestion(
    id: 'q12',
    topic: '卡方',
    topicEn: 'Chi-square',
    stem: '列联表卡方检验的自由度是？',
    stemEn:
        'What are the degrees of freedom of a contingency-table chi-square test?',
    options: ['r+c', 'r×c', '(r−1)(c−1)', 'N−1'],
    optionsEn: ['r+c', 'r×c', '(r−1)(c−1)', 'N−1'],
    answerIndex: 2,
    explanation: '独立性检验 df=(r−1)(c−1)。',
    explanationEn: 'The independence test uses df = (r−1)(c−1).',
  ),
  QuizQuestion(
    id: 'q13',
    topic: '卡方',
    topicEn: 'Chi-square',
    stem: '期望频数大多小于 5 时应？',
    stemEn: 'When most expected counts are below 5, you should:',
    options: [
      '继续用卡方',
      '合并类别或用 Fisher 精确检验',
      '做 t 检验',
      '删除 50% 数据',
    ],
    optionsEn: [
      'keep using chi-square',
      "merge categories or use Fisher's exact test",
      'run a t-test',
      'delete 50% of the data',
    ],
    answerIndex: 1,
    explanation: '卡方大样本近似失效时，可合并相邻类别或用 Fisher 精确法。',
    explanationEn:
        'When the large-sample approximation breaks down, merge adjacent '
        "categories or use Fisher's exact method.",
  ),
  QuizQuestion(
    id: 'q14',
    topic: '非参数',
    topicEn: 'Non-parametric',
    stem: 'Mann-Whitney U 对应参数方法是？',
    stemEn: 'Mann-Whitney U is the non-parametric counterpart of...',
    options: ['配对 t', '独立样本 t', 'ANOVA', '回归'],
    optionsEn: [
      'the paired t-test',
      'the independent-samples t-test',
      'ANOVA',
      'regression',
    ],
    answerIndex: 1,
    explanation: '两独立样本的非参数替代是 Mann-Whitney U。',
    explanationEn:
        'Mann-Whitney U is the non-parametric alternative for two independent '
        'samples.',
  ),
  QuizQuestion(
    id: 'q15',
    topic: '非参数',
    topicEn: 'Non-parametric',
    stem: 'Wilcoxon 符号秩检验要求差值？',
    stemEn: 'The Wilcoxon signed-rank test requires the differences to be:',
    options: [
      '必须正态',
      '至少是有序/可比大小',
      '必须二分',
      '方差齐性',
    ],
    optionsEn: [
      'normally distributed',
      'at least ordered / comparable in size',
      'binary',
      'homoscedastic',
    ],
    answerIndex: 1,
    explanation: 'Wilcoxon 使用差值的秩，因此要求数据至少可排序。',
    explanationEn:
        'Wilcoxon ranks the differences, so the data must at least be sortable.',
  ),
  QuizQuestion(
    id: 'q16',
    topic: '信度',
    topicEn: 'Reliability',
    stem: "Cronbach α = 0.85 通常表示？",
    stemEn: "Cronbach's α = 0.85 usually means:",
    options: ['信度很差', '内部一致性良好', '效度很高', '样本无效'],
    optionsEn: [
      'poor reliability',
      'good internal consistency',
      'high validity',
      'an invalid sample',
    ],
    answerIndex: 1,
    explanation: 'α≥0.8 一般认为内部一致性良好；但 α 高不等于单维。',
    explanationEn:
        'α ≥ 0.8 is generally considered good internal consistency, but a high α '
        'does not imply unidimensionality.',
  ),
  QuizQuestion(
    id: 'q17',
    topic: '描述统计',
    topicEn: 'Descriptive statistics',
    stem: '95% 置信区间的意思是？',
    stemEn: 'What does a 95% confidence interval mean?',
    options: [
      '95% 的数据落在区间内',
      '重复抽样构造的区间约有 95% 覆盖真参数',
      '真值有 95% 概率在区间内',
      'p 值是 0.95',
    ],
    optionsEn: [
      '95% of the data fall inside the interval',
      'about 95% of intervals built by repeated sampling cover the true parameter',
      'the true value has a 95% probability of lying in the interval',
      'the p-value is 0.95',
    ],
    answerIndex: 1,
    explanation: '频率学派解释：区间构造程序的长期覆盖率约 95%。',
    explanationEn:
        'The frequentist reading: the interval-building procedure covers the true '
        'parameter about 95% of the time in the long run.',
  ),
  QuizQuestion(
    id: 'q18',
    topic: 't 检验',
    topicEn: 't-tests',
    stem: 'p=0.03，α=0.05，结论是？',
    stemEn: 'p = 0.03 with α = 0.05. The conclusion is:',
    options: [
      '拒绝 H₀，差异显著',
      '接受 H₀',
      '证明 H₁ 为真',
      '效应量一定很大',
    ],
    optionsEn: [
      'reject H₀, the difference is significant',
      'accept H₀',
      'prove H₁ is true',
      'the effect size must be large',
    ],
    answerIndex: 0,
    explanation: 'p<α 拒绝原假设；但不能「证明」备择为真，效应大小要看 d/CI。',
    explanationEn:
        'p < α rejects the null hypothesis, but that does not prove the '
        'alternative; use d or the confidence interval for magnitude.',
  ),
  QuizQuestion(
    id: 'q19',
    topic: '方差分析',
    topicEn: 'ANOVA',
    stem: 'ANOVA 显著后要做？',
    stemEn: 'After a significant ANOVA you should:',
    options: [
      '直接下结论说所有组不同',
      '事后多重比较定位差异',
      '删除数据',
      '改做回归',
    ],
    optionsEn: [
      'conclude that all groups differ',
      'run post-hoc comparisons to locate the differences',
      'delete data',
      'switch to regression',
    ],
    answerIndex: 1,
    explanation: '需要 Tukey/Bonferroni 等事后比较才知道哪两组不同。',
    explanationEn:
        'Tukey, Bonferroni or similar post-hoc tests are needed to know which '
        'pairs differ.',
  ),
  QuizQuestion(
    id: 'q20',
    topic: '回归',
    topicEn: 'Regression',
    stem: 'Durbin-Watson 接近 2 表示？',
    stemEn: 'A Durbin-Watson statistic near 2 means:',
    options: [
      '残差存在正自相关',
      '残差无一阶自相关',
      '存在异方差',
      'R²=2',
    ],
    optionsEn: [
      'positive autocorrelation in the residuals',
      'no first-order autocorrelation',
      'heteroscedasticity',
      'R² = 2',
    ],
    answerIndex: 1,
    explanation: 'DW≈2 无一阶自相关；接近 0 正相关，接近 4 负相关。',
    explanationEn:
        'DW ≈ 2 means no first-order autocorrelation; near 0 is positive, near 4 '
        'negative.',
  ),
];
