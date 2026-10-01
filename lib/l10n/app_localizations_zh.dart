// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Stats-flutter';

  @override
  String get tabData => '数据';

  @override
  String get tabProjects => '工程';

  @override
  String get tabAnalysis => '分析';

  @override
  String get tabLearn => '学习';

  @override
  String get tabQuiz => '测试';

  @override
  String get tabSettings => '设置';

  @override
  String get navHome => '首页';

  @override
  String get dataView => '数据视图';

  @override
  String get variableView => '变量视图';

  @override
  String get searchHint => '搜索个案 / 变量…';

  @override
  String get cases => '个案';

  @override
  String get variables => '变量';

  @override
  String get addCase => '个案';

  @override
  String get addVariable => '添加变量';

  @override
  String get variableName => '变量名';

  @override
  String get loadDemo => '加载示例数据';

  @override
  String get importCsv => '导入 CSV…';

  @override
  String get exportCsv => '导出 CSV';

  @override
  String get showValueLabels => '显示值标签';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get ok => '确定';

  @override
  String get close => '关闭';

  @override
  String get reset => '重置';

  @override
  String get resetConfirm => '确定要将所有设置和数据恢复默认吗？';

  @override
  String get resetDone => '设置与数据已重置';

  @override
  String get about => '关于';

  @override
  String get aboutTitle => '关于 StatLab';

  @override
  String get aboutDesc => '移动优先的工程化统计分析套件，内置学习与测试模块。';

  @override
  String get version => '版本';

  @override
  String get settings => '设置';

  @override
  String get appearance => '外观';

  @override
  String get themeMode => '主题模式';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeColor => '主题色';

  @override
  String get language => '语言';

  @override
  String get langSystem => '跟随系统';

  @override
  String get langEnglish => 'English';

  @override
  String get langChinese => '中文';

  @override
  String get analysis => '分析';

  @override
  String get runAnalysis => '运行分析';

  @override
  String get running => '计算中…';

  @override
  String get shareReport => '分享报告';

  @override
  String get params => '分析参数';

  @override
  String get selectVariables => '变量（可多选）';

  @override
  String get analysisVariable => '分析变量';

  @override
  String get groupVariable => '分组变量';

  @override
  String get pairVariables => '配对变量（选 2 个）';

  @override
  String get testValue => '检验值 μ₀';

  @override
  String get dependentVar => '因变量 Y';

  @override
  String get independentVar => '自变量 X';

  @override
  String get rowVariable => '行变量';

  @override
  String get columnVariable => '列变量';

  @override
  String get clusterCount => '簇数 k';

  @override
  String get error => '错误';

  @override
  String get failed => '运行失败';

  @override
  String get notImplemented => '该分析正在开发中，可先使用描述统计与 t 检验。';

  @override
  String get pleaseSelectVars => '请至少选择一个变量';

  @override
  String get pleaseSelectGroup => '请选择分析变量与分组变量';

  @override
  String get pleaseSelectXY => '请选择 Y 与 X';

  @override
  String get needTwoGroups => '分组变量至少需要 2 组';

  @override
  String get needTwoVars => '请至少选择 2 个变量';

  @override
  String get learnTitle => '统计学习';

  @override
  String get learnTagline => '从概念到公式';

  @override
  String get learnIntro => '用短课掌握假设检验、回归、非参数与信度等核心方法。学完可直接去「测试」练手。';

  @override
  String get coreFormulas => '核心公式';

  @override
  String get quizTitle => '统计测试';

  @override
  String get quizTagline => '随机抽题 · 即时判分';

  @override
  String get quizIntro => '题库覆盖描述统计、t 检验、ANOVA、相关、回归、卡方、非参数与信度。';

  @override
  String get questionCount => '题目数量';

  @override
  String get questionsUnit => '题';

  @override
  String get startQuiz => '开始测试';

  @override
  String get next => '下一题';

  @override
  String get prev => '上一题';

  @override
  String get submit => '交卷';

  @override
  String get retry => '再来一套';

  @override
  String get backToSetup => '返回设置';

  @override
  String get scoreTitle => '本次得分';

  @override
  String get quizGreat => '非常棒！可以挑战更高题量或去数据分析里实践。';

  @override
  String get quizGood => '还不错，建议复习错题解析。';

  @override
  String get quizLow => '建议先到「学习」模块巩固概念再来测试。';

  @override
  String get answerReview => '答题回顾';

  @override
  String get correct => '正确';

  @override
  String get yourChoice => '你的选择';

  @override
  String get explanation => '解析';

  @override
  String questionOf(int n, int total) {
    return '第 $n / $total 题';
  }

  @override
  String importSuccess(int cases, int vars) {
    return '已导入 $cases 个案 × $vars 变量';
  }

  @override
  String importFailed(String e) {
    return '导入失败：$e';
  }

  @override
  String exportFailed(String e) {
    return '导出失败：$e';
  }

  @override
  String get copied => '已复制';

  @override
  String editCase(int n) {
    return '编辑个案 #$n';
  }

  @override
  String get label => '标签';

  @override
  String get measure => '测量';

  @override
  String get type => '类型';

  @override
  String get decimals => '小数位';

  @override
  String get valueLabels => '值标签';

  @override
  String get doubleClickEdit => '双击单元格编辑';

  @override
  String get cellEditHint => 'Enter 下移 · Tab 右移 · Esc 取消';

  @override
  String get row => '行';

  @override
  String get col => '列';

  @override
  String get deleteCase => '删除个案';

  @override
  String get insertCase => '插入个案';

  @override
  String get duplicateCase => '复制个案';

  @override
  String get clearCell => '清空单元格';

  @override
  String get undo => '撤销';

  @override
  String get redo => '重做';

  @override
  String get importData => '导入';

  @override
  String get exportData => '导出';

  @override
  String get importSav => '导入 SPSS .sav…';

  @override
  String get importExcel => '导入 Excel…';

  @override
  String get transformMenu => '数据变换…';

  @override
  String get syntaxEditor => '语法编辑器…';

  @override
  String get weightCases => '加权个案…';

  @override
  String get splitFile => '拆分文件…';

  @override
  String get findCase => '查找个案…';

  @override
  String get notWeighted => '不加权';

  @override
  String weightedBy(String v) {
    return '加权变量: $v';
  }

  @override
  String get weightOff => '已取消加权';

  @override
  String get noSplit => '不分组';

  @override
  String splitBy(String v) {
    return '拆分变量: $v';
  }

  @override
  String get splitOff => '已关闭拆分';

  @override
  String get find => '查找';

  @override
  String get findHint => '输入要查找的内容…';

  @override
  String notFound(String q) {
    return '未找到「$q」';
  }

  @override
  String foundN(int n, String list, String more) {
    return '找到 $n 处：$list$more';
  }

  @override
  String get noValueLabels => '尚未定义值标签';

  @override
  String get editValueLabels => '编辑值标签';

  @override
  String get missingValues => '缺失值';

  @override
  String get deleteVariable => '删除变量';

  @override
  String savedTo(String path) {
    return '已保存到 $path';
  }

  @override
  String get shareFile => '分享文件';

  @override
  String get copyToClipboard => '复制到剪贴板';

  @override
  String get shareDataText => 'StatLab 数据导出';

  @override
  String get importDataTitle => '导入数据';

  @override
  String get importDemoData => '加载示例数据';

  @override
  String get saveAndBack => '保存并返回';

  @override
  String get importCsvSav => '导入 CSV / SAV / Excel';

  @override
  String get saveProject => '保存工程';

  @override
  String get closeProject => '关闭工程';

  @override
  String get projectSaved => '工程已保存';

  @override
  String autoSavedAt(String time) {
    return '已自动保存 $time';
  }

  @override
  String get tabTransform => '变换';

  @override
  String casesByVars(int cases, int vars) {
    return '$cases 个案 × $vars 变量';
  }

  @override
  String get syntaxTitle => '语法编辑器';

  @override
  String get openSps => '打开 .sps';

  @override
  String get saveSps => '保存 .sps';

  @override
  String get run => '运行';

  @override
  String get runSyntax => '运行语法';

  @override
  String get syntaxHint => '输入 SPSS 风格语法，语句以句点结尾…';

  @override
  String get outputHere => '输出将显示在这里';

  @override
  String syntaxDone(int ok, int fail) {
    return '完成: $ok 成功, $fail 失败';
  }

  @override
  String get exportHtml => '导出 HTML';

  @override
  String get varY => '变量 Y';

  @override
  String get varX => '变量 X';

  @override
  String get notImplementedTitle => '尚未实现';

  @override
  String get hintTitle => '提示';

  @override
  String get pleaseSelectTestVar => '请选择检验变量';

  @override
  String get pleaseSelectPaired => '请选择 2 个配对变量';

  @override
  String get pleaseSelectRowCol => '请选择行、列变量';

  @override
  String get pleaseSelectTwoVars => '请选择 2 个变量';

  @override
  String get atLeastTwoGroups => '至少两组';

  @override
  String get pleaseSelectItems => '请至少选择 2 个题目变量';

  @override
  String get pleaseSelectVar => '请选择变量';

  @override
  String get pleaseSelectXYShort => '请选择 X/Y';

  @override
  String get pleaseSelectStateVar => '请选择状态变量与检验变量';

  @override
  String get pleaseSelectDepVar => '请选择因变量';

  @override
  String get pleaseSelectPredictors => '请至少选择 2 个预测变量';

  @override
  String get varNotFound => '变量不存在';

  @override
  String get noValidData => '无有效数据';

  @override
  String get reportVar => '变量';

  @override
  String get mean => '均值';

  @override
  String get stdDev => '标准差';

  @override
  String get variance => '方差';

  @override
  String get minWord => '最小';

  @override
  String get maxWord => '最大';

  @override
  String get skewness => '偏度';

  @override
  String get kurtosis => '峰度';

  @override
  String get median => '中位数';

  @override
  String get se => '标准误';

  @override
  String get total => '总计';

  @override
  String get group => '组';

  @override
  String get pTwoTail => 'p(双尾)';

  @override
  String get meanDiff => '均值差';

  @override
  String get seDiff => '差值标准误';

  @override
  String get ciLower => '95%CI下';

  @override
  String get ciUpper => '95%CI上';

  @override
  String get descriptivesTitle => '描述统计';

  @override
  String get descriptivesStats => '描述统计量';

  @override
  String get descByVar => '各变量描述统计';

  @override
  String get quantilesCi => '分位数与置信区间';

  @override
  String get ciNote => '置信区间基于 t 分布，置信水平 95%。';

  @override
  String get ttestTitle => 't 检验';

  @override
  String get groupStats => '组统计量';

  @override
  String get group1 => '组1';

  @override
  String get group2 => '组2';

  @override
  String get independentTest => '独立样本检验';

  @override
  String leveneNote(String f, String p, String assumption) {
    return 'Levene 方差齐性：F=$f, p=$p；$assumption';
  }

  @override
  String get equalVarAssumed => '假定方差齐性';

  @override
  String get equalVarNotAssumed => '不假定方差齐性（Welch）';

  @override
  String oneSampleLabel(String name, String mu) {
    return '单样本 $name vs μ=$mu';
  }

  @override
  String pairedLabel(String a, String b) {
    return '配对 $a vs $b';
  }

  @override
  String get anovaTitle => '单因素方差分析';

  @override
  String get anovaTable => '方差分析表';

  @override
  String get source => '来源';

  @override
  String get ss => '平方和';

  @override
  String get ms => '均方';

  @override
  String get betweenGroups => '组间';

  @override
  String get withinGroups => '组内';

  @override
  String anovaNote(String w, String f, String p) {
    return 'ω²=$w；Levene F=$f, p=$p。';
  }

  @override
  String anovaOfLabel(String v, String g) {
    return '单因素 ANOVA：$v by $g';
  }

  @override
  String get corrTitle => '相关分析';

  @override
  String get corrCoef => '相关系数';

  @override
  String get sigTwoTail => '显著性 (双尾 p)';

  @override
  String get corrStars => '*** p<.001  ** p<.01  * p<.05';

  @override
  String get regressionTitle => '线性回归';

  @override
  String depVarColon(String y) {
    return '因变量：$y';
  }

  @override
  String get modelSummary => '模型摘要';

  @override
  String get adjR2 => '调整 R²';

  @override
  String get regressionWord => '回归';

  @override
  String get residual => '残差';

  @override
  String get coefficients => '系数';

  @override
  String get term => '项';

  @override
  String get stdBeta => '标准β';

  @override
  String get chiSquareTitle => '卡方检验';

  @override
  String get statistic => '统计量';

  @override
  String get valueWord => '值';

  @override
  String get likelihoodRatio => '似然比 G²';

  @override
  String get association => '关联度';

  @override
  String get cellsObsExp => '单元格（观察 / 期望）';

  @override
  String get observed => '观察';

  @override
  String get expected => '期望';

  @override
  String get stdResidual => '标准化残差';

  @override
  String get kmeansTitle => 'K-Means 聚类';

  @override
  String kmeansSubtitle(int k, int iters, String inertia) {
    return 'k=$k · $iters 次迭代 · inertia=$inertia';
  }

  @override
  String get finalClusterCenters => '最终聚类中心';

  @override
  String get cluster => '簇';

  @override
  String get caseCount => '个案数';

  @override
  String get reliabilityTitle => '信度分析';

  @override
  String get reliabilityStats => '可靠性统计量';

  @override
  String get stdAlpha => '标准化 α';

  @override
  String get nItemsWord => '项数';

  @override
  String get itemStats => '项统计量';

  @override
  String get itemWord => '项';

  @override
  String get itemTotalCorr => '校正项总相关';

  @override
  String get alphaIfDeleted => '删除项后 α';

  @override
  String get histogramTitle => '直方图';

  @override
  String get binFreq => '分箱频数';

  @override
  String get lower => '下限';

  @override
  String get upper => '上限';

  @override
  String get freq => '频数';

  @override
  String get scatterTitle => '散点图';

  @override
  String get corrFit => '相关与拟合';

  @override
  String get slope => '斜率';

  @override
  String get intercept => '截距';

  @override
  String get barTitle => '条形图 / 频率';

  @override
  String get freqTable => '频率表';

  @override
  String get category => '类别';

  @override
  String get percent => '百分比';

  @override
  String get validPercent => '有效百分比';

  @override
  String get cumulativePercent => '累计%';

  @override
  String freqNote(int n, int m) {
    return '有效 N=$n  缺失=$m';
  }

  @override
  String get meansTitle => '分层均值';

  @override
  String get normalityTitle => '正态性检验';

  @override
  String get resultWord => '结果';

  @override
  String get testWord => '检验';

  @override
  String get verdictWord => '判断';

  @override
  String get looksNormal => '近似正态';

  @override
  String get deviatesNormal => '偏离正态';

  @override
  String get normalityNote => 'p>0.05 且 |偏度|<1.5、|峰度|<3 时可近似认为正态。';

  @override
  String get rocTitle => 'ROC 曲线';

  @override
  String get aucSection => '曲线下面积';

  @override
  String get rocNote => 'AUC 0.5=无诊断力，0.7-0.8 中等，>0.8 较好。';

  @override
  String get tukeyTitle => '事后两两比较';

  @override
  String get pairwise => 'Pairwise';

  @override
  String get significant => '显著';

  @override
  String tukeyNote(String f, String p) {
    return '整体 F=$f, p=$p。';
  }

  @override
  String get factorPcaTitle => '主成分因子分析';

  @override
  String get eigenSection => '特征值与方差';

  @override
  String get component => '成分';

  @override
  String get eigenvalue => '特征值';

  @override
  String get varExplained => '方差贡献率';

  @override
  String get cumulative => '累计';

  @override
  String get loadingsMatrix => '载荷矩阵';

  @override
  String factorPcaNote(String v) {
    return '总方差解释率 $v。采用相关矩阵主成分法（未旋转）。';
  }

  @override
  String get logisticTitle => '逻辑回归';

  @override
  String get modelWord => '模型';

  @override
  String get orExpB => 'OR=exp(B)';

  @override
  String get pseudoR2Mcfadden => '伪R² (McFadden)';

  @override
  String get accuracy => '正确率';

  @override
  String get iterations => '迭代';

  @override
  String get logisticNote => '采用梯度下降拟合，样本量建议 ≥ 30。OR>1 表示风险增加。';

  @override
  String get examineDesc => '描述';

  @override
  String get percentileWord => '百分位';

  @override
  String trimmedNote(String a, String b) {
    return '5% 截尾均值=$a  Winsorized=$b';
  }

  @override
  String get extremes => '极值';

  @override
  String get lowest => '最小';

  @override
  String get highest => '最大';

  @override
  String get boxSection => '箱线';

  @override
  String get lowerWhisker => '下须';

  @override
  String get upperWhisker => '上须';

  @override
  String get medianShort => '中位';

  @override
  String get outliers => '离群数';

  @override
  String get stemLeaf => '茎叶图';

  @override
  String get normalityDap => '正态性 (D\'Agostino-Pearson)';

  @override
  String get zSkew => 'Z偏度';

  @override
  String get zKurt => 'Z峰度';

  @override
  String get boxplotTitle => '箱线图';

  @override
  String get distSummary => '分布摘要';

  @override
  String get qqTitle => 'Q-Q 图';

  @override
  String get qqSection => '正态分位对照';

  @override
  String qqNote(int n) {
    return '点数 $n；点越贴近 y=x 直线越接近正态。';
  }

  @override
  String get factorFullTitle => '因子分析（全）';

  @override
  String get adequacySection => '适切性与球形检验';

  @override
  String get kmoPerVar => '逐变量 KMO';

  @override
  String get eigenCommunalities => '特征值 / 共同度';

  @override
  String get communality => '共同度';

  @override
  String get varimaxLoadings => 'Varimax 旋转载荷';

  @override
  String rotationNote(String v) {
    return '旋转平方和=$v';
  }

  @override
  String get logisticFullTitle => '逻辑回归（全）';

  @override
  String get waldCoefficients => '系数（Wald）';

  @override
  String get modelClassification => '模型与分类';

  @override
  String get classificationTable => '分类表（阈值 0.5）';

  @override
  String get sensitivity => '敏感度';

  @override
  String get specificity => '特异度';

  @override
  String get precision => '精确率';

  @override
  String get nGroups => '组数';

  @override
  String get glmOneTitle => 'GLM 单元 ANOVA';

  @override
  String get glmTwoTitle => 'GLM 双元 ANOVA';

  @override
  String get betweenEffects => '主体间效应';

  @override
  String get partialEta2 => '偏η²';

  @override
  String get errorWord => '误差';

  @override
  String glmNote(String r2, String adj, String rmse, int n) {
    return 'R²=$r2  调整R²=$adj  RMSE=$rmse  N=$n';
  }

  @override
  String get stepwiseTitle => '逐步回归';

  @override
  String get enteredVars => '进入模型的变量';

  @override
  String get noneEntered => '（无变量进入）';

  @override
  String get step => '步';

  @override
  String get action => '动作';

  @override
  String get enter => '进入';

  @override
  String get remove => '移除';

  @override
  String get ctablesTitle => 'CTABLES 透视表';

  @override
  String get summaryCounts => '汇总（计数）';

  @override
  String get nonparamSubtitle => '非参数检验';

  @override
  String get testResult => '检验结果';

  @override
  String get meanRank1 => '平均秩1';

  @override
  String get meanRank2 => '平均秩2';

  @override
  String generatedAt(String time) {
    return '生成时间：$time';
  }
}
