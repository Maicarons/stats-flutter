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
  String get cellEditHint => 'Enter · Tab · Esc';

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
}
