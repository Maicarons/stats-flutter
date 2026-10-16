// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stats-flutter';

  @override
  String get tabData => 'Data';

  @override
  String get tabProjects => 'Projects';

  @override
  String get tabAnalysis => 'Analysis';

  @override
  String get tabLearn => 'Learn';

  @override
  String get tabQuiz => 'Quiz';

  @override
  String get tabSettings => 'Settings';

  @override
  String get navHome => 'Home';

  @override
  String get dataView => 'Data View';

  @override
  String get variableView => 'Variable View';

  @override
  String get searchHint => 'Search cases / variables…';

  @override
  String get cases => 'Cases';

  @override
  String get variables => 'Variables';

  @override
  String get addCase => 'Case';

  @override
  String get addVariable => 'Add Variable';

  @override
  String get variableName => 'Variable name';

  @override
  String get loadDemo => 'Load demo data';

  @override
  String get importCsv => 'Import CSV…';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get showValueLabels => 'Show value labels';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get reset => 'Reset';

  @override
  String get resetConfirm => 'Reset all settings and data to defaults?';

  @override
  String get resetDone => 'Settings and data have been reset';

  @override
  String get about => 'About';

  @override
  String get aboutTitle => 'About StatLab';

  @override
  String get aboutDesc =>
      'A mobile-first, project-based statistical analysis suite with built-in learning and testing modules.';

  @override
  String get version => 'Version';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme mode';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeColor => 'Theme color';

  @override
  String get language => 'Language';

  @override
  String get langSystem => 'System';

  @override
  String get langEnglish => 'English';

  @override
  String get langChinese => '中文';

  @override
  String get analysis => 'Analysis';

  @override
  String get runAnalysis => 'Run analysis';

  @override
  String get running => 'Running…';

  @override
  String get shareReport => 'Share report';

  @override
  String get params => 'Analysis parameters';

  @override
  String get selectVariables => 'Variables (multi-select)';

  @override
  String get analysisVariable => 'Analysis variable';

  @override
  String get groupVariable => 'Grouping variable';

  @override
  String get pairVariables => 'Paired variables (pick 2)';

  @override
  String get testValue => 'Test value μ₀';

  @override
  String get dependentVar => 'Dependent Y';

  @override
  String get independentVar => 'Independent X';

  @override
  String get rowVariable => 'Row variable';

  @override
  String get columnVariable => 'Column variable';

  @override
  String get clusterCount => 'Clusters k';

  @override
  String get error => 'Error';

  @override
  String get failed => 'Run failed';

  @override
  String get notImplemented =>
      'This analysis is under development. Try descriptives or t-tests first.';

  @override
  String get pleaseSelectVars => 'Please select at least one variable';

  @override
  String get pleaseSelectGroup =>
      'Please select analysis and grouping variables';

  @override
  String get pleaseSelectXY => 'Please select Y and X';

  @override
  String get needTwoGroups => 'Need at least two groups';

  @override
  String get needTwoVars => 'Please select at least 2 variables';

  @override
  String get learnTitle => 'Statistics Learning';

  @override
  String get learnTagline => 'From concepts to formulas';

  @override
  String get learnIntro =>
      'Master hypothesis tests, regression, nonparametrics and reliability through short lessons. Then practice in Quiz.';

  @override
  String get coreFormulas => 'Core formulas';

  @override
  String get quizTitle => 'Statistics Quiz';

  @override
  String get quizTagline => 'Random questions · instant scoring';

  @override
  String get quizIntro =>
      'Question bank covers descriptives, t-tests, ANOVA, correlation, regression, chi-square, nonparametrics and reliability.';

  @override
  String get questionCount => 'Number of questions';

  @override
  String get questionsUnit => 'questions';

  @override
  String get startQuiz => 'Start quiz';

  @override
  String get next => 'Next';

  @override
  String get prev => 'Previous';

  @override
  String get submit => 'Submit';

  @override
  String get retry => 'Try another set';

  @override
  String get backToSetup => 'Back to setup';

  @override
  String get scoreTitle => 'Your score';

  @override
  String get quizGreat =>
      'Excellent! Try more questions or practice in Analysis.';

  @override
  String get quizGood => 'Not bad — review the explanations for missed items.';

  @override
  String get quizLow => 'Visit Learn first to strengthen concepts, then retry.';

  @override
  String get answerReview => 'Answer review';

  @override
  String get correct => 'Correct';

  @override
  String get yourChoice => 'Your choice';

  @override
  String get explanation => 'Explanation';

  @override
  String questionOf(int n, int total) {
    return 'Question $n of $total';
  }

  @override
  String importSuccess(int cases, int vars) {
    return 'Imported $cases cases × $vars variables';
  }

  @override
  String importFailed(String e) {
    return 'Import failed: $e';
  }

  @override
  String exportFailed(String e) {
    return 'Export failed: $e';
  }

  @override
  String get copied => 'Copied';

  @override
  String editCase(int n) {
    return 'Edit case #$n';
  }

  @override
  String get label => 'Label';

  @override
  String get measure => 'Measure';

  @override
  String get type => 'Type';

  @override
  String get decimals => 'Decimals';

  @override
  String get valueLabels => 'Value labels';

  @override
  String get doubleClickEdit => 'Double-click a cell to edit';

  @override
  String get cellEditHint =>
      'Arrows select · Enter edits · Tab moves right · Esc cancels';

  @override
  String get row => 'Row';

  @override
  String get col => 'Col';

  @override
  String get deleteCase => 'Delete case';

  @override
  String get insertCase => 'Insert case';

  @override
  String get duplicateCase => 'Duplicate case';

  @override
  String get clearCell => 'Clear cell';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get importData => 'Import';

  @override
  String get exportData => 'Export';

  @override
  String get importSav => 'Import SPSS .sav…';

  @override
  String get importExcel => 'Import Excel…';

  @override
  String get transformMenu => 'Transforms…';

  @override
  String get syntaxEditor => 'Syntax editor…';

  @override
  String get weightCases => 'Weight cases…';

  @override
  String get splitFile => 'Split file…';

  @override
  String get findCase => 'Find cases…';

  @override
  String get notWeighted => 'Not weighted';

  @override
  String weightedBy(String v) {
    return 'Weighted by: $v';
  }

  @override
  String get weightOff => 'Weighting off';

  @override
  String get noSplit => 'No split';

  @override
  String splitBy(String v) {
    return 'Split by: $v';
  }

  @override
  String get splitOff => 'Split off';

  @override
  String get find => 'Find';

  @override
  String get findHint => 'Enter text to find…';

  @override
  String notFound(String q) {
    return '「$q」not found';
  }

  @override
  String foundN(int n, String list, String more) {
    return 'Found $n: $list$more';
  }

  @override
  String get noValueLabels => 'No value labels defined';

  @override
  String get editValueLabels => 'Edit value labels';

  @override
  String get missingValues => 'Missing values';

  @override
  String get deleteVariable => 'Delete variable';

  @override
  String savedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get shareFile => 'Share file';

  @override
  String get copyToClipboard => 'Copy to clipboard';

  @override
  String get shareDataText => 'StatLab data export';

  @override
  String get importDataTitle => 'Import data';

  @override
  String get importDemoData => 'Load demo data';

  @override
  String get saveAndBack => 'Save and back';

  @override
  String get importCsvSav => 'Import CSV / SAV / Excel';

  @override
  String get saveProject => 'Save project';

  @override
  String get closeProject => 'Close project';

  @override
  String get projectSaved => 'Project saved';

  @override
  String autoSavedAt(String time) {
    return 'Auto-saved $time';
  }

  @override
  String get tabTransform => 'Transform';

  @override
  String casesByVars(int cases, int vars) {
    return '$cases cases × $vars variables';
  }

  @override
  String get syntaxTitle => 'Syntax editor';

  @override
  String get openSps => 'Open .sps';

  @override
  String get saveSps => 'Save .sps';

  @override
  String get run => 'Run';

  @override
  String get runSyntax => 'Run syntax';

  @override
  String get syntaxHint =>
      'Enter SPSS-style syntax; statements end with a period…';

  @override
  String get outputHere => 'Output will appear here';

  @override
  String syntaxDone(int ok, int fail) {
    return 'Done: $ok ok, $fail failed';
  }

  @override
  String get exportHtml => 'Export HTML';

  @override
  String get varY => 'Variable Y';

  @override
  String get varX => 'Variable X';

  @override
  String get notImplementedTitle => 'Not implemented yet';

  @override
  String get hintTitle => 'Hint';

  @override
  String get pleaseSelectTestVar => 'Please select a test variable';

  @override
  String get pleaseSelectPaired => 'Please select 2 paired variables';

  @override
  String get pleaseSelectRowCol => 'Please select row and column variables';

  @override
  String get pleaseSelectTwoVars => 'Please select 2 variables';

  @override
  String get atLeastTwoGroups => 'Need at least 2 groups';

  @override
  String get pleaseSelectItems => 'Please select at least 2 item variables';

  @override
  String get pleaseSelectVar => 'Please select a variable';

  @override
  String get pleaseSelectXYShort => 'Please select X/Y';

  @override
  String get pleaseSelectStateVar => 'Please select state and test variables';

  @override
  String get pleaseSelectDepVar => 'Please select dependent variable';

  @override
  String get pleaseSelectPredictors => 'Please select at least 2 predictors';

  @override
  String get varNotFound => 'Variable not found';

  @override
  String get noValidData => 'No valid data';

  @override
  String get reportVar => 'Variable';

  @override
  String get mean => 'Mean';

  @override
  String get stdDev => 'Std. deviation';

  @override
  String get variance => 'Variance';

  @override
  String get minWord => 'Min';

  @override
  String get maxWord => 'Max';

  @override
  String get skewness => 'Skewness';

  @override
  String get kurtosis => 'Kurtosis';

  @override
  String get median => 'Median';

  @override
  String get se => 'Std. error';

  @override
  String get total => 'Total';

  @override
  String get group => 'Group';

  @override
  String get pTwoTail => 'p (2-tailed)';

  @override
  String get meanDiff => 'Mean difference';

  @override
  String get seDiff => 'Std. error of difference';

  @override
  String get ciLower => '95% CI lower';

  @override
  String get ciUpper => '95% CI upper';

  @override
  String get descriptivesTitle => 'Descriptives';

  @override
  String get descriptivesStats => 'Descriptive statistics';

  @override
  String get descByVar => 'Descriptives by variable';

  @override
  String get quantilesCi => 'Quantiles & confidence intervals';

  @override
  String get ciNote =>
      'Confidence intervals are based on the t distribution at the 95% level.';

  @override
  String get ttestTitle => 't-test';

  @override
  String get groupStats => 'Group statistics';

  @override
  String get group1 => 'Group 1';

  @override
  String get group2 => 'Group 2';

  @override
  String get independentTest => 'Independent samples test';

  @override
  String leveneNote(String f, String p, String assumption) {
    return 'Levene\'s test: F=$f, p=$p; $assumption';
  }

  @override
  String get equalVarAssumed => 'equal variances assumed';

  @override
  String get equalVarNotAssumed => 'equal variances not assumed (Welch)';

  @override
  String oneSampleLabel(String name, String mu) {
    return 'One-sample $name vs μ=$mu';
  }

  @override
  String pairedLabel(String a, String b) {
    return 'Paired $a vs $b';
  }

  @override
  String get anovaTitle => 'One-way ANOVA';

  @override
  String get anovaTable => 'ANOVA table';

  @override
  String get source => 'Source';

  @override
  String get ss => 'Sum of squares';

  @override
  String get ms => 'Mean square';

  @override
  String get betweenGroups => 'Between groups';

  @override
  String get withinGroups => 'Within groups';

  @override
  String anovaNote(String w, String f, String p) {
    return 'ω²=$w; Levene F=$f, p=$p.';
  }

  @override
  String anovaOfLabel(String v, String g) {
    return 'One-way ANOVA: $v by $g';
  }

  @override
  String get corrTitle => 'Correlation analysis';

  @override
  String get corrCoef => 'Correlation coefficients';

  @override
  String get sigTwoTail => 'Significance (two-tailed p)';

  @override
  String get corrStars => '*** p<.001  ** p<.01  * p<.05';

  @override
  String get regressionTitle => 'Linear regression';

  @override
  String depVarColon(String y) {
    return 'Dependent: $y';
  }

  @override
  String get modelSummary => 'Model summary';

  @override
  String get adjR2 => 'Adjusted R²';

  @override
  String get regressionWord => 'Regression';

  @override
  String get residual => 'Residual';

  @override
  String get coefficients => 'Coefficients';

  @override
  String get term => 'Term';

  @override
  String get stdBeta => 'Std. β';

  @override
  String get chiSquareTitle => 'Chi-square test';

  @override
  String get statistic => 'Statistic';

  @override
  String get valueWord => 'Value';

  @override
  String get likelihoodRatio => 'Likelihood ratio G²';

  @override
  String get association => 'Association';

  @override
  String get cellsObsExp => 'Cells (observed / expected)';

  @override
  String get observed => 'Observed';

  @override
  String get expected => 'Expected';

  @override
  String get stdResidual => 'Std. residual';

  @override
  String get kmeansTitle => 'K-Means clustering';

  @override
  String kmeansSubtitle(int k, int iters, String inertia) {
    return 'k=$k · $iters iterations · inertia=$inertia';
  }

  @override
  String get finalClusterCenters => 'Final cluster centers';

  @override
  String get cluster => 'Cluster';

  @override
  String get caseCount => 'Cases';

  @override
  String get reliabilityTitle => 'Reliability analysis';

  @override
  String get reliabilityStats => 'Reliability statistics';

  @override
  String get stdAlpha => 'Standardized α';

  @override
  String get nItemsWord => 'Items';

  @override
  String get itemStats => 'Item statistics';

  @override
  String get itemWord => 'Item';

  @override
  String get itemTotalCorr => 'Corrected item-total correlation';

  @override
  String get alphaIfDeleted => 'α if item deleted';

  @override
  String get histogramTitle => 'Histogram';

  @override
  String get binFreq => 'Bin frequencies';

  @override
  String get lower => 'Lower';

  @override
  String get upper => 'Upper';

  @override
  String get freq => 'Frequency';

  @override
  String get scatterTitle => 'Scatter plot';

  @override
  String get corrFit => 'Correlation & fit';

  @override
  String get slope => 'Slope';

  @override
  String get intercept => 'Intercept';

  @override
  String get barTitle => 'Bar chart / frequencies';

  @override
  String get freqTable => 'Frequency table';

  @override
  String get category => 'Category';

  @override
  String get percent => 'Percent';

  @override
  String get validPercent => 'Valid percent';

  @override
  String get cumulativePercent => 'Cumulative %';

  @override
  String freqNote(int n, int m) {
    return 'Valid N=$n  Missing=$m';
  }

  @override
  String get meansTitle => 'Layered means';

  @override
  String get normalityTitle => 'Normality test';

  @override
  String get resultWord => 'Result';

  @override
  String get testWord => 'Test';

  @override
  String get verdictWord => 'Verdict';

  @override
  String get looksNormal => 'Approximately normal';

  @override
  String get deviatesNormal => 'Deviates from normal';

  @override
  String get normalityNote =>
      'Approximately normal when p>0.05, |skewness|<1.5 and |kurtosis|<3.';

  @override
  String get rocTitle => 'ROC curve';

  @override
  String get aucSection => 'Area under the curve';

  @override
  String get rocNote => 'AUC 0.5 = no discrimination, 0.7–0.8 fair, >0.8 good.';

  @override
  String get tukeyTitle => 'Post hoc pairwise comparisons';

  @override
  String get pairwise => 'Pairwise';

  @override
  String get significant => 'Significant';

  @override
  String tukeyNote(String f, String p) {
    return 'Overall F=$f, p=$p.';
  }

  @override
  String get factorPcaTitle => 'PCA factor analysis';

  @override
  String get eigenSection => 'Eigenvalues & variance';

  @override
  String get component => 'Component';

  @override
  String get eigenvalue => 'Eigenvalue';

  @override
  String get varExplained => '% of variance';

  @override
  String get cumulative => 'Cumulative';

  @override
  String get loadingsMatrix => 'Loading matrix';

  @override
  String factorPcaNote(String v) {
    return 'Total variance explained: $v. PCA on the correlation matrix (unrotated).';
  }

  @override
  String get logisticTitle => 'Logistic regression';

  @override
  String get modelWord => 'Model';

  @override
  String get orExpB => 'OR=exp(B)';

  @override
  String get pseudoR2Mcfadden => 'Pseudo R² (McFadden)';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get iterations => 'Iterations';

  @override
  String get logisticNote =>
      'Fitted by gradient descent; n ≥ 30 recommended. OR>1 means increased risk.';

  @override
  String get examineDesc => 'Descriptives';

  @override
  String get percentileWord => 'Percentiles';

  @override
  String trimmedNote(String a, String b) {
    return '5% trimmed mean=$a  Winsorized=$b';
  }

  @override
  String get extremes => 'Extremes';

  @override
  String get lowest => 'Lowest';

  @override
  String get highest => 'Highest';

  @override
  String get boxSection => 'Boxplot';

  @override
  String get lowerWhisker => 'Lower whisker';

  @override
  String get upperWhisker => 'Upper whisker';

  @override
  String get medianShort => 'Median';

  @override
  String get outliers => 'Outliers';

  @override
  String get stemLeaf => 'Stem-and-leaf';

  @override
  String get normalityDap => 'Normality (D\'Agostino-Pearson)';

  @override
  String get zSkew => 'Z skewness';

  @override
  String get zKurt => 'Z kurtosis';

  @override
  String get boxplotTitle => 'Boxplot';

  @override
  String get distSummary => 'Distribution summary';

  @override
  String get qqTitle => 'Q-Q plot';

  @override
  String get qqSection => 'Normal quantile comparison';

  @override
  String qqNote(int n) {
    return '$n points; the closer to the y=x line, the more normal.';
  }

  @override
  String get factorFullTitle => 'Factor analysis (full)';

  @override
  String get adequacySection => 'Adequacy & sphericity';

  @override
  String get kmoPerVar => 'Per-variable KMO';

  @override
  String get eigenCommunalities => 'Eigenvalues / communalities';

  @override
  String get communality => 'Communality';

  @override
  String get varimaxLoadings => 'Varimax rotated loadings';

  @override
  String rotationNote(String v) {
    return 'Rotation SS=$v';
  }

  @override
  String get logisticFullTitle => 'Logistic regression (full)';

  @override
  String get waldCoefficients => 'Coefficients (Wald)';

  @override
  String get modelClassification => 'Model & classification';

  @override
  String get classificationTable => 'Classification table (threshold 0.5)';

  @override
  String get sensitivity => 'Sensitivity';

  @override
  String get specificity => 'Specificity';

  @override
  String get precision => 'Precision';

  @override
  String get nGroups => 'Groups';

  @override
  String get glmOneTitle => 'GLM one-way ANOVA';

  @override
  String get glmTwoTitle => 'GLM two-way ANOVA';

  @override
  String get betweenEffects => 'Between-subjects effects';

  @override
  String get partialEta2 => 'Partial η²';

  @override
  String get errorWord => 'Error';

  @override
  String glmNote(String r2, String adj, String rmse, int n) {
    return 'R²=$r2  Adjusted R²=$adj  RMSE=$rmse  N=$n';
  }

  @override
  String get pKolmogorov => 'p (Kolmogorov)';

  @override
  String get jtTitle => 'Jonckheere-Terpstra trend test';

  @override
  String get jtNote =>
      'Groups are ordered by the ordering variable\'s level order (value labels first, then ascending values). The alternative is a monotone rise of the response along that order.';

  @override
  String get pOneTail => 'p (1-tailed)';

  @override
  String get pGreater => 'p (≥ observed)';

  @override
  String get pLess => 'p (≤ observed)';

  @override
  String get pleaseSelectCovariates => 'Please select at least one covariate';

  @override
  String get observedValue => 'Observed';

  @override
  String get permTitle => 'Permutation test';

  @override
  String get permDesign => 'Design';

  @override
  String get permIndependent => 'Independent samples';

  @override
  String get permPaired => 'Paired samples';

  @override
  String permRunInfo(int b, String seed, String mode) {
    return 'Permutations: $b · seed $seed · $mode';
  }

  @override
  String get permExact => 'exact enumeration';

  @override
  String get permRandom => 'random sampling';

  @override
  String get permDistribution => 'Permutation distribution';

  @override
  String get permStatMean => 'Mean of permuted';

  @override
  String get permStatSd => 'SD of permuted';

  @override
  String get permStatRange => 'Min / max of permuted';

  @override
  String get multinomialTitle => 'Multinomial logistic regression';

  @override
  String get referenceCategory => 'Reference category';

  @override
  String get multinomialFit => 'Model fit & classification';

  @override
  String get confusionMatrix => 'Confusion matrix';

  @override
  String get lrChiSquare => 'LR χ²';

  @override
  String get actualClass => 'Actual';

  @override
  String get predictedClass => 'Predicted';

  @override
  String multinomialNote(String ref, String r2, int n) {
    return 'Reference category: $ref · McFadden R²=$r2 · N=$n';
  }

  @override
  String get ancovaTitle => 'ANCOVA (analysis of covariance)';

  @override
  String get factorWord => 'Factor';

  @override
  String get typeIiiSs => 'Type III sums of squares';

  @override
  String get covariates => 'Covariates';

  @override
  String get covariateSlopes => 'Covariate slopes';

  @override
  String get adjustedMeans => 'Adjusted means (EMM)';

  @override
  String get rawMean => 'Raw mean';

  @override
  String get adjustedMean => 'Adjusted mean';

  @override
  String ancovaNote(String r2, String adj, int n) {
    return 'Adjusted means are evaluated at the covariates\' means; the slope is on the original scale (change in Y per one unit of X). R²=$r2 · Adjusted R²=$adj · N=$n';
  }

  @override
  String get stepwiseTitle => 'Stepwise regression';

  @override
  String get enteredVars => 'Variables entered';

  @override
  String get noneEntered => '(no variables entered)';

  @override
  String get step => 'Step';

  @override
  String get action => 'Action';

  @override
  String get enter => 'Enter';

  @override
  String get remove => 'Remove';

  @override
  String get ctablesTitle => 'CTABLES pivot table';

  @override
  String get summaryCounts => 'Summary (counts)';

  @override
  String get nonparamSubtitle => 'Nonparametric test';

  @override
  String get testResult => 'Test result';

  @override
  String get meanRank1 => 'Mean rank 1';

  @override
  String get meanRank2 => 'Mean rank 2';

  @override
  String generatedAt(String time) {
    return 'Generated: $time';
  }

  @override
  String get splashTagline => 'Statistical analysis workbench';

  @override
  String get splashSkip => 'Tap to skip';

  @override
  String get projHeroTitle => 'Projects';

  @override
  String get projHeroDesc =>
      'Each project is a standalone dataset. Create, open, duplicate or delete a project, then edit data and run analyses inside.';

  @override
  String get projNewDemo => 'Demo project';

  @override
  String get projNewBlank => 'New blank';

  @override
  String get projSearchHint => 'Search projects…';

  @override
  String projCount(int n) {
    return '$n projects';
  }

  @override
  String get projEmptyTitle => 'No projects yet';

  @override
  String get projEmptyMsg =>
      'Tap “Demo project” or “New blank” to get started.';

  @override
  String get projNoMatchTitle => 'No matching projects';

  @override
  String get projNoMatchMsg => 'Try another keyword.';

  @override
  String get projNewProject => 'New project';

  @override
  String get projNewDemoTitle => 'New demo project';

  @override
  String get projNewBlankTitle => 'New blank project';

  @override
  String get projNameField => 'Project name';

  @override
  String get projDescField => 'Description (optional)';

  @override
  String get projCreate => 'Create';

  @override
  String get projRenameTitle => 'Rename project';

  @override
  String get projNameLabel => 'Name';

  @override
  String get projDeleteTitle => 'Delete project';

  @override
  String projDeleteMsg(String name) {
    return 'Delete “$name”? This cannot be undone.';
  }

  @override
  String get projDeleteAction => 'Delete';

  @override
  String get projDuplicated => 'Project duplicated';

  @override
  String get projOpenFailed => 'Failed to open project';

  @override
  String get projOpen => 'Open';

  @override
  String get projDuplicate => 'Duplicate';

  @override
  String get projRecent => 'Recent';

  @override
  String get projAll => 'All projects';

  @override
  String projUpdatedAt(String time) {
    return 'Updated $time';
  }

  @override
  String get projUntitled => 'Untitled';

  @override
  String projCopySuffix(String name) {
    return '$name copy';
  }

  @override
  String casesByVarsShort(int cases, int vars) {
    return '$cases cases · $vars vars';
  }

  @override
  String get projDemoName => 'Demo · scores';

  @override
  String projDefaultName(int n) {
    return 'Project $n';
  }

  @override
  String get anSearchHint => 'Search analyses…';

  @override
  String get anRecent => 'Recently used';

  @override
  String get anFavorites => 'Favorites';

  @override
  String get anResults => 'Results';

  @override
  String get anNoMatch => 'No matching analysis';

  @override
  String get anAdvanced => 'Advanced';

  @override
  String get anCatDescribe => 'Descriptives & exploration';

  @override
  String get anCatCompare => 'Compare means';

  @override
  String get anCatCorrelate => 'Correlation & association';

  @override
  String get anCatModel => 'Regression & clustering';

  @override
  String get anCatNonparam => 'Nonparametric & reliability';

  @override
  String get anCatExtra => 'Additional procedures';

  @override
  String get anCatDimreduce => 'Dimension reduction & classification';

  @override
  String get anCatCharts => 'Charts';

  @override
  String get anDescriptives => 'Descriptives';

  @override
  String get anDescriptivesDesc =>
      'Mean, SD, skewness, kurtosis, confidence intervals';

  @override
  String get anFrequencies => 'Frequencies';

  @override
  String get anFrequenciesDesc => 'Frequency tables, percentages, cumulative';

  @override
  String get anExplore => 'Explore';

  @override
  String get anExploreDesc => 'Percentiles, extremes, normality';

  @override
  String get anTtestOne => 'One-sample t test';

  @override
  String get anTtestOneDesc => 'Mean vs test value';

  @override
  String get anTtestInd => 'Independent-samples t test';

  @override
  String get anTtestIndDesc => 'Two group means + Levene';

  @override
  String get anTtestPaired => 'Paired-samples t test';

  @override
  String get anTtestPairedDesc => 'Pre/post or matched design';

  @override
  String get anAnova => 'One-way ANOVA';

  @override
  String get anAnovaDesc => 'Multiple group means + effect size';

  @override
  String get anCorrelation => 'Correlation';

  @override
  String get anCorrelationDesc => 'Pearson / Spearman matrix';

  @override
  String get anCrosstabs => 'Crosstabs & chi-square';

  @override
  String get anCrosstabsDesc => 'Contingency table, χ², Cramér V';

  @override
  String get anRegression => 'Linear regression';

  @override
  String get anRegressionDesc => 'Simple / multiple, coefficient table';

  @override
  String get anKmeans => 'K-Means clustering';

  @override
  String get anKmeansDesc => 'Fast clustering, cluster centers';

  @override
  String get anMannwhitney => 'Mann-Whitney U';

  @override
  String get anMannwhitneyDesc => 'Two independent samples, rank sum';

  @override
  String get anWilcoxon => 'Wilcoxon signed-rank';

  @override
  String get anWilcoxonDesc => 'Two related samples';

  @override
  String get anKruskal => 'Kruskal-Wallis H';

  @override
  String get anKruskalDesc => 'k independent samples';

  @override
  String get anReliability => 'Cronbach α reliability';

  @override
  String get anReliabilityDesc => 'Internal consistency of a scale';

  @override
  String get anMeans => 'Layered means (MEANS)';

  @override
  String get anMeansDesc => 'Grouped mean table';

  @override
  String get anNormality => 'Normality tests';

  @override
  String get anNormalityDesc => 'KS / skewness & kurtosis';

  @override
  String get anExamineFull => 'EXAMINE suite';

  @override
  String get anExamineFullDesc =>
      'Percentiles / extremes / stem-and-leaf / boxplot / Q-Q';

  @override
  String get anBoxplot => 'Boxplot';

  @override
  String get anBoxplotDesc => 'Compare distributions across groups';

  @override
  String get anQqplot => 'Q-Q plot';

  @override
  String get anQqplotDesc => 'Normal quantile plot';

  @override
  String get anRoc => 'ROC curve';

  @override
  String get anRocDesc => 'AUC and diagnostics';

  @override
  String get anTukey => 'Tukey post hoc';

  @override
  String get anTukeyDesc => 'Pairwise differences after ANOVA';

  @override
  String get anFactorPca => 'PCA factor analysis';

  @override
  String get anFactorPcaDesc => 'Loading matrix';

  @override
  String get anFactorFull => 'Factor analysis (full)';

  @override
  String get anFactorFullDesc => 'varimax / KMO / Bartlett';

  @override
  String get anLogistic => 'Logistic regression';

  @override
  String get anLogisticDesc => 'Binary outcome prediction';

  @override
  String get anLogisticFull => 'Logistic regression (full)';

  @override
  String get anLogisticFullDesc => 'Wald / OR CI / classification / H-L';

  @override
  String get anGlmTwo => 'GLM two-way ANOVA';

  @override
  String get anGlmTwoDesc => 'A×B fixed effects';

  @override
  String get anStepwise => 'Stepwise regression';

  @override
  String get anStepwiseDesc => 'Forward / backward selection';

  @override
  String get anCtables => 'CTABLES pivot table';

  @override
  String get anCtablesDesc => 'Row/column summaries';

  @override
  String get anJtTrend => 'Jonckheere-Terpstra trend';

  @override
  String get anJtTrendDesc => 'Ordered-alternative trend across groups';

  @override
  String get anAncova => 'ANCOVA (covariance)';

  @override
  String get anAncovaDesc => 'Group means adjusted for covariates';

  @override
  String get anMultinomial => 'Multinomial logistic';

  @override
  String get anMultinomialDesc => 'Nominal outcome with 3+ categories';

  @override
  String get anPermutation => 'Permutation test';

  @override
  String get anPermutationDesc =>
      'Exact / random p without distributional assumptions';

  @override
  String get anHistogram => 'Histogram';

  @override
  String get anHistogramDesc => 'Distribution shape';

  @override
  String get anScatter => 'Scatter plot';

  @override
  String get anScatterDesc => 'Relationship between two variables';

  @override
  String get anBar => 'Bar chart';

  @override
  String get anBarDesc => 'Category frequencies';

  @override
  String get unsaved => 'Unsaved';

  @override
  String get chartSection => 'Chart';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get trTitle => 'Transform';

  @override
  String get trType => 'Transform type';

  @override
  String get trOpCompute => 'COMPUTE';

  @override
  String get trOpRecode => 'RECODE';

  @override
  String get trOpAutorecode => 'AUTORECODE';

  @override
  String get trAutorecodeVars => 'Variables to recode';

  @override
  String get trAutorecodeTargets => 'Target names';

  @override
  String get trAutorecodeTargetHint => 'comma separated; default <source>_n';

  @override
  String get trAutorecodeDescending => 'Descending (largest value gets code 1)';

  @override
  String get trAutorecodeCountMismatch =>
      'Number of target names must match the selected variables';

  @override
  String get trAutorecodeHelp =>
      'Codes values 1,2,3… in ascending order (text: alphabetical) and writes each old value as a value label on the new variable; user-missing values get the highest codes and are marked missing.';

  @override
  String get trOpCount => 'COUNT';

  @override
  String get trOpRank => 'RANK';

  @override
  String get trOpSort => 'SORT';

  @override
  String get trOpSelect => 'SELECT IF';

  @override
  String get trOpAggregate => 'AGGREGATE';

  @override
  String get trOpFlip => 'FLIP';

  @override
  String get trRun => 'Run transform';

  @override
  String get trTargetVar => 'Target variable';

  @override
  String get trTargetName => 'Target variable name';

  @override
  String get trTargetHint => 'e.g. total_score';

  @override
  String get trNewVar => '(new)';

  @override
  String get trExpr => 'Expression';

  @override
  String get trExprHint => 'e.g. pre + post, or sqrt(hours) * 2';

  @override
  String get trComputeHelp =>
      'Supports + - * / ( ) and abs sqrt ln exp log10 sin cos tan round trunc';

  @override
  String get trSourceVar => 'Source variable';

  @override
  String get trRecodeTargetHint => 'e.g. method_label';

  @override
  String get trRules => 'Rules (old=new, comma separated)';

  @override
  String get trRulesHint => '1=lecture, 2=inquiry, 3=blended';

  @override
  String get trCountTargetHint => 'e.g. n_pass';

  @override
  String get trCountVars => 'Variables to count';

  @override
  String get trMatchValue => 'Match value';

  @override
  String get trRankDescending => 'Rank descending';

  @override
  String get trRankFunction => 'Output function';

  @override
  String get trRankFRank => 'RANK rank';

  @override
  String get trRankFN => 'N count';

  @override
  String get trRankFRFraction => 'RFRACTION rank/N';

  @override
  String get trRankFProportion => 'PROPORTION fraction';

  @override
  String get trRankFPercent => 'PERCENT percentile';

  @override
  String get trRankFNormal => 'NORMAL normal score';

  @override
  String get trRankFNtiles => 'NTILES groups';

  @override
  String get trRankNtiles => 'Number of groups';

  @override
  String get trRankTies => 'Ties';

  @override
  String get trRankTiesMean => 'MEAN average';

  @override
  String get trRankTiesLow => 'LOW minimum';

  @override
  String get trRankTiesHigh => 'HIGH maximum';

  @override
  String get trRankTiesCondense => 'CONDENSE condense';

  @override
  String get trRankHelp =>
      'Percentile = rank/N x 100; normal scores use the Blom plotting position (rank-3/8)/(N+1/4) fed to the inverse normal CDF; ntiles = floor(rank x k/(N+1))+1 (same as PSPP).';

  @override
  String get trSortDescending => 'Descending';

  @override
  String get trSortKeys => 'Sort keys (in order)';

  @override
  String get trCondition => 'Condition expression';

  @override
  String get trConditionHint => 'e.g. post >= 70 && method == 2';

  @override
  String get trConditionHelp => 'Supports > < >= <= == != with && ||';

  @override
  String get trGroupVar => 'Group variable';

  @override
  String get trAggVars => 'Numeric variables to aggregate (mean)';

  @override
  String get trFlipNote =>
      'Swap rows and columns (transpose) to create a new dataset.';

  @override
  String get trCurrentData => 'Current data';

  @override
  String get trDataset => 'Dataset';

  @override
  String get trResult => 'Result';

  @override
  String get trNeedTargetExpr => 'Enter a target variable and an expression';

  @override
  String get trNeedSource => 'Select a source variable';

  @override
  String get trNeedVars => 'Select at least one variable';

  @override
  String get trNeedSortKeys => 'Select sort keys';

  @override
  String get trNeedCondition => 'Enter a condition';

  @override
  String get trNeedGroupAndVars =>
      'Select a group variable and variables to aggregate';

  @override
  String get trUnknownOp => 'Unknown operation';

  @override
  String trError(String msg) {
    return 'Error: $msg';
  }

  @override
  String get copy => 'Copy';

  @override
  String get stCurrentDataset => 'Current dataset';

  @override
  String get stStorage => 'Storage location';

  @override
  String get abInfoTab => 'Info';

  @override
  String get abReadmeZh => '中文 README';

  @override
  String get abReadmeEn => 'English README';

  @override
  String abReadmeFailed(String msg) {
    return 'Failed to load README: $msg';
  }

  @override
  String get abIntroTitle => 'Introduction';

  @override
  String get abIntroBody =>
      'A project-based statistical analysis suite covering data editing, statistical procedures, data transformation, learning and testing. The statistics kernel is the standalone pure-Dart package statkit.';

  @override
  String get abDocs => 'Documentation';

  @override
  String get abLicense => 'License';

  @override
  String get abLicenseValue => 'AGPL-3.0 · open source';

  @override
  String get abStack => 'Tech stack';

  @override
  String get abStackValue => 'Flutter · Dart';

  @override
  String get abRuntime => 'Runtime';

  @override
  String get abPlatform =>
      'Flutter app · Windows / macOS / Linux / Android / iOS';

  @override
  String get abKernel =>
      'Statistics kernel: packages/statkit (pure Dart, 13 test groups)';

  @override
  String get abUiLang => 'UI language: 中文 / English (switch in Settings)';

  @override
  String get abTheme => 'Theme: light / dark / system · 8 seed colors';

  @override
  String get more => 'More';

  @override
  String get delete => 'Delete';

  @override
  String get noVariablesMatch => 'No matching variables';

  @override
  String get learnIntroBody =>
      'Master descriptive statistics, hypothesis testing, regression, non-parametric methods and reliability through short lessons. Each lesson has key points and core formulas; finish it and head to the Quiz to practise.';

  @override
  String get keyFormulas => 'Core formulas';

  @override
  String get quizSetupTitle => 'Random questions · instant scoring';

  @override
  String quizSetupBody(int n) {
    return 'The bank holds $n questions covering descriptive statistics, t-tests, ANOVA, correlation, regression, chi-square, non-parametric tests and reliability. Submit to see explanations and your mistakes.';
  }

  @override
  String get quizCount => 'Number of questions';

  @override
  String quizNQuestions(int n) {
    return '$n questions';
  }

  @override
  String get quizStart => 'Start quiz';

  @override
  String quizProgress(int a, int b) {
    return 'Question $a of $b';
  }

  @override
  String get quizScoreLabel => 'Your score';

  @override
  String get quizFeedbackHigh =>
      'Excellent! Try a bigger set, or practise the same methods in Data analysis.';

  @override
  String get quizFeedbackMid =>
      'Not bad — review the explanations for the questions you missed.';

  @override
  String get quizFeedbackLow =>
      'Go through the Learn module to consolidate the concepts, then try again.';

  @override
  String get quizTryAgain => 'New set';

  @override
  String get quizBackToSetup => 'Back to setup';

  @override
  String get quizReview => 'Review';

  @override
  String quizUnanswered(int n) {
    return 'You have $n unanswered question(s). Submit anyway?';
  }

  @override
  String quizItemTopic(int i, String topic) {
    return 'Q$i · $topic';
  }

  @override
  String get quizCorrect => 'correct';

  @override
  String get quizYourChoice => 'your choice';

  @override
  String quizExplanation(String text) {
    return 'Explanation: $text';
  }

  @override
  String get addFavorite => 'Add to favourites';

  @override
  String get removeFavorite => 'Remove from favourites';

  @override
  String get clearSelection => 'Clear';

  @override
  String get searchVariables => 'Search variables…';

  @override
  String significanceLabel(String stars) {
    return 'Significance $stars';
  }

  @override
  String get clear => 'Clear';

  @override
  String get update => 'Update';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get value => 'Value';

  @override
  String mvTitle(String name) {
    return 'Missing values · $name';
  }

  @override
  String get mvDiscrete => 'Discrete missing values (comma separated)';

  @override
  String get mvDiscreteHint => 'e.g. -99, -98';

  @override
  String get mvRangeLow => 'Range lower bound (optional)';

  @override
  String get mvRangeHigh => 'Range upper bound (optional)';

  @override
  String get mvNote =>
      'Blank cells always count as missing. A range and discrete values can be used together.';

  @override
  String vlTitle(String name) {
    return 'Value labels · $name';
  }

  @override
  String vlCount(int n) {
    return '$n label(s)';
  }

  @override
  String get vlClearAll => 'Clear all';

  @override
  String get vlEmptyHint => 'No value labels yet — add one above.';

  @override
  String savImported(int cases, int vars, String product) {
    return 'Imported $cases cases × $vars variables ($product)';
  }

  @override
  String savImportFailed(String msg) {
    return 'Failed to import .sav: $msg';
  }

  @override
  String get chartSemanticsHint =>
      'Chart illustration only — the exact values are listed in the result table.';

  @override
  String get copySection => 'Copy section';

  @override
  String get anErrorbar => 'Error bar chart';

  @override
  String get anErrorbarDesc => 'Mean with 95% CI';

  @override
  String get errorBarTitle => 'Error bar chart';

  @override
  String get errorBarNote =>
      'Error bars are mean ± 1.96 × SE, i.e. the 95% confidence interval.';

  @override
  String get theoreticalQuantile => 'Theoretical quantile z';

  @override
  String get sampleQuantile => 'Sample quantile z';

  @override
  String get qqRefLine => 'Reference line y = x';

  @override
  String get screePlot => 'Scree plot';

  @override
  String screeNote(int k) {
    return 'The scree plot draws only the $k extracted components (the extraction limit set by the analysis).';
  }

  @override
  String get cumulativeVariance => 'Cumulative variance';

  @override
  String elbowAt(String name) {
    return 'Elbow at $name';
  }

  @override
  String get legendBox => 'Interquartile box Q1–Q3';

  @override
  String get legendMedian => 'Median';

  @override
  String get legendWhisker => 'Whiskers 1.5×IQR';

  @override
  String get legendMean => 'Mean';

  @override
  String get legendOutlier => 'Outliers';

  @override
  String get legendClusterCenter => 'Cluster center';

  @override
  String legendTopDeviation(int n) {
    return 'Top $n deviations';
  }

  @override
  String get legendCi => '95% confidence interval';

  @override
  String moreGroupsHidden(int n) {
    return '$n more groups hidden (at most 6 side by side)';
  }

  @override
  String get boxPlotNote =>
      'Box = interquartile range (Q1–Q3) with the median line; whiskers reach the most extreme values within 1.5×IQR; diamond = mean; dots = outliers.';

  @override
  String get whisker => 'Whisker';

  @override
  String get ci95 => '95% CI';

  @override
  String get chartNoData => 'Not enough data to draw the chart';

  @override
  String get elbow => 'Elbow';

  @override
  String get exportSection => 'Export section';

  @override
  String get exportSectionMarkdown => 'Export Markdown';

  @override
  String get exportSectionHtml => 'Export HTML';

  @override
  String sectionExported(String name) {
    return 'Exported “$name”';
  }

  @override
  String get groupVariableOptional => 'Grouping variable (optional)';

  @override
  String get factorB => 'Factor B (optional)';

  @override
  String get stateVar => 'State variable (median split)';

  @override
  String get testVar => 'Test variable';

  @override
  String get predictors => 'Predictors (multi-select)';

  @override
  String get frozenColumnHint => 'First column is frozen';
}
