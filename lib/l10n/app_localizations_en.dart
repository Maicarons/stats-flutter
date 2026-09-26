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
      'A mobile-first statistical analysis suite inspired by GNU PSPP, with learning and testing modules.';

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
      'Master hypothesis tests, regression, nonparametrics and reliability through short lessons aligned with PSPP procedures. Then practice in Quiz.';

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
}
