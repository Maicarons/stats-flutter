/// 学习内容数据
library;

class LearnLesson {
  final String id;
  final String title;
  final String category;
  final String summary;
  final List<LearnSection> sections;
  final List<String> formulas;
  const LearnLesson({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.sections,
    this.formulas = const [],
  });
}

class LearnSection {
  final String heading;
  final String body;
  const LearnSection({required this.heading, required this.body});
}

const learnLessons = <LearnLesson>[
  LearnLesson(
    id: 'desc',
    title: '描述统计基础',
    category: '入门',
    summary: '用均值、标准差、分位数刻画数据分布。',
    sections: [
      LearnSection(
        heading: '为什么需要描述统计',
        body: '原始数据往往过于庞杂。描述统计把一批观测压缩成少数几个数字：'
            '中心位置（均值、中位数）、离散程度（标准差、极差）、分布形态（偏度、峰度），'
            '让人一眼看出数据大致长什么样。',
      ),
      LearnSection(
        heading: '均值与中位数',
        body: '均值利用所有信息，但对极端值敏感；中位数只看位置，稳健但忽略数值大小。'
            '对称分布两者接近；右偏分布通常均值 > 中位数。',
      ),
      LearnSection(
        heading: '标准差与标准误',
        body: '标准差描述个体观测的波动；标准误 SE = SD/√n 描述样本均值的抽样波动。'
            '样本量越大，均值估计越稳，SE 越小。',
      ),
      LearnSection(
        heading: '偏度与峰度',
        body: '偏度>0 右偏（长尾在右），<0 左偏；峰度（超额）>0 比正态更尖锐厚尾，'
            '<0 更平坦。两者都接近 0 时可近似看作正态。',
      ),
    ],
    formulas: [
      '均值  x̄ = Σxᵢ / n',
      '样本标准差  s = √[ Σ(xᵢ−x̄)² / (n−1) ]',
      '标准误  SE = s / √n',
      '95% CI = x̄ ± t₀.₀₅,ₙ₋₁ · SE',
    ],
  ),
  LearnLesson(
    id: 'ttest',
    title: 't 检验三兄弟',
    category: '比较均值',
    summary: '单样本、独立样本、配对样本 t 检验的选择与解读。',
    sections: [
      LearnSection(
        heading: '共同逻辑',
        body: 't 检验都在问：「均值差异是否大到不太可能只是抽样误差？」'
            't = 差异 / 标准误。|t| 越大，p 越小。',
      ),
      LearnSection(
        heading: '单样本',
        body: '把一个样本均值与固定值（总体均值 μ₀）比较。'
            '例如：本班平均分是否显著高于 70 分？',
      ),
      LearnSection(
        heading: '独立样本',
        body: '两组互不相关的个体比较均值。先看 Levene 检验：'
            'p>0.05 可假定方差齐性，用合并方差；否则用 Welch 校正自由度。',
      ),
      LearnSection(
        heading: '配对样本',
        body: '同一组对象的两次测量（前后测、左右侧）。'
            '先求差值 d = x₁−x₂，再对 d 做单样本 t 检验（μ₀=0）。',
      ),
      LearnSection(
        heading: '效应量 Cohen d',
        body: 'd = 均值差 / 合并标准差。约 0.2 小、0.5 中、0.8 大。'
            'p 告诉你「是否显著」，d 告诉你「差多少」。',
      ),
    ],
    formulas: [
      '单样本  t = (x̄ − μ₀) / (s/√n)',
      '独立样本  t = (x̄₁−x̄₂) / √[ s²ₚ(1/n₁+1/n₂) ]',
      'Cohen d = (x̄₁−x̄₂) / sₚ',
    ],
  ),
  LearnLesson(
    id: 'anova',
    title: '单因素方差分析',
    category: '比较均值',
    summary: '一次比较多组均值，控制整体第一类错误率。',
    sections: [
      LearnSection(
        heading: '核心思想',
        body: 'ANOVA 把总变异拆成组间变异（处理效应 + 误差）与组内变异（纯误差）。'
            'F = 组间均方 / 组内均方。F 显著说明至少有两组不同。',
      ),
      LearnSection(
        heading: '前提假设',
        body: '独立性、正态性、方差齐性（Levene）。方差不齐时可用 Welch ANOVA 或非参数 Kruskal-Wallis。',
      ),
      LearnSection(
        heading: '效应量',
        body: 'η² = SS组间/SS总，表示处理解释了多大比例的变异。'
            'ω² 更保守，避免高估。事后多重比较（Tukey HSD）定位哪些组不同。',
      ),
    ],
    formulas: [
      'F = MS组间 / MS组内',
      'MS组间 = SS组间 / (k−1)',
      'η² = SS组间 / SS总',
    ],
  ),
  LearnLesson(
    id: 'cor',
    title: '相关分析',
    category: '关系',
    summary: '用 r 刻画两个连续变量的线性关联强度与方向。',
    sections: [
      LearnSection(
        heading: 'Pearson r',
        body: '取值 −1 到 1。|r| 越接近 1 线性关系越强。'
            '注意：相关不等于因果；非线性关系可能 r≈0 却高度依赖。',
      ),
      LearnSection(
        heading: 'Spearman ρ',
        body: '先转成秩再算 Pearson，刻画单调关系，对异常值更稳健。',
      ),
      LearnSection(
        heading: '显著性与 CI',
        body: '检验 H₀: ρ=0。样本量越大，同样的 r 越容易显著。'
            '报告 r 与 95% 置信区间（Fisher z 变换）比只报 p 更有价值。',
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
    category: '预测',
    summary: '用一条直线（或超平面）预测因变量。',
    sections: [
      LearnSection(
        heading: '模型',
        body: 'y = b₀ + b₁x + ε。b₁ 表示 x 每增加 1 单位，y 平均变化多少。'
            '多元回归时控制其他变量后看偏回归系数。',
      ),
      LearnSection(
        heading: 'R² 与 F',
        body: 'R² 表示模型解释的变异比例。调整 R² 惩罚多余自变量。'
            '整体 F 检验问「模型是否比只用均值更好」。',
      ),
      LearnSection(
        heading: '诊断',
        body: '看残差是否随机、有无异方差；VIF>10 提示多重共线性；'
            'DW 接近 2 说明残差无一阶自相关。',
      ),
    ],
    formulas: [
      'b₁ = Σ(xᵢ−x̄)(yᵢ−ȳ) / Σ(xᵢ−x̄)²',
      'b₀ = ȳ − b₁ x̄',
      'R² = 1 − SS残差 / SS总',
    ],
  ),
  LearnLesson(
    id: 'chi',
    title: '卡方检验',
    category: '分类',
    summary: '频数数据的拟合优度与独立性检验。',
    sections: [
      LearnSection(
        heading: '拟合优度',
        body: '观察频数与理论频数是否吻合。χ² = Σ (O−E)²/E。'
            '期望频数不宜过小（一般 ≥5）。',
      ),
      LearnSection(
        heading: '独立性',
        body: '列联表中行、列变量是否关联。df=(r−1)(c−1)。'
            '显著后看 Cramér V 或标准化残差定位哪些单元格贡献最大。',
      ),
      LearnSection(
        heading: '效应量',
        body: 'φ = √(χ²/N) 适用于 2×2；Cramér V = √(χ²/(N·min(r−1,c−1))) '
            '适用于更大表。',
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
    category: '稳健',
    summary: '不依赖正态假设的替代方案。',
    sections: [
      LearnSection(
        heading: '何时使用',
        body: '明显偏态、样本量很小、有序等级数据、方差严重不齐时，'
            '用秩检验更稳妥。',
      ),
      LearnSection(
        heading: '常用对照',
        body: '独立两样本 t → Mann-Whitney U；配对 t → Wilcoxon 符号秩；'
            '单因素 ANOVA → Kruskal-Wallis；配对多组 → Friedman。',
      ),
      LearnSection(
        heading: '符号检验',
        body: '只看差值正负，不看大小，最稳健也最不灵敏。',
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
    category: '测量',
    summary: "Cronbach α 评估内部一致性。",
    sections: [
      LearnSection(
        heading: '什么是信度',
        body: '信度 = 测量结果的一致性/可重复性。'
            '内部一致性反映题目是否在测同一构念。',
      ),
      LearnSection(
        heading: "Cronbach α",
        body: 'α 通常 ≥0.7 可接受，≥0.8 良好。'
            '题目过多也会抬高 α，需结合「校正项总相关」与「删除项后 α」诊断。',
      ),
      LearnSection(
        heading: '注意事项',
        body: 'α 高不代表单维；高 α 也可能来自冗余题目。'
            '必要时做因子分析验证结构。',
      ),
    ],
    formulas: [
      'α = (k/(k−1)) · (1 − Σsᵢ² / sₜ²)',
    ],
  ),
];
