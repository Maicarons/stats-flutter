/// 学习内容数据（中英双语）
library;

class LearnLesson {
  final String id;
  final String title;
  final String titleEn;
  final String category;
  final String categoryEn;
  final String summary;
  final String summaryEn;
  final List<LearnSection> sections;
  final List<String> formulas;
  final List<String> formulasEn;

  const LearnLesson({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.category,
    required this.categoryEn,
    required this.summary,
    required this.summaryEn,
    required this.sections,
    this.formulas = const [],
    this.formulasEn = const [],
  });

  String titleFor(bool zh) => zh ? title : titleEn;
  String categoryFor(bool zh) => zh ? category : categoryEn;
  String summaryFor(bool zh) => zh ? summary : summaryEn;
  List<String> formulasFor(bool zh) =>
      (zh || formulasEn.isEmpty) ? formulas : formulasEn;
}

class LearnSection {
  final String heading;
  final String headingEn;
  final String body;
  final String bodyEn;

  const LearnSection({
    required this.heading,
    required this.headingEn,
    required this.body,
    required this.bodyEn,
  });

  String headingFor(bool zh) => zh ? heading : headingEn;
  String bodyFor(bool zh) => zh ? body : bodyEn;
}

const learnLessons = <LearnLesson>[
  LearnLesson(
    id: 'desc',
    title: '描述统计基础',
    titleEn: 'Descriptive statistics',
    category: '入门',
    categoryEn: 'Getting started',
    summary: '用均值、标准差、分位数刻画数据分布。',
    summaryEn:
        'Describe a distribution with the mean, standard deviation and quantiles.',
    sections: [
      LearnSection(
        heading: '为什么需要描述统计',
        headingEn: 'Why descriptive statistics',
        body: '原始数据往往过于庞杂。描述统计把一批观测压缩成少数几个数字：'
            '中心位置（均值、中位数）、离散程度（标准差、极差）、分布形态（偏度、峰度），'
            '让人一眼看出数据大致长什么样。',
        bodyEn:
            'Raw data is often overwhelming. Descriptive statistics compress a batch '
            'of observations into a few numbers: central location (mean, median), '
            'spread (standard deviation, range) and shape (skewness, kurtosis) — so '
            'you can see at a glance what the data look like.',
      ),
      LearnSection(
        heading: '均值与中位数',
        headingEn: 'Mean and median',
        body: '均值利用所有信息，但对极端值敏感；中位数只看位置，稳健但忽略数值大小。'
            '对称分布两者接近；右偏分布通常均值 > 中位数。',
        bodyEn:
            'The mean uses all the information but is sensitive to extremes; the '
            'median only looks at position, so it is robust but ignores magnitude. '
            'For symmetric distributions the two are close; for right-skewed data the '
            'mean is usually greater than the median.',
      ),
      LearnSection(
        heading: '标准差与标准误',
        headingEn: 'Standard deviation and standard error',
        body: '标准差描述个体观测的波动；标准误 SE = SD/√n 描述样本均值的抽样波动。'
            '样本量越大，均值估计越稳，SE 越小。',
        bodyEn:
            'The standard deviation describes how individual observations vary; the '
            'standard error SE = SD/√n describes how the sample mean varies from '
            'sample to sample. Larger samples give more stable mean estimates and a '
            'smaller SE.',
      ),
      LearnSection(
        heading: '偏度与峰度',
        headingEn: 'Skewness and kurtosis',
        body: '偏度>0 右偏（长尾在右），<0 左偏；峰度（超额）>0 比正态更尖锐厚尾，'
            '<0 更平坦。两者都接近 0 时可近似看作正态。',
        bodyEn:
            'Skewness > 0 is right-skewed (long tail on the right), < 0 left-skewed. '
            'Excess kurtosis > 0 is more peaked with heavier tails than the normal '
            'distribution, < 0 flatter. When both are near 0 the data can be treated '
            'as roughly normal.',
      ),
    ],
    formulas: [
      '均值  x̄ = Σxᵢ / n',
      '样本标准差  s = √[ Σ(xᵢ−x̄)² / (n−1) ]',
      '标准误  SE = s / √n',
      '95% CI = x̄ ± t₀.₀₅,ₙ₋₁ · SE',
    ],
    formulasEn: [
      'Mean  x̄ = Σxᵢ / n',
      'Sample SD  s = √[ Σ(xᵢ−x̄)² / (n−1) ]',
      'Standard error  SE = s / √n',
      '95% CI = x̄ ± t₀.₀₅,ₙ₋₁ · SE',
    ],
  ),
  LearnLesson(
    id: 'ttest',
    title: 't 检验三兄弟',
    titleEn: 'The t-test family',
    category: '比较均值',
    categoryEn: 'Comparing means',
    summary: '单样本、独立样本、配对样本 t 检验的选择与解读。',
    summaryEn:
        'Choosing and reading one-sample, independent-samples and paired-samples t-tests.',
    sections: [
      LearnSection(
        heading: '共同逻辑',
        headingEn: 'Shared logic',
        body: 't 检验都在问：「均值差异是否大到不太可能只是抽样误差？」'
            't = 差异 / 标准误。|t| 越大，p 越小。',
        bodyEn:
            'Every t-test asks the same question: is the mean difference too large to '
            'be explained by sampling error alone? t = difference / standard error. '
            'The larger |t| is, the smaller p.',
      ),
      LearnSection(
        heading: '单样本',
        headingEn: 'One sample',
        body: '把一个样本均值与固定值（总体均值 μ₀）比较。'
            '例如：本班平均分是否显著高于 70 分？',
        bodyEn:
            'Compare a sample mean with a fixed value (population mean μ₀). For '
            'example: is this class averaging significantly above 70?',
      ),
      LearnSection(
        heading: '独立样本',
        headingEn: 'Independent samples',
        body: '两组互不相关的个体比较均值。先看 Levene 检验：'
            'p>0.05 可假定方差齐性，用合并方差；否则用 Welch 校正自由度。',
        bodyEn:
            'Compare the means of two unrelated groups. Check Levene\'s test first: '
            'p > 0.05 allows assuming equal variances and using the pooled variance; '
            'otherwise use the Welch correction for degrees of freedom.',
      ),
      LearnSection(
        heading: '配对样本',
        headingEn: 'Paired samples',
        body: '同一组对象的两次测量（前后测、左右侧）。'
            '先求差值 d = x₁−x₂，再对 d 做单样本 t 检验（μ₀=0）。',
        bodyEn:
            'Two measurements on the same subjects (pre/post, left/right). Compute '
            'the difference d = x₁ − x₂, then run a one-sample t-test on d with '
            'μ₀ = 0.',
      ),
      LearnSection(
        heading: '效应量 Cohen d',
        headingEn: 'Effect size: Cohen\'s d',
        body: 'd = 均值差 / 合并标准差。约 0.2 小、0.5 中、0.8 大。'
            'p 告诉你「是否显著」，d 告诉你「差多少」。',
        bodyEn:
            'd = mean difference / pooled SD. Roughly 0.2 small, 0.5 medium, 0.8 '
            'large. p tells you whether the result is significant; d tells you how '
            'big the difference is.',
      ),
    ],
    formulas: [
      '单样本  t = (x̄ − μ₀) / (s/√n)',
      '独立样本  t = (x̄₁−x̄₂) / √[ s²ₚ(1/n₁+1/n₂) ]',
      'Cohen d = (x̄₁−x̄₂) / sₚ',
    ],
    formulasEn: [
      'One sample  t = (x̄ − μ₀) / (s/√n)',
      'Independent  t = (x̄₁−x̄₂) / √[ s²ₚ(1/n₁+1/n₂) ]',
      "Cohen's d = (x̄₁−x̄₂) / sₚ",
    ],
  ),
  LearnLesson(
    id: 'anova',
    title: '单因素方差分析',
    titleEn: 'One-way ANOVA',
    category: '比较均值',
    categoryEn: 'Comparing means',
    summary: '一次比较多组均值，控制整体第一类错误率。',
    summaryEn:
        'Compare several group means at once while controlling the family-wise Type I error rate.',
    sections: [
      LearnSection(
        heading: '核心思想',
        headingEn: 'Core idea',
        body: 'ANOVA 把总变异拆成组间变异（处理效应 + 误差）与组内变异（纯误差）。'
            'F = 组间均方 / 组内均方。F 显著说明至少有两组不同。',
        bodyEn:
            'ANOVA splits total variation into between-group variation (treatment '
            'effect + error) and within-group variation (pure error). '
            'F = between-group mean square / within-group mean square. A significant '
            'F means at least two groups differ.',
      ),
      LearnSection(
        heading: '前提假设',
        headingEn: 'Assumptions',
        body: '独立性、正态性、方差齐性（Levene）。方差不齐时可用 Welch ANOVA 或非参数 Kruskal-Wallis。',
        bodyEn:
            'Independence, normality and homogeneity of variance (Levene). With '
            'unequal variances use Welch\'s ANOVA or the non-parametric '
            'Kruskal-Wallis test.',
      ),
      LearnSection(
        heading: '效应量',
        headingEn: 'Effect size',
        body: 'η² = SS组间/SS总，表示处理解释了多大比例的变异。'
            'ω² 更保守，避免高估。事后多重比较（Tukey HSD）定位哪些组不同。',
        bodyEn:
            'η² = SS_between / SS_total, the share of variation explained by the '
            'treatment. ω² is more conservative and avoids overestimation. Post-hoc '
            'comparisons (Tukey HSD) locate which groups differ.',
      ),
    ],
    formulas: [
      'F = MS组间 / MS组内',
      'MS组间 = SS组间 / (k−1)',
      'η² = SS组间 / SS总',
    ],
    formulasEn: [
      'F = MS_between / MS_within',
      'MS_between = SS_between / (k−1)',
      'η² = SS_between / SS_total',
    ],
  ),
  LearnLesson(
    id: 'cor',
    title: '相关分析',
    titleEn: 'Correlation',
    category: '关系',
    categoryEn: 'Relationships',
    summary: '用 r 刻画两个连续变量的线性关联强度与方向。',
    summaryEn:
        'Use r to describe the strength and direction of a linear association between two continuous variables.',
    sections: [
      LearnSection(
        heading: 'Pearson r',
        headingEn: 'Pearson r',
        body: '取值 −1 到 1。|r| 越接近 1 线性关系越强。'
            '注意：相关不等于因果；非线性关系可能 r≈0 却高度依赖。',
        bodyEn:
            'Ranges from −1 to 1; the closer |r| is to 1, the stronger the linear '
            'relationship. Note that correlation is not causation, and a strong '
            'non-linear relationship can still give r ≈ 0.',
      ),
      LearnSection(
        heading: 'Spearman ρ',
        headingEn: 'Spearman ρ',
        body: '先转成秩再算 Pearson，刻画单调关系，对异常值更稳健。',
        bodyEn:
            'Convert to ranks first, then apply Pearson. It captures monotonic '
            'relationships and is more robust to outliers.',
      ),
      LearnSection(
        heading: '显著性与 CI',
        headingEn: 'Significance and confidence intervals',
        body: '检验 H₀: ρ=0。样本量越大，同样的 r 越容易显著。'
            '报告 r 与 95% 置信区间（Fisher z 变换）比只报 p 更有价值。',
        bodyEn:
            'Tests H₀: ρ = 0. Larger samples make the same r easier to call '
            'significant. Reporting r with a 95% confidence interval (Fisher z '
            'transform) is more informative than p alone.',
      ),
    ],
    formulas: [
      'r = Σ(xᵢ−x̄)(yᵢ−ȳ) / √[ Σ(xᵢ−x̄)² Σ(yᵢ−ȳ)² ]',
      't = r √[(n−2)/(1−r²)],  df = n−2',
    ],
  ),
  LearnLesson(
    id: 'reg',
    title: '线性回归',
    titleEn: 'Linear regression',
    category: '预测',
    categoryEn: 'Prediction',
    summary: '用一条直线（或超平面）预测因变量。',
    summaryEn:
        'Predict a dependent variable with a straight line (or a hyperplane).',
    sections: [
      LearnSection(
        heading: '模型',
        headingEn: 'The model',
        body: 'y = b₀ + b₁x + ε。b₁ 表示 x 每增加 1 单位，y 平均变化多少。'
            '多元回归时控制其他变量后看偏回归系数。',
        bodyEn:
            'y = b₀ + b₁x + ε. b₁ is the average change in y for a one-unit increase '
            'in x. In multiple regression, partial coefficients describe each '
            'predictor while holding the others constant.',
      ),
      LearnSection(
        heading: 'R² 与 F',
        headingEn: 'R² and F',
        body: 'R² 表示模型解释的变异比例。调整 R² 惩罚多余自变量。'
            '整体 F 检验问「模型是否比只用均值更好」。',
        bodyEn:
            'R² is the share of variation explained by the model; adjusted R² '
            'penalises extra predictors. The overall F test asks whether the model '
            'beats using the mean alone.',
      ),
      LearnSection(
        heading: '诊断',
        headingEn: 'Diagnostics',
        body: '看残差是否随机、有无异方差；VIF>10 提示多重共线性；'
            'DW 接近 2 说明残差无一阶自相关。',
        bodyEn:
            'Check that residuals look random with no heteroscedasticity; VIF > 10 '
            'suggests multicollinearity; a Durbin-Watson near 2 means no '
            'first-order autocorrelation.',
      ),
    ],
    formulas: [
      'b₁ = Σ(xᵢ−x̄)(yᵢ−ȳ) / Σ(xᵢ−x̄)²',
      'b₀ = ȳ − b₁ x̄',
      'R² = 1 − SS残差 / SS总',
    ],
    formulasEn: [
      'b₁ = Σ(xᵢ−x̄)(yᵢ−ȳ) / Σ(xᵢ−x̄)²',
      'b₀ = ȳ − b₁ x̄',
      'R² = 1 − SS_residual / SS_total',
    ],
  ),
  LearnLesson(
    id: 'chi',
    title: '卡方检验',
    titleEn: 'Chi-square tests',
    category: '分类',
    categoryEn: 'Categorical data',
    summary: '频数数据的拟合优度与独立性检验。',
    summaryEn: 'Goodness-of-fit and independence tests for frequency data.',
    sections: [
      LearnSection(
        heading: '拟合优度',
        headingEn: 'Goodness of fit',
        body: '观察频数与理论频数是否吻合。χ² = Σ (O−E)²/E。'
            '期望频数不宜过小（一般 ≥5）。',
        bodyEn:
            'Do observed frequencies match the expected ones? χ² = Σ (O−E)²/E. '
            'Expected counts should not be too small (generally ≥ 5).',
      ),
      LearnSection(
        heading: '独立性',
        headingEn: 'Independence',
        body: '列联表中行、列变量是否关联。df=(r−1)(c−1)。'
            '显著后看 Cramér V 或标准化残差定位哪些单元格贡献最大。',
        bodyEn:
            'Are the row and column variables of a contingency table associated? '
            'df = (r−1)(c−1). After significance, use Cramér\'s V or standardised '
            'residuals to see which cells contribute most.',
      ),
      LearnSection(
        heading: '效应量',
        headingEn: 'Effect size',
        body: 'φ = √(χ²/N) 适用于 2×2；Cramér V = √(χ²/(N·min(r−1,c−1))) '
            '适用于更大表。',
        bodyEn:
            'φ = √(χ²/N) applies to 2×2 tables; '
            'Cramér\'s V = √(χ²/(N·min(r−1, c−1))) applies to larger tables.',
      ),
    ],
    formulas: [
      'χ² = Σ (Oᵢ−Eᵢ)² / Eᵢ',
      "Cramér's V = √[ χ² / (N · (min(r,c)−1)) ]",
    ],
  ),
  LearnLesson(
    id: 'nonparam',
    title: '非参数检验',
    titleEn: 'Non-parametric tests',
    category: '稳健',
    categoryEn: 'Robust methods',
    summary: '不依赖正态假设的替代方案。',
    summaryEn: 'Alternatives that do not rely on the normality assumption.',
    sections: [
      LearnSection(
        heading: '何时使用',
        headingEn: 'When to use them',
        body: '明显偏态、样本量很小、有序等级数据、方差严重不齐时，'
            '用秩检验更稳妥。',
        bodyEn:
            'With clearly skewed data, very small samples, ordered/ordinal data or '
            'severe variance heterogeneity, rank-based tests are the safer choice.',
      ),
      LearnSection(
        heading: '常用对照',
        headingEn: 'Common counterparts',
        body: '独立两样本 t → Mann-Whitney U；配对 t → Wilcoxon 符号秩；'
            '单因素 ANOVA → Kruskal-Wallis；配对多组 → Friedman。',
        bodyEn:
            'Independent t → Mann-Whitney U; paired t → Wilcoxon signed-rank; '
            'one-way ANOVA → Kruskal-Wallis; repeated measures → Friedman.',
      ),
      LearnSection(
        heading: '符号检验',
        headingEn: 'The sign test',
        body: '只看差值正负，不看大小，最稳健也最不灵敏。',
        bodyEn:
            'It looks only at whether each difference is positive or negative, not '
            'its size: the most robust but least sensitive option.',
      ),
    ],
    formulas: [
      'Mann-Whitney  U = R₁ − n₁(n₁+1)/2',
      'Kruskal-Wallis  H = [12/(N(N+1))] Σ nⱼ R̄ⱼ² − 3(N+1)',
    ],
  ),
  LearnLesson(
    id: 'alpha',
    title: '信度与量表',
    titleEn: 'Reliability and scales',
    category: '测量',
    categoryEn: 'Measurement',
    summary: "Cronbach α 评估内部一致性。",
    summaryEn: "Cronbach's α assesses internal consistency.",
    sections: [
      LearnSection(
        heading: '什么是信度',
        headingEn: 'What reliability means',
        body: '信度 = 测量结果的一致性/可重复性。'
            '内部一致性反映题目是否在测同一构念。',
        bodyEn:
            'Reliability is the consistency and repeatability of a measurement. '
            'Internal consistency reflects whether the items measure the same '
            'construct.',
      ),
      LearnSection(
        heading: "Cronbach α",
        headingEn: "Cronbach's α",
        body: 'α 通常 ≥0.7 可接受，≥0.8 良好。'
            '题目过多也会抬高 α，需结合「校正项总相关」与「删除项后 α」诊断。',
        bodyEn:
            'α ≥ 0.7 is usually acceptable and ≥ 0.8 good. Too many items also '
            'inflate α, so combine it with corrected item-total correlations and '
            'alpha-if-item-deleted diagnostics.',
      ),
      LearnSection(
        heading: '注意事项',
        headingEn: 'Caveats',
        body: 'α 高不代表单维；高 α 也可能来自冗余题目。'
            '必要时做因子分析验证结构。',
        bodyEn:
            'A high α does not imply unidimensionality, and it can come from '
            'redundant items. Run a factor analysis when the structure matters.',
      ),
    ],
    formulas: [
      'α = (k/(k−1)) · (1 − Σsᵢ² / sₜ²)',
    ],
  ),
];
