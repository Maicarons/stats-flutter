/// 题库
library;

class QuizQuestion {
  final String id;
  final String topic;
  final String stem;
  final List<String> options;
  final int answerIndex;
  final String explanation;
  const QuizQuestion({
    required this.id,
    required this.topic,
    required this.stem,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });
}

const quizBank = <QuizQuestion>[
  QuizQuestion(
    id: 'q1',
    topic: '描述统计',
    stem: '样本标准差 s 的自由度是？',
    options: ['n', 'n−1', 'n−2', '√n'],
    answerIndex: 1,
    explanation: '样本方差用 n−1 做无偏校正（Bessel 校正），故 s 的自由度为 n−1。',
  ),
  QuizQuestion(
    id: 'q2',
    topic: '描述统计',
    stem: '右偏分布通常满足？',
    options: ['均值 < 中位数', '均值 > 中位数', '均值 = 中位数', '标准差 = 0'],
    answerIndex: 1,
    explanation: '右侧长尾把均值拉高，故均值大于中位数。',
  ),
  QuizQuestion(
    id: 'q3',
    topic: 't 检验',
    stem: '独立样本 t 检验前的 Levene 检验 p=0.40，应如何处理？',
    options: [
      '拒绝做 t 检验',
      '假定方差齐性，使用合并方差 t 检验',
      '必须用 Welch 校正',
      '改用卡方检验',
    ],
    answerIndex: 1,
    explanation: 'Levene p>0.05 不能拒绝方差齐性，可使用合并方差版本的 t 检验。',
  ),
  QuizQuestion(
    id: 'q4',
    topic: 't 检验',
    stem: '同一组学生前后测成绩比较，最合适的检验是？',
    options: ['独立样本 t', '配对样本 t', '单因素 ANOVA', '卡方独立性'],
    answerIndex: 1,
    explanation: '同一对象两次测量，观测不独立，应对差值做配对 t（等价单样本）。',
  ),
  QuizQuestion(
    id: 'q5',
    topic: 't 检验',
    stem: 'Cohen d ≈ 0.8 通常表示？',
    options: ['小效应', '中等效应', '大效应', '无效应'],
    answerIndex: 2,
    explanation: '惯例：0.2 小、0.5 中、0.8 大。',
  ),
  QuizQuestion(
    id: 'q6',
    topic: '方差分析',
    stem: '单因素 ANOVA 的 F 显著说明？',
    options: [
      '所有组均值都不同',
      '至少有两组均值不同',
      '方差齐性成立',
      '数据服从正态',
    ],
    answerIndex: 1,
    explanation: 'F 显著只说明至少一对有差异，具体哪对需事后多重比较。',
  ),
  QuizQuestion(
    id: 'q7',
    topic: '方差分析',
    stem: 'η² = 0.14 表示？',
    options: [
      '模型解释了 14% 的变异',
      'p=0.14',
      '有 14 个组',
      '效应不存在',
    ],
    answerIndex: 0,
    explanation: 'η² 是组间平方和占总平方和比例，即解释方差比例。',
  ),
  QuizQuestion(
    id: 'q8',
    topic: '相关',
    stem: 'Pearson r = −0.6 表示？',
    options: [
      '强正相关',
      '中等负相关',
      '无相关',
      '因果关系',
    ],
    answerIndex: 1,
    explanation: '负号表方向，|r|=0.6 约中等强度；相关不能推因果。',
  ),
  QuizQuestion(
    id: 'q9',
    topic: '相关',
    stem: '数据有明显异常值时更稳健的相关是？',
    options: ['Pearson', 'Spearman', 'φ 系数', 'η²'],
    answerIndex: 1,
    explanation: 'Spearman 基于秩，对异常值不敏感。',
  ),
  QuizQuestion(
    id: 'q10',
    topic: '回归',
    stem: '回归中 VIF=12 提示？',
    options: [
      '模型完美',
      '存在多重共线性风险',
      '残差不正态',
      '样本量过大',
    ],
    answerIndex: 1,
    explanation: 'VIF>10 通常认为自变量间共线性较强，系数可能不稳。',
  ),
  QuizQuestion(
    id: 'q11',
    topic: '回归',
    stem: 'R²=0.64 意味着？',
    options: [
      '相关系数是 0.64',
      '模型解释了 64% 的 Y 变异',
      '预测误差 64%',
      '样本量 64',
    ],
    answerIndex: 1,
    explanation: 'R² 为决定系数，即解释方差比例；简单回归中 R²=r²。',
  ),
  QuizQuestion(
    id: 'q12',
    topic: '卡方',
    stem: '列联表卡方检验的自由度是？',
    options: ['r+c', 'r×c', '(r−1)(c−1)', 'N−1'],
    answerIndex: 2,
    explanation: '独立性检验 df=(r−1)(c−1)。',
  ),
  QuizQuestion(
    id: 'q13',
    topic: '卡方',
    stem: '期望频数大多小于 5 时应？',
    options: [
      '继续用卡方',
      '合并类别或用 Fisher 精确检验',
      '做 t 检验',
      '删除 50% 数据',
    ],
    answerIndex: 1,
    explanation: '卡方大样本近似失效时，可合并相邻类别或用 Fisher 精确法。',
  ),
  QuizQuestion(
    id: 'q14',
    topic: '非参数',
    stem: 'Mann-Whitney U 对应参数方法是？',
    options: ['配对 t', '独立样本 t', 'ANOVA', '回归'],
    answerIndex: 1,
    explanation: '两独立样本的非参数替代是 Mann-Whitney U。',
  ),
  QuizQuestion(
    id: 'q15',
    topic: '非参数',
    stem: 'Wilcoxon 符号秩检验要求差值？',
    options: [
      '必须正态',
      '至少是有序/可比大小',
      '必须二分',
      '方差齐性',
    ],
    answerIndex: 1,
    explanation: 'Wilcoxon 使用差值的秩，因此要求数据至少可排序。',
  ),
  QuizQuestion(
    id: 'q16',
    topic: '信度',
    stem: "Cronbach α = 0.85 通常表示？",
    options: ['信度很差', '内部一致性良好', '效度很高', '样本无效'],
    answerIndex: 1,
    explanation: 'α≥0.8 一般认为内部一致性良好；但 α 高不等于单维。',
  ),
  QuizQuestion(
    id: 'q17',
    topic: '描述统计',
    stem: '95% 置信区间的意思是？',
    options: [
      '95% 的数据落在区间内',
      '重复抽样构造的区间约有 95% 覆盖真参数',
      '真值有 95% 概率在区间内',
      'p 值是 0.95',
    ],
    answerIndex: 1,
    explanation: '频率学派解释：区间构造程序的长期覆盖率约 95%。',
  ),
  QuizQuestion(
    id: 'q18',
    topic: 't 检验',
    stem: 'p=0.03，α=0.05，结论是？',
    options: [
      '拒绝 H₀，差异显著',
      '接受 H₀',
      '证明 H₁ 为真',
      '效应量一定很大',
    ],
    answerIndex: 0,
    explanation: 'p<α 拒绝原假设；但不能「证明」备择为真，效应大小要看 d/CI。',
  ),
  QuizQuestion(
    id: 'q19',
    topic: '方差分析',
    stem: 'ANOVA 显著后要做？',
    options: [
      '直接下结论说所有组不同',
      '事后多重比较定位差异',
      '删除数据',
      '改做回归',
    ],
    answerIndex: 1,
    explanation: '需要 Tukey/Bonferroni 等事后比较才知道哪两组不同。',
  ),
  QuizQuestion(
    id: 'q20',
    topic: '回归',
    stem: 'Durbin-Watson 接近 2 表示？',
    options: [
      '残差存在正自相关',
      '残差无一阶自相关',
      '存在异方差',
      'R²=2',
    ],
    answerIndex: 1,
    explanation: 'DW≈2 无一阶自相关；接近 0 正相关，接近 4 负相关。',
  ),
];
