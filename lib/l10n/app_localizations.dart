import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Stats-flutter'**
  String get appTitle;

  /// No description provided for @tabData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get tabData;

  /// No description provided for @tabProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get tabProjects;

  /// No description provided for @tabAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get tabAnalysis;

  /// No description provided for @tabLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get tabLearn;

  /// No description provided for @tabQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get tabQuiz;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @dataView.
  ///
  /// In en, this message translates to:
  /// **'Data View'**
  String get dataView;

  /// No description provided for @variableView.
  ///
  /// In en, this message translates to:
  /// **'Variable View'**
  String get variableView;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search cases / variables…'**
  String get searchHint;

  /// No description provided for @cases.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get cases;

  /// No description provided for @variables.
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get variables;

  /// No description provided for @addCase.
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get addCase;

  /// No description provided for @addVariable.
  ///
  /// In en, this message translates to:
  /// **'Add Variable'**
  String get addVariable;

  /// No description provided for @variableName.
  ///
  /// In en, this message translates to:
  /// **'Variable name'**
  String get variableName;

  /// No description provided for @loadDemo.
  ///
  /// In en, this message translates to:
  /// **'Load demo data'**
  String get loadDemo;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV…'**
  String get importCsv;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @showValueLabels.
  ///
  /// In en, this message translates to:
  /// **'Show value labels'**
  String get showValueLabels;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset all settings and data to defaults?'**
  String get resetConfirm;

  /// No description provided for @resetDone.
  ///
  /// In en, this message translates to:
  /// **'Settings and data have been reset'**
  String get resetDone;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About StatLab'**
  String get aboutTitle;

  /// No description provided for @aboutDesc.
  ///
  /// In en, this message translates to:
  /// **'A mobile-first, project-based statistical analysis suite with built-in learning and testing modules.'**
  String get aboutDesc;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme color'**
  String get themeColor;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @langSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get langSystem;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get langChinese;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @runAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Run analysis'**
  String get runAnalysis;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running…'**
  String get running;

  /// No description provided for @shareReport.
  ///
  /// In en, this message translates to:
  /// **'Share report'**
  String get shareReport;

  /// No description provided for @params.
  ///
  /// In en, this message translates to:
  /// **'Analysis parameters'**
  String get params;

  /// No description provided for @selectVariables.
  ///
  /// In en, this message translates to:
  /// **'Variables (multi-select)'**
  String get selectVariables;

  /// No description provided for @analysisVariable.
  ///
  /// In en, this message translates to:
  /// **'Analysis variable'**
  String get analysisVariable;

  /// No description provided for @groupVariable.
  ///
  /// In en, this message translates to:
  /// **'Grouping variable'**
  String get groupVariable;

  /// No description provided for @pairVariables.
  ///
  /// In en, this message translates to:
  /// **'Paired variables (pick 2)'**
  String get pairVariables;

  /// No description provided for @testValue.
  ///
  /// In en, this message translates to:
  /// **'Test value μ₀'**
  String get testValue;

  /// No description provided for @dependentVar.
  ///
  /// In en, this message translates to:
  /// **'Dependent Y'**
  String get dependentVar;

  /// No description provided for @independentVar.
  ///
  /// In en, this message translates to:
  /// **'Independent X'**
  String get independentVar;

  /// No description provided for @rowVariable.
  ///
  /// In en, this message translates to:
  /// **'Row variable'**
  String get rowVariable;

  /// No description provided for @columnVariable.
  ///
  /// In en, this message translates to:
  /// **'Column variable'**
  String get columnVariable;

  /// No description provided for @clusterCount.
  ///
  /// In en, this message translates to:
  /// **'Clusters k'**
  String get clusterCount;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Run failed'**
  String get failed;

  /// No description provided for @notImplemented.
  ///
  /// In en, this message translates to:
  /// **'This analysis is under development. Try descriptives or t-tests first.'**
  String get notImplemented;

  /// No description provided for @pleaseSelectVars.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one variable'**
  String get pleaseSelectVars;

  /// No description provided for @pleaseSelectGroup.
  ///
  /// In en, this message translates to:
  /// **'Please select analysis and grouping variables'**
  String get pleaseSelectGroup;

  /// No description provided for @pleaseSelectXY.
  ///
  /// In en, this message translates to:
  /// **'Please select Y and X'**
  String get pleaseSelectXY;

  /// No description provided for @needTwoGroups.
  ///
  /// In en, this message translates to:
  /// **'Need at least two groups'**
  String get needTwoGroups;

  /// No description provided for @needTwoVars.
  ///
  /// In en, this message translates to:
  /// **'Please select at least 2 variables'**
  String get needTwoVars;

  /// No description provided for @learnTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics Learning'**
  String get learnTitle;

  /// No description provided for @learnTagline.
  ///
  /// In en, this message translates to:
  /// **'From concepts to formulas'**
  String get learnTagline;

  /// No description provided for @learnIntro.
  ///
  /// In en, this message translates to:
  /// **'Master hypothesis tests, regression, nonparametrics and reliability through short lessons. Then practice in Quiz.'**
  String get learnIntro;

  /// No description provided for @coreFormulas.
  ///
  /// In en, this message translates to:
  /// **'Core formulas'**
  String get coreFormulas;

  /// No description provided for @quizTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics Quiz'**
  String get quizTitle;

  /// No description provided for @quizTagline.
  ///
  /// In en, this message translates to:
  /// **'Random questions · instant scoring'**
  String get quizTagline;

  /// No description provided for @quizIntro.
  ///
  /// In en, this message translates to:
  /// **'Question bank covers descriptives, t-tests, ANOVA, correlation, regression, chi-square, nonparametrics and reliability.'**
  String get quizIntro;

  /// No description provided for @questionCount.
  ///
  /// In en, this message translates to:
  /// **'Number of questions'**
  String get questionCount;

  /// No description provided for @questionsUnit.
  ///
  /// In en, this message translates to:
  /// **'questions'**
  String get questionsUnit;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start quiz'**
  String get startQuiz;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @prev.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get prev;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try another set'**
  String get retry;

  /// No description provided for @backToSetup.
  ///
  /// In en, this message translates to:
  /// **'Back to setup'**
  String get backToSetup;

  /// No description provided for @scoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Your score'**
  String get scoreTitle;

  /// No description provided for @quizGreat.
  ///
  /// In en, this message translates to:
  /// **'Excellent! Try more questions or practice in Analysis.'**
  String get quizGreat;

  /// No description provided for @quizGood.
  ///
  /// In en, this message translates to:
  /// **'Not bad — review the explanations for missed items.'**
  String get quizGood;

  /// No description provided for @quizLow.
  ///
  /// In en, this message translates to:
  /// **'Visit Learn first to strengthen concepts, then retry.'**
  String get quizLow;

  /// No description provided for @answerReview.
  ///
  /// In en, this message translates to:
  /// **'Answer review'**
  String get answerReview;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @yourChoice.
  ///
  /// In en, this message translates to:
  /// **'Your choice'**
  String get yourChoice;

  /// No description provided for @explanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get explanation;

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {n} of {total}'**
  String questionOf(int n, int total);

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {cases} cases × {vars} variables'**
  String importSuccess(int cases, int vars);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {e}'**
  String importFailed(String e);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {e}'**
  String exportFailed(String e);

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @editCase.
  ///
  /// In en, this message translates to:
  /// **'Edit case #{n}'**
  String editCase(int n);

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @measure.
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get measure;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @decimals.
  ///
  /// In en, this message translates to:
  /// **'Decimals'**
  String get decimals;

  /// No description provided for @valueLabels.
  ///
  /// In en, this message translates to:
  /// **'Value labels'**
  String get valueLabels;

  /// No description provided for @doubleClickEdit.
  ///
  /// In en, this message translates to:
  /// **'Double-click a cell to edit'**
  String get doubleClickEdit;

  /// No description provided for @cellEditHint.
  ///
  /// In en, this message translates to:
  /// **'Enter · Tab · Esc'**
  String get cellEditHint;

  /// No description provided for @row.
  ///
  /// In en, this message translates to:
  /// **'Row'**
  String get row;

  /// No description provided for @col.
  ///
  /// In en, this message translates to:
  /// **'Col'**
  String get col;

  /// No description provided for @deleteCase.
  ///
  /// In en, this message translates to:
  /// **'Delete case'**
  String get deleteCase;

  /// No description provided for @insertCase.
  ///
  /// In en, this message translates to:
  /// **'Insert case'**
  String get insertCase;

  /// No description provided for @duplicateCase.
  ///
  /// In en, this message translates to:
  /// **'Duplicate case'**
  String get duplicateCase;

  /// No description provided for @clearCell.
  ///
  /// In en, this message translates to:
  /// **'Clear cell'**
  String get clearCell;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importData;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportData;

  /// No description provided for @importSav.
  ///
  /// In en, this message translates to:
  /// **'Import SPSS .sav…'**
  String get importSav;

  /// No description provided for @importExcel.
  ///
  /// In en, this message translates to:
  /// **'Import Excel…'**
  String get importExcel;

  /// No description provided for @transformMenu.
  ///
  /// In en, this message translates to:
  /// **'Transforms…'**
  String get transformMenu;

  /// No description provided for @syntaxEditor.
  ///
  /// In en, this message translates to:
  /// **'Syntax editor…'**
  String get syntaxEditor;

  /// No description provided for @weightCases.
  ///
  /// In en, this message translates to:
  /// **'Weight cases…'**
  String get weightCases;

  /// No description provided for @splitFile.
  ///
  /// In en, this message translates to:
  /// **'Split file…'**
  String get splitFile;

  /// No description provided for @findCase.
  ///
  /// In en, this message translates to:
  /// **'Find cases…'**
  String get findCase;

  /// No description provided for @notWeighted.
  ///
  /// In en, this message translates to:
  /// **'Not weighted'**
  String get notWeighted;

  /// No description provided for @weightedBy.
  ///
  /// In en, this message translates to:
  /// **'Weighted by: {v}'**
  String weightedBy(String v);

  /// No description provided for @weightOff.
  ///
  /// In en, this message translates to:
  /// **'Weighting off'**
  String get weightOff;

  /// No description provided for @noSplit.
  ///
  /// In en, this message translates to:
  /// **'No split'**
  String get noSplit;

  /// No description provided for @splitBy.
  ///
  /// In en, this message translates to:
  /// **'Split by: {v}'**
  String splitBy(String v);

  /// No description provided for @splitOff.
  ///
  /// In en, this message translates to:
  /// **'Split off'**
  String get splitOff;

  /// No description provided for @find.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get find;

  /// No description provided for @findHint.
  ///
  /// In en, this message translates to:
  /// **'Enter text to find…'**
  String get findHint;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'「{q}」not found'**
  String notFound(String q);

  /// No description provided for @foundN.
  ///
  /// In en, this message translates to:
  /// **'Found {n}: {list}{more}'**
  String foundN(int n, String list, String more);

  /// No description provided for @noValueLabels.
  ///
  /// In en, this message translates to:
  /// **'No value labels defined'**
  String get noValueLabels;

  /// No description provided for @editValueLabels.
  ///
  /// In en, this message translates to:
  /// **'Edit value labels'**
  String get editValueLabels;

  /// No description provided for @missingValues.
  ///
  /// In en, this message translates to:
  /// **'Missing values'**
  String get missingValues;

  /// No description provided for @deleteVariable.
  ///
  /// In en, this message translates to:
  /// **'Delete variable'**
  String get deleteVariable;

  /// No description provided for @savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String savedTo(String path);

  /// No description provided for @shareFile.
  ///
  /// In en, this message translates to:
  /// **'Share file'**
  String get shareFile;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get copyToClipboard;

  /// No description provided for @shareDataText.
  ///
  /// In en, this message translates to:
  /// **'StatLab data export'**
  String get shareDataText;

  /// No description provided for @importDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importDataTitle;

  /// No description provided for @importDemoData.
  ///
  /// In en, this message translates to:
  /// **'Load demo data'**
  String get importDemoData;

  /// No description provided for @saveAndBack.
  ///
  /// In en, this message translates to:
  /// **'Save and back'**
  String get saveAndBack;

  /// No description provided for @importCsvSav.
  ///
  /// In en, this message translates to:
  /// **'Import CSV / SAV / Excel'**
  String get importCsvSav;

  /// No description provided for @saveProject.
  ///
  /// In en, this message translates to:
  /// **'Save project'**
  String get saveProject;

  /// No description provided for @closeProject.
  ///
  /// In en, this message translates to:
  /// **'Close project'**
  String get closeProject;

  /// No description provided for @projectSaved.
  ///
  /// In en, this message translates to:
  /// **'Project saved'**
  String get projectSaved;

  /// No description provided for @autoSavedAt.
  ///
  /// In en, this message translates to:
  /// **'Auto-saved {time}'**
  String autoSavedAt(String time);

  /// No description provided for @tabTransform.
  ///
  /// In en, this message translates to:
  /// **'Transform'**
  String get tabTransform;

  /// No description provided for @casesByVars.
  ///
  /// In en, this message translates to:
  /// **'{cases} cases × {vars} variables'**
  String casesByVars(int cases, int vars);

  /// No description provided for @syntaxTitle.
  ///
  /// In en, this message translates to:
  /// **'Syntax editor'**
  String get syntaxTitle;

  /// No description provided for @openSps.
  ///
  /// In en, this message translates to:
  /// **'Open .sps'**
  String get openSps;

  /// No description provided for @saveSps.
  ///
  /// In en, this message translates to:
  /// **'Save .sps'**
  String get saveSps;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @runSyntax.
  ///
  /// In en, this message translates to:
  /// **'Run syntax'**
  String get runSyntax;

  /// No description provided for @syntaxHint.
  ///
  /// In en, this message translates to:
  /// **'Enter SPSS-style syntax; statements end with a period…'**
  String get syntaxHint;

  /// No description provided for @outputHere.
  ///
  /// In en, this message translates to:
  /// **'Output will appear here'**
  String get outputHere;

  /// No description provided for @syntaxDone.
  ///
  /// In en, this message translates to:
  /// **'Done: {ok} ok, {fail} failed'**
  String syntaxDone(int ok, int fail);

  /// No description provided for @exportHtml.
  ///
  /// In en, this message translates to:
  /// **'Export HTML'**
  String get exportHtml;

  /// No description provided for @varY.
  ///
  /// In en, this message translates to:
  /// **'Variable Y'**
  String get varY;

  /// No description provided for @varX.
  ///
  /// In en, this message translates to:
  /// **'Variable X'**
  String get varX;

  /// No description provided for @notImplementedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not implemented yet'**
  String get notImplementedTitle;

  /// No description provided for @hintTitle.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hintTitle;

  /// No description provided for @pleaseSelectTestVar.
  ///
  /// In en, this message translates to:
  /// **'Please select a test variable'**
  String get pleaseSelectTestVar;

  /// No description provided for @pleaseSelectPaired.
  ///
  /// In en, this message translates to:
  /// **'Please select 2 paired variables'**
  String get pleaseSelectPaired;

  /// No description provided for @pleaseSelectRowCol.
  ///
  /// In en, this message translates to:
  /// **'Please select row and column variables'**
  String get pleaseSelectRowCol;

  /// No description provided for @pleaseSelectTwoVars.
  ///
  /// In en, this message translates to:
  /// **'Please select 2 variables'**
  String get pleaseSelectTwoVars;

  /// No description provided for @atLeastTwoGroups.
  ///
  /// In en, this message translates to:
  /// **'Need at least 2 groups'**
  String get atLeastTwoGroups;

  /// No description provided for @pleaseSelectItems.
  ///
  /// In en, this message translates to:
  /// **'Please select at least 2 item variables'**
  String get pleaseSelectItems;

  /// No description provided for @pleaseSelectVar.
  ///
  /// In en, this message translates to:
  /// **'Please select a variable'**
  String get pleaseSelectVar;

  /// No description provided for @pleaseSelectXYShort.
  ///
  /// In en, this message translates to:
  /// **'Please select X/Y'**
  String get pleaseSelectXYShort;

  /// No description provided for @pleaseSelectStateVar.
  ///
  /// In en, this message translates to:
  /// **'Please select state and test variables'**
  String get pleaseSelectStateVar;

  /// No description provided for @pleaseSelectDepVar.
  ///
  /// In en, this message translates to:
  /// **'Please select dependent variable'**
  String get pleaseSelectDepVar;

  /// No description provided for @pleaseSelectPredictors.
  ///
  /// In en, this message translates to:
  /// **'Please select at least 2 predictors'**
  String get pleaseSelectPredictors;

  /// No description provided for @varNotFound.
  ///
  /// In en, this message translates to:
  /// **'Variable not found'**
  String get varNotFound;

  /// No description provided for @noValidData.
  ///
  /// In en, this message translates to:
  /// **'No valid data'**
  String get noValidData;

  /// No description provided for @reportVar.
  ///
  /// In en, this message translates to:
  /// **'Variable'**
  String get reportVar;

  /// No description provided for @mean.
  ///
  /// In en, this message translates to:
  /// **'Mean'**
  String get mean;

  /// No description provided for @stdDev.
  ///
  /// In en, this message translates to:
  /// **'Std. deviation'**
  String get stdDev;

  /// No description provided for @variance.
  ///
  /// In en, this message translates to:
  /// **'Variance'**
  String get variance;

  /// No description provided for @minWord.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minWord;

  /// No description provided for @maxWord.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxWord;

  /// No description provided for @skewness.
  ///
  /// In en, this message translates to:
  /// **'Skewness'**
  String get skewness;

  /// No description provided for @kurtosis.
  ///
  /// In en, this message translates to:
  /// **'Kurtosis'**
  String get kurtosis;

  /// No description provided for @median.
  ///
  /// In en, this message translates to:
  /// **'Median'**
  String get median;

  /// No description provided for @se.
  ///
  /// In en, this message translates to:
  /// **'Std. error'**
  String get se;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @pTwoTail.
  ///
  /// In en, this message translates to:
  /// **'p (2-tailed)'**
  String get pTwoTail;

  /// No description provided for @meanDiff.
  ///
  /// In en, this message translates to:
  /// **'Mean difference'**
  String get meanDiff;

  /// No description provided for @seDiff.
  ///
  /// In en, this message translates to:
  /// **'Std. error of difference'**
  String get seDiff;

  /// No description provided for @ciLower.
  ///
  /// In en, this message translates to:
  /// **'95% CI lower'**
  String get ciLower;

  /// No description provided for @ciUpper.
  ///
  /// In en, this message translates to:
  /// **'95% CI upper'**
  String get ciUpper;

  /// No description provided for @descriptivesTitle.
  ///
  /// In en, this message translates to:
  /// **'Descriptives'**
  String get descriptivesTitle;

  /// No description provided for @descriptivesStats.
  ///
  /// In en, this message translates to:
  /// **'Descriptive statistics'**
  String get descriptivesStats;

  /// No description provided for @descByVar.
  ///
  /// In en, this message translates to:
  /// **'Descriptives by variable'**
  String get descByVar;

  /// No description provided for @quantilesCi.
  ///
  /// In en, this message translates to:
  /// **'Quantiles & confidence intervals'**
  String get quantilesCi;

  /// No description provided for @ciNote.
  ///
  /// In en, this message translates to:
  /// **'Confidence intervals are based on the t distribution at the 95% level.'**
  String get ciNote;

  /// No description provided for @ttestTitle.
  ///
  /// In en, this message translates to:
  /// **'t-test'**
  String get ttestTitle;

  /// No description provided for @groupStats.
  ///
  /// In en, this message translates to:
  /// **'Group statistics'**
  String get groupStats;

  /// No description provided for @group1.
  ///
  /// In en, this message translates to:
  /// **'Group 1'**
  String get group1;

  /// No description provided for @group2.
  ///
  /// In en, this message translates to:
  /// **'Group 2'**
  String get group2;

  /// No description provided for @independentTest.
  ///
  /// In en, this message translates to:
  /// **'Independent samples test'**
  String get independentTest;

  /// No description provided for @leveneNote.
  ///
  /// In en, this message translates to:
  /// **'Levene\'s test: F={f}, p={p}; {assumption}'**
  String leveneNote(String f, String p, String assumption);

  /// No description provided for @equalVarAssumed.
  ///
  /// In en, this message translates to:
  /// **'equal variances assumed'**
  String get equalVarAssumed;

  /// No description provided for @equalVarNotAssumed.
  ///
  /// In en, this message translates to:
  /// **'equal variances not assumed (Welch)'**
  String get equalVarNotAssumed;

  /// No description provided for @oneSampleLabel.
  ///
  /// In en, this message translates to:
  /// **'One-sample {name} vs μ={mu}'**
  String oneSampleLabel(String name, String mu);

  /// No description provided for @pairedLabel.
  ///
  /// In en, this message translates to:
  /// **'Paired {a} vs {b}'**
  String pairedLabel(String a, String b);

  /// No description provided for @anovaTitle.
  ///
  /// In en, this message translates to:
  /// **'One-way ANOVA'**
  String get anovaTitle;

  /// No description provided for @anovaTable.
  ///
  /// In en, this message translates to:
  /// **'ANOVA table'**
  String get anovaTable;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @ss.
  ///
  /// In en, this message translates to:
  /// **'Sum of squares'**
  String get ss;

  /// No description provided for @ms.
  ///
  /// In en, this message translates to:
  /// **'Mean square'**
  String get ms;

  /// No description provided for @betweenGroups.
  ///
  /// In en, this message translates to:
  /// **'Between groups'**
  String get betweenGroups;

  /// No description provided for @withinGroups.
  ///
  /// In en, this message translates to:
  /// **'Within groups'**
  String get withinGroups;

  /// No description provided for @anovaNote.
  ///
  /// In en, this message translates to:
  /// **'ω²={w}; Levene F={f}, p={p}.'**
  String anovaNote(String w, String f, String p);

  /// No description provided for @anovaOfLabel.
  ///
  /// In en, this message translates to:
  /// **'One-way ANOVA: {v} by {g}'**
  String anovaOfLabel(String v, String g);

  /// No description provided for @corrTitle.
  ///
  /// In en, this message translates to:
  /// **'Correlation analysis'**
  String get corrTitle;

  /// No description provided for @corrCoef.
  ///
  /// In en, this message translates to:
  /// **'Correlation coefficients'**
  String get corrCoef;

  /// No description provided for @sigTwoTail.
  ///
  /// In en, this message translates to:
  /// **'Significance (two-tailed p)'**
  String get sigTwoTail;

  /// No description provided for @corrStars.
  ///
  /// In en, this message translates to:
  /// **'*** p<.001  ** p<.01  * p<.05'**
  String get corrStars;

  /// No description provided for @regressionTitle.
  ///
  /// In en, this message translates to:
  /// **'Linear regression'**
  String get regressionTitle;

  /// No description provided for @depVarColon.
  ///
  /// In en, this message translates to:
  /// **'Dependent: {y}'**
  String depVarColon(String y);

  /// No description provided for @modelSummary.
  ///
  /// In en, this message translates to:
  /// **'Model summary'**
  String get modelSummary;

  /// No description provided for @adjR2.
  ///
  /// In en, this message translates to:
  /// **'Adjusted R²'**
  String get adjR2;

  /// No description provided for @regressionWord.
  ///
  /// In en, this message translates to:
  /// **'Regression'**
  String get regressionWord;

  /// No description provided for @residual.
  ///
  /// In en, this message translates to:
  /// **'Residual'**
  String get residual;

  /// No description provided for @coefficients.
  ///
  /// In en, this message translates to:
  /// **'Coefficients'**
  String get coefficients;

  /// No description provided for @term.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get term;

  /// No description provided for @stdBeta.
  ///
  /// In en, this message translates to:
  /// **'Std. β'**
  String get stdBeta;

  /// No description provided for @chiSquareTitle.
  ///
  /// In en, this message translates to:
  /// **'Chi-square test'**
  String get chiSquareTitle;

  /// No description provided for @statistic.
  ///
  /// In en, this message translates to:
  /// **'Statistic'**
  String get statistic;

  /// No description provided for @valueWord.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueWord;

  /// No description provided for @likelihoodRatio.
  ///
  /// In en, this message translates to:
  /// **'Likelihood ratio G²'**
  String get likelihoodRatio;

  /// No description provided for @association.
  ///
  /// In en, this message translates to:
  /// **'Association'**
  String get association;

  /// No description provided for @cellsObsExp.
  ///
  /// In en, this message translates to:
  /// **'Cells (observed / expected)'**
  String get cellsObsExp;

  /// No description provided for @observed.
  ///
  /// In en, this message translates to:
  /// **'Observed'**
  String get observed;

  /// No description provided for @expected.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get expected;

  /// No description provided for @stdResidual.
  ///
  /// In en, this message translates to:
  /// **'Std. residual'**
  String get stdResidual;

  /// No description provided for @kmeansTitle.
  ///
  /// In en, this message translates to:
  /// **'K-Means clustering'**
  String get kmeansTitle;

  /// No description provided for @kmeansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'k={k} · {iters} iterations · inertia={inertia}'**
  String kmeansSubtitle(int k, int iters, String inertia);

  /// No description provided for @finalClusterCenters.
  ///
  /// In en, this message translates to:
  /// **'Final cluster centers'**
  String get finalClusterCenters;

  /// No description provided for @cluster.
  ///
  /// In en, this message translates to:
  /// **'Cluster'**
  String get cluster;

  /// No description provided for @caseCount.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get caseCount;

  /// No description provided for @reliabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Reliability analysis'**
  String get reliabilityTitle;

  /// No description provided for @reliabilityStats.
  ///
  /// In en, this message translates to:
  /// **'Reliability statistics'**
  String get reliabilityStats;

  /// No description provided for @stdAlpha.
  ///
  /// In en, this message translates to:
  /// **'Standardized α'**
  String get stdAlpha;

  /// No description provided for @nItemsWord.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get nItemsWord;

  /// No description provided for @itemStats.
  ///
  /// In en, this message translates to:
  /// **'Item statistics'**
  String get itemStats;

  /// No description provided for @itemWord.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemWord;

  /// No description provided for @itemTotalCorr.
  ///
  /// In en, this message translates to:
  /// **'Corrected item-total correlation'**
  String get itemTotalCorr;

  /// No description provided for @alphaIfDeleted.
  ///
  /// In en, this message translates to:
  /// **'α if item deleted'**
  String get alphaIfDeleted;

  /// No description provided for @histogramTitle.
  ///
  /// In en, this message translates to:
  /// **'Histogram'**
  String get histogramTitle;

  /// No description provided for @binFreq.
  ///
  /// In en, this message translates to:
  /// **'Bin frequencies'**
  String get binFreq;

  /// No description provided for @lower.
  ///
  /// In en, this message translates to:
  /// **'Lower'**
  String get lower;

  /// No description provided for @upper.
  ///
  /// In en, this message translates to:
  /// **'Upper'**
  String get upper;

  /// No description provided for @freq.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get freq;

  /// No description provided for @scatterTitle.
  ///
  /// In en, this message translates to:
  /// **'Scatter plot'**
  String get scatterTitle;

  /// No description provided for @corrFit.
  ///
  /// In en, this message translates to:
  /// **'Correlation & fit'**
  String get corrFit;

  /// No description provided for @slope.
  ///
  /// In en, this message translates to:
  /// **'Slope'**
  String get slope;

  /// No description provided for @intercept.
  ///
  /// In en, this message translates to:
  /// **'Intercept'**
  String get intercept;

  /// No description provided for @barTitle.
  ///
  /// In en, this message translates to:
  /// **'Bar chart / frequencies'**
  String get barTitle;

  /// No description provided for @freqTable.
  ///
  /// In en, this message translates to:
  /// **'Frequency table'**
  String get freqTable;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @percent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get percent;

  /// No description provided for @validPercent.
  ///
  /// In en, this message translates to:
  /// **'Valid percent'**
  String get validPercent;

  /// No description provided for @cumulativePercent.
  ///
  /// In en, this message translates to:
  /// **'Cumulative %'**
  String get cumulativePercent;

  /// No description provided for @freqNote.
  ///
  /// In en, this message translates to:
  /// **'Valid N={n}  Missing={m}'**
  String freqNote(int n, int m);

  /// No description provided for @meansTitle.
  ///
  /// In en, this message translates to:
  /// **'Layered means'**
  String get meansTitle;

  /// No description provided for @normalityTitle.
  ///
  /// In en, this message translates to:
  /// **'Normality test'**
  String get normalityTitle;

  /// No description provided for @resultWord.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultWord;

  /// No description provided for @testWord.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get testWord;

  /// No description provided for @verdictWord.
  ///
  /// In en, this message translates to:
  /// **'Verdict'**
  String get verdictWord;

  /// No description provided for @looksNormal.
  ///
  /// In en, this message translates to:
  /// **'Approximately normal'**
  String get looksNormal;

  /// No description provided for @deviatesNormal.
  ///
  /// In en, this message translates to:
  /// **'Deviates from normal'**
  String get deviatesNormal;

  /// No description provided for @normalityNote.
  ///
  /// In en, this message translates to:
  /// **'Approximately normal when p>0.05, |skewness|<1.5 and |kurtosis|<3.'**
  String get normalityNote;

  /// No description provided for @rocTitle.
  ///
  /// In en, this message translates to:
  /// **'ROC curve'**
  String get rocTitle;

  /// No description provided for @aucSection.
  ///
  /// In en, this message translates to:
  /// **'Area under the curve'**
  String get aucSection;

  /// No description provided for @rocNote.
  ///
  /// In en, this message translates to:
  /// **'AUC 0.5 = no discrimination, 0.7–0.8 fair, >0.8 good.'**
  String get rocNote;

  /// No description provided for @tukeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Post hoc pairwise comparisons'**
  String get tukeyTitle;

  /// No description provided for @pairwise.
  ///
  /// In en, this message translates to:
  /// **'Pairwise'**
  String get pairwise;

  /// No description provided for @significant.
  ///
  /// In en, this message translates to:
  /// **'Significant'**
  String get significant;

  /// No description provided for @tukeyNote.
  ///
  /// In en, this message translates to:
  /// **'Overall F={f}, p={p}.'**
  String tukeyNote(String f, String p);

  /// No description provided for @factorPcaTitle.
  ///
  /// In en, this message translates to:
  /// **'PCA factor analysis'**
  String get factorPcaTitle;

  /// No description provided for @eigenSection.
  ///
  /// In en, this message translates to:
  /// **'Eigenvalues & variance'**
  String get eigenSection;

  /// No description provided for @component.
  ///
  /// In en, this message translates to:
  /// **'Component'**
  String get component;

  /// No description provided for @eigenvalue.
  ///
  /// In en, this message translates to:
  /// **'Eigenvalue'**
  String get eigenvalue;

  /// No description provided for @varExplained.
  ///
  /// In en, this message translates to:
  /// **'% of variance'**
  String get varExplained;

  /// No description provided for @cumulative.
  ///
  /// In en, this message translates to:
  /// **'Cumulative'**
  String get cumulative;

  /// No description provided for @loadingsMatrix.
  ///
  /// In en, this message translates to:
  /// **'Loading matrix'**
  String get loadingsMatrix;

  /// No description provided for @factorPcaNote.
  ///
  /// In en, this message translates to:
  /// **'Total variance explained: {v}. PCA on the correlation matrix (unrotated).'**
  String factorPcaNote(String v);

  /// No description provided for @logisticTitle.
  ///
  /// In en, this message translates to:
  /// **'Logistic regression'**
  String get logisticTitle;

  /// No description provided for @modelWord.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelWord;

  /// No description provided for @orExpB.
  ///
  /// In en, this message translates to:
  /// **'OR=exp(B)'**
  String get orExpB;

  /// No description provided for @pseudoR2Mcfadden.
  ///
  /// In en, this message translates to:
  /// **'Pseudo R² (McFadden)'**
  String get pseudoR2Mcfadden;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @iterations.
  ///
  /// In en, this message translates to:
  /// **'Iterations'**
  String get iterations;

  /// No description provided for @logisticNote.
  ///
  /// In en, this message translates to:
  /// **'Fitted by gradient descent; n ≥ 30 recommended. OR>1 means increased risk.'**
  String get logisticNote;

  /// No description provided for @examineDesc.
  ///
  /// In en, this message translates to:
  /// **'Descriptives'**
  String get examineDesc;

  /// No description provided for @percentileWord.
  ///
  /// In en, this message translates to:
  /// **'Percentiles'**
  String get percentileWord;

  /// No description provided for @trimmedNote.
  ///
  /// In en, this message translates to:
  /// **'5% trimmed mean={a}  Winsorized={b}'**
  String trimmedNote(String a, String b);

  /// No description provided for @extremes.
  ///
  /// In en, this message translates to:
  /// **'Extremes'**
  String get extremes;

  /// No description provided for @lowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get lowest;

  /// No description provided for @highest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get highest;

  /// No description provided for @boxSection.
  ///
  /// In en, this message translates to:
  /// **'Boxplot'**
  String get boxSection;

  /// No description provided for @lowerWhisker.
  ///
  /// In en, this message translates to:
  /// **'Lower whisker'**
  String get lowerWhisker;

  /// No description provided for @upperWhisker.
  ///
  /// In en, this message translates to:
  /// **'Upper whisker'**
  String get upperWhisker;

  /// No description provided for @medianShort.
  ///
  /// In en, this message translates to:
  /// **'Median'**
  String get medianShort;

  /// No description provided for @outliers.
  ///
  /// In en, this message translates to:
  /// **'Outliers'**
  String get outliers;

  /// No description provided for @stemLeaf.
  ///
  /// In en, this message translates to:
  /// **'Stem-and-leaf'**
  String get stemLeaf;

  /// No description provided for @normalityDap.
  ///
  /// In en, this message translates to:
  /// **'Normality (D\'Agostino-Pearson)'**
  String get normalityDap;

  /// No description provided for @zSkew.
  ///
  /// In en, this message translates to:
  /// **'Z skewness'**
  String get zSkew;

  /// No description provided for @zKurt.
  ///
  /// In en, this message translates to:
  /// **'Z kurtosis'**
  String get zKurt;

  /// No description provided for @boxplotTitle.
  ///
  /// In en, this message translates to:
  /// **'Boxplot'**
  String get boxplotTitle;

  /// No description provided for @distSummary.
  ///
  /// In en, this message translates to:
  /// **'Distribution summary'**
  String get distSummary;

  /// No description provided for @qqTitle.
  ///
  /// In en, this message translates to:
  /// **'Q-Q plot'**
  String get qqTitle;

  /// No description provided for @qqSection.
  ///
  /// In en, this message translates to:
  /// **'Normal quantile comparison'**
  String get qqSection;

  /// No description provided for @qqNote.
  ///
  /// In en, this message translates to:
  /// **'{n} points; the closer to the y=x line, the more normal.'**
  String qqNote(int n);

  /// No description provided for @factorFullTitle.
  ///
  /// In en, this message translates to:
  /// **'Factor analysis (full)'**
  String get factorFullTitle;

  /// No description provided for @adequacySection.
  ///
  /// In en, this message translates to:
  /// **'Adequacy & sphericity'**
  String get adequacySection;

  /// No description provided for @kmoPerVar.
  ///
  /// In en, this message translates to:
  /// **'Per-variable KMO'**
  String get kmoPerVar;

  /// No description provided for @eigenCommunalities.
  ///
  /// In en, this message translates to:
  /// **'Eigenvalues / communalities'**
  String get eigenCommunalities;

  /// No description provided for @communality.
  ///
  /// In en, this message translates to:
  /// **'Communality'**
  String get communality;

  /// No description provided for @varimaxLoadings.
  ///
  /// In en, this message translates to:
  /// **'Varimax rotated loadings'**
  String get varimaxLoadings;

  /// No description provided for @rotationNote.
  ///
  /// In en, this message translates to:
  /// **'Rotation SS={v}'**
  String rotationNote(String v);

  /// No description provided for @logisticFullTitle.
  ///
  /// In en, this message translates to:
  /// **'Logistic regression (full)'**
  String get logisticFullTitle;

  /// No description provided for @waldCoefficients.
  ///
  /// In en, this message translates to:
  /// **'Coefficients (Wald)'**
  String get waldCoefficients;

  /// No description provided for @modelClassification.
  ///
  /// In en, this message translates to:
  /// **'Model & classification'**
  String get modelClassification;

  /// No description provided for @classificationTable.
  ///
  /// In en, this message translates to:
  /// **'Classification table (threshold 0.5)'**
  String get classificationTable;

  /// No description provided for @sensitivity.
  ///
  /// In en, this message translates to:
  /// **'Sensitivity'**
  String get sensitivity;

  /// No description provided for @specificity.
  ///
  /// In en, this message translates to:
  /// **'Specificity'**
  String get specificity;

  /// No description provided for @precision.
  ///
  /// In en, this message translates to:
  /// **'Precision'**
  String get precision;

  /// No description provided for @nGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get nGroups;

  /// No description provided for @glmOneTitle.
  ///
  /// In en, this message translates to:
  /// **'GLM one-way ANOVA'**
  String get glmOneTitle;

  /// No description provided for @glmTwoTitle.
  ///
  /// In en, this message translates to:
  /// **'GLM two-way ANOVA'**
  String get glmTwoTitle;

  /// No description provided for @betweenEffects.
  ///
  /// In en, this message translates to:
  /// **'Between-subjects effects'**
  String get betweenEffects;

  /// No description provided for @partialEta2.
  ///
  /// In en, this message translates to:
  /// **'Partial η²'**
  String get partialEta2;

  /// No description provided for @errorWord.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorWord;

  /// No description provided for @glmNote.
  ///
  /// In en, this message translates to:
  /// **'R²={r2}  Adjusted R²={adj}  RMSE={rmse}  N={n}'**
  String glmNote(String r2, String adj, String rmse, int n);

  /// No description provided for @stepwiseTitle.
  ///
  /// In en, this message translates to:
  /// **'Stepwise regression'**
  String get stepwiseTitle;

  /// No description provided for @enteredVars.
  ///
  /// In en, this message translates to:
  /// **'Variables entered'**
  String get enteredVars;

  /// No description provided for @noneEntered.
  ///
  /// In en, this message translates to:
  /// **'(no variables entered)'**
  String get noneEntered;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @enter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enter;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @ctablesTitle.
  ///
  /// In en, this message translates to:
  /// **'CTABLES pivot table'**
  String get ctablesTitle;

  /// No description provided for @summaryCounts.
  ///
  /// In en, this message translates to:
  /// **'Summary (counts)'**
  String get summaryCounts;

  /// No description provided for @nonparamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nonparametric test'**
  String get nonparamSubtitle;

  /// No description provided for @testResult.
  ///
  /// In en, this message translates to:
  /// **'Test result'**
  String get testResult;

  /// No description provided for @meanRank1.
  ///
  /// In en, this message translates to:
  /// **'Mean rank 1'**
  String get meanRank1;

  /// No description provided for @meanRank2.
  ///
  /// In en, this message translates to:
  /// **'Mean rank 2'**
  String get meanRank2;

  /// No description provided for @generatedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated: {time}'**
  String generatedAt(String time);

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Statistical analysis workbench'**
  String get splashTagline;

  /// No description provided for @splashSkip.
  ///
  /// In en, this message translates to:
  /// **'Tap to skip'**
  String get splashSkip;

  /// No description provided for @projHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projHeroTitle;

  /// No description provided for @projHeroDesc.
  ///
  /// In en, this message translates to:
  /// **'Each project is a standalone dataset. Create, open, duplicate or delete a project, then edit data and run analyses inside.'**
  String get projHeroDesc;

  /// No description provided for @projNewDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo project'**
  String get projNewDemo;

  /// No description provided for @projNewBlank.
  ///
  /// In en, this message translates to:
  /// **'New blank'**
  String get projNewBlank;

  /// No description provided for @projSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search projects…'**
  String get projSearchHint;

  /// No description provided for @projCount.
  ///
  /// In en, this message translates to:
  /// **'{n} projects'**
  String projCount(int n);

  /// No description provided for @projEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get projEmptyTitle;

  /// No description provided for @projEmptyMsg.
  ///
  /// In en, this message translates to:
  /// **'Tap “Demo project” or “New blank” to get started.'**
  String get projEmptyMsg;

  /// No description provided for @projNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching projects'**
  String get projNoMatchTitle;

  /// No description provided for @projNoMatchMsg.
  ///
  /// In en, this message translates to:
  /// **'Try another keyword.'**
  String get projNoMatchMsg;

  /// No description provided for @projNewProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projNewProject;

  /// No description provided for @projNewDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'New demo project'**
  String get projNewDemoTitle;

  /// No description provided for @projNewBlankTitle.
  ///
  /// In en, this message translates to:
  /// **'New blank project'**
  String get projNewBlankTitle;

  /// No description provided for @projNameField.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projNameField;

  /// No description provided for @projDescField.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get projDescField;

  /// No description provided for @projCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get projCreate;

  /// No description provided for @projRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename project'**
  String get projRenameTitle;

  /// No description provided for @projNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get projNameLabel;

  /// No description provided for @projDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get projDeleteTitle;

  /// No description provided for @projDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”? This cannot be undone.'**
  String projDeleteMsg(String name);

  /// No description provided for @projDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get projDeleteAction;

  /// No description provided for @projDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Project duplicated'**
  String get projDuplicated;

  /// No description provided for @projOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open project'**
  String get projOpenFailed;

  /// No description provided for @projOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get projOpen;

  /// No description provided for @projDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get projDuplicate;

  /// No description provided for @projRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get projRecent;

  /// No description provided for @projAll.
  ///
  /// In en, this message translates to:
  /// **'All projects'**
  String get projAll;

  /// No description provided for @projUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String projUpdatedAt(String time);

  /// No description provided for @projUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get projUntitled;

  /// No description provided for @projCopySuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} copy'**
  String projCopySuffix(String name);

  /// No description provided for @casesByVarsShort.
  ///
  /// In en, this message translates to:
  /// **'{cases} cases · {vars} vars'**
  String casesByVarsShort(int cases, int vars);

  /// No description provided for @projDemoName.
  ///
  /// In en, this message translates to:
  /// **'Demo · scores'**
  String get projDemoName;

  /// No description provided for @projDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Project {n}'**
  String projDefaultName(int n);

  /// No description provided for @anSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search analyses…'**
  String get anSearchHint;

  /// No description provided for @anRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently used'**
  String get anRecent;

  /// No description provided for @anFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get anFavorites;

  /// No description provided for @anResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get anResults;

  /// No description provided for @anNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching analysis'**
  String get anNoMatch;

  /// No description provided for @anAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get anAdvanced;

  /// No description provided for @anCatDescribe.
  ///
  /// In en, this message translates to:
  /// **'Descriptives & exploration'**
  String get anCatDescribe;

  /// No description provided for @anCatCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare means'**
  String get anCatCompare;

  /// No description provided for @anCatCorrelate.
  ///
  /// In en, this message translates to:
  /// **'Correlation & association'**
  String get anCatCorrelate;

  /// No description provided for @anCatModel.
  ///
  /// In en, this message translates to:
  /// **'Regression & clustering'**
  String get anCatModel;

  /// No description provided for @anCatNonparam.
  ///
  /// In en, this message translates to:
  /// **'Nonparametric & reliability'**
  String get anCatNonparam;

  /// No description provided for @anCatExtra.
  ///
  /// In en, this message translates to:
  /// **'Additional procedures'**
  String get anCatExtra;

  /// No description provided for @anCatDimreduce.
  ///
  /// In en, this message translates to:
  /// **'Dimension reduction & classification'**
  String get anCatDimreduce;

  /// No description provided for @anCatCharts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get anCatCharts;

  /// No description provided for @anDescriptives.
  ///
  /// In en, this message translates to:
  /// **'Descriptives'**
  String get anDescriptives;

  /// No description provided for @anDescriptivesDesc.
  ///
  /// In en, this message translates to:
  /// **'Mean, SD, skewness, kurtosis, confidence intervals'**
  String get anDescriptivesDesc;

  /// No description provided for @anFrequencies.
  ///
  /// In en, this message translates to:
  /// **'Frequencies'**
  String get anFrequencies;

  /// No description provided for @anFrequenciesDesc.
  ///
  /// In en, this message translates to:
  /// **'Frequency tables, percentages, cumulative'**
  String get anFrequenciesDesc;

  /// No description provided for @anExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get anExplore;

  /// No description provided for @anExploreDesc.
  ///
  /// In en, this message translates to:
  /// **'Percentiles, extremes, normality'**
  String get anExploreDesc;

  /// No description provided for @anTtestOne.
  ///
  /// In en, this message translates to:
  /// **'One-sample t test'**
  String get anTtestOne;

  /// No description provided for @anTtestOneDesc.
  ///
  /// In en, this message translates to:
  /// **'Mean vs test value'**
  String get anTtestOneDesc;

  /// No description provided for @anTtestInd.
  ///
  /// In en, this message translates to:
  /// **'Independent-samples t test'**
  String get anTtestInd;

  /// No description provided for @anTtestIndDesc.
  ///
  /// In en, this message translates to:
  /// **'Two group means + Levene'**
  String get anTtestIndDesc;

  /// No description provided for @anTtestPaired.
  ///
  /// In en, this message translates to:
  /// **'Paired-samples t test'**
  String get anTtestPaired;

  /// No description provided for @anTtestPairedDesc.
  ///
  /// In en, this message translates to:
  /// **'Pre/post or matched design'**
  String get anTtestPairedDesc;

  /// No description provided for @anAnova.
  ///
  /// In en, this message translates to:
  /// **'One-way ANOVA'**
  String get anAnova;

  /// No description provided for @anAnovaDesc.
  ///
  /// In en, this message translates to:
  /// **'Multiple group means + effect size'**
  String get anAnovaDesc;

  /// No description provided for @anCorrelation.
  ///
  /// In en, this message translates to:
  /// **'Correlation'**
  String get anCorrelation;

  /// No description provided for @anCorrelationDesc.
  ///
  /// In en, this message translates to:
  /// **'Pearson / Spearman matrix'**
  String get anCorrelationDesc;

  /// No description provided for @anCrosstabs.
  ///
  /// In en, this message translates to:
  /// **'Crosstabs & chi-square'**
  String get anCrosstabs;

  /// No description provided for @anCrosstabsDesc.
  ///
  /// In en, this message translates to:
  /// **'Contingency table, χ², Cramér V'**
  String get anCrosstabsDesc;

  /// No description provided for @anRegression.
  ///
  /// In en, this message translates to:
  /// **'Linear regression'**
  String get anRegression;

  /// No description provided for @anRegressionDesc.
  ///
  /// In en, this message translates to:
  /// **'Simple / multiple, coefficient table'**
  String get anRegressionDesc;

  /// No description provided for @anKmeans.
  ///
  /// In en, this message translates to:
  /// **'K-Means clustering'**
  String get anKmeans;

  /// No description provided for @anKmeansDesc.
  ///
  /// In en, this message translates to:
  /// **'Fast clustering, cluster centers'**
  String get anKmeansDesc;

  /// No description provided for @anMannwhitney.
  ///
  /// In en, this message translates to:
  /// **'Mann-Whitney U'**
  String get anMannwhitney;

  /// No description provided for @anMannwhitneyDesc.
  ///
  /// In en, this message translates to:
  /// **'Two independent samples, rank sum'**
  String get anMannwhitneyDesc;

  /// No description provided for @anWilcoxon.
  ///
  /// In en, this message translates to:
  /// **'Wilcoxon signed-rank'**
  String get anWilcoxon;

  /// No description provided for @anWilcoxonDesc.
  ///
  /// In en, this message translates to:
  /// **'Two related samples'**
  String get anWilcoxonDesc;

  /// No description provided for @anKruskal.
  ///
  /// In en, this message translates to:
  /// **'Kruskal-Wallis H'**
  String get anKruskal;

  /// No description provided for @anKruskalDesc.
  ///
  /// In en, this message translates to:
  /// **'k independent samples'**
  String get anKruskalDesc;

  /// No description provided for @anReliability.
  ///
  /// In en, this message translates to:
  /// **'Cronbach α reliability'**
  String get anReliability;

  /// No description provided for @anReliabilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Internal consistency of a scale'**
  String get anReliabilityDesc;

  /// No description provided for @anMeans.
  ///
  /// In en, this message translates to:
  /// **'Layered means (MEANS)'**
  String get anMeans;

  /// No description provided for @anMeansDesc.
  ///
  /// In en, this message translates to:
  /// **'Grouped mean table'**
  String get anMeansDesc;

  /// No description provided for @anNormality.
  ///
  /// In en, this message translates to:
  /// **'Normality tests'**
  String get anNormality;

  /// No description provided for @anNormalityDesc.
  ///
  /// In en, this message translates to:
  /// **'KS / skewness & kurtosis'**
  String get anNormalityDesc;

  /// No description provided for @anExamineFull.
  ///
  /// In en, this message translates to:
  /// **'EXAMINE suite'**
  String get anExamineFull;

  /// No description provided for @anExamineFullDesc.
  ///
  /// In en, this message translates to:
  /// **'Percentiles / extremes / stem-and-leaf / boxplot / Q-Q'**
  String get anExamineFullDesc;

  /// No description provided for @anBoxplot.
  ///
  /// In en, this message translates to:
  /// **'Boxplot'**
  String get anBoxplot;

  /// No description provided for @anBoxplotDesc.
  ///
  /// In en, this message translates to:
  /// **'Compare distributions across groups'**
  String get anBoxplotDesc;

  /// No description provided for @anQqplot.
  ///
  /// In en, this message translates to:
  /// **'Q-Q plot'**
  String get anQqplot;

  /// No description provided for @anQqplotDesc.
  ///
  /// In en, this message translates to:
  /// **'Normal quantile plot'**
  String get anQqplotDesc;

  /// No description provided for @anRoc.
  ///
  /// In en, this message translates to:
  /// **'ROC curve'**
  String get anRoc;

  /// No description provided for @anRocDesc.
  ///
  /// In en, this message translates to:
  /// **'AUC and diagnostics'**
  String get anRocDesc;

  /// No description provided for @anTukey.
  ///
  /// In en, this message translates to:
  /// **'Tukey post hoc'**
  String get anTukey;

  /// No description provided for @anTukeyDesc.
  ///
  /// In en, this message translates to:
  /// **'Pairwise differences after ANOVA'**
  String get anTukeyDesc;

  /// No description provided for @anFactorPca.
  ///
  /// In en, this message translates to:
  /// **'PCA factor analysis'**
  String get anFactorPca;

  /// No description provided for @anFactorPcaDesc.
  ///
  /// In en, this message translates to:
  /// **'Loading matrix'**
  String get anFactorPcaDesc;

  /// No description provided for @anFactorFull.
  ///
  /// In en, this message translates to:
  /// **'Factor analysis (full)'**
  String get anFactorFull;

  /// No description provided for @anFactorFullDesc.
  ///
  /// In en, this message translates to:
  /// **'varimax / KMO / Bartlett'**
  String get anFactorFullDesc;

  /// No description provided for @anLogistic.
  ///
  /// In en, this message translates to:
  /// **'Logistic regression'**
  String get anLogistic;

  /// No description provided for @anLogisticDesc.
  ///
  /// In en, this message translates to:
  /// **'Binary outcome prediction'**
  String get anLogisticDesc;

  /// No description provided for @anLogisticFull.
  ///
  /// In en, this message translates to:
  /// **'Logistic regression (full)'**
  String get anLogisticFull;

  /// No description provided for @anLogisticFullDesc.
  ///
  /// In en, this message translates to:
  /// **'Wald / OR CI / classification / H-L'**
  String get anLogisticFullDesc;

  /// No description provided for @anGlmTwo.
  ///
  /// In en, this message translates to:
  /// **'GLM two-way ANOVA'**
  String get anGlmTwo;

  /// No description provided for @anGlmTwoDesc.
  ///
  /// In en, this message translates to:
  /// **'A×B fixed effects'**
  String get anGlmTwoDesc;

  /// No description provided for @anStepwise.
  ///
  /// In en, this message translates to:
  /// **'Stepwise regression'**
  String get anStepwise;

  /// No description provided for @anStepwiseDesc.
  ///
  /// In en, this message translates to:
  /// **'Forward / backward selection'**
  String get anStepwiseDesc;

  /// No description provided for @anCtables.
  ///
  /// In en, this message translates to:
  /// **'CTABLES pivot table'**
  String get anCtables;

  /// No description provided for @anCtablesDesc.
  ///
  /// In en, this message translates to:
  /// **'Row/column summaries'**
  String get anCtablesDesc;

  /// No description provided for @anHistogram.
  ///
  /// In en, this message translates to:
  /// **'Histogram'**
  String get anHistogram;

  /// No description provided for @anHistogramDesc.
  ///
  /// In en, this message translates to:
  /// **'Distribution shape'**
  String get anHistogramDesc;

  /// No description provided for @anScatter.
  ///
  /// In en, this message translates to:
  /// **'Scatter plot'**
  String get anScatter;

  /// No description provided for @anScatterDesc.
  ///
  /// In en, this message translates to:
  /// **'Relationship between two variables'**
  String get anScatterDesc;

  /// No description provided for @anBar.
  ///
  /// In en, this message translates to:
  /// **'Bar chart'**
  String get anBar;

  /// No description provided for @anBarDesc.
  ///
  /// In en, this message translates to:
  /// **'Category frequencies'**
  String get anBarDesc;

  /// No description provided for @unsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get unsaved;

  /// No description provided for @chartSection.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get chartSection;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @trTitle.
  ///
  /// In en, this message translates to:
  /// **'Transform'**
  String get trTitle;

  /// No description provided for @trType.
  ///
  /// In en, this message translates to:
  /// **'Transform type'**
  String get trType;

  /// No description provided for @trOpCompute.
  ///
  /// In en, this message translates to:
  /// **'COMPUTE'**
  String get trOpCompute;

  /// No description provided for @trOpRecode.
  ///
  /// In en, this message translates to:
  /// **'RECODE'**
  String get trOpRecode;

  /// No description provided for @trOpCount.
  ///
  /// In en, this message translates to:
  /// **'COUNT'**
  String get trOpCount;

  /// No description provided for @trOpRank.
  ///
  /// In en, this message translates to:
  /// **'RANK'**
  String get trOpRank;

  /// No description provided for @trOpSort.
  ///
  /// In en, this message translates to:
  /// **'SORT'**
  String get trOpSort;

  /// No description provided for @trOpSelect.
  ///
  /// In en, this message translates to:
  /// **'SELECT IF'**
  String get trOpSelect;

  /// No description provided for @trOpAggregate.
  ///
  /// In en, this message translates to:
  /// **'AGGREGATE'**
  String get trOpAggregate;

  /// No description provided for @trOpFlip.
  ///
  /// In en, this message translates to:
  /// **'FLIP'**
  String get trOpFlip;

  /// No description provided for @trRun.
  ///
  /// In en, this message translates to:
  /// **'Run transform'**
  String get trRun;

  /// No description provided for @trTargetVar.
  ///
  /// In en, this message translates to:
  /// **'Target variable'**
  String get trTargetVar;

  /// No description provided for @trTargetName.
  ///
  /// In en, this message translates to:
  /// **'Target variable name'**
  String get trTargetName;

  /// No description provided for @trTargetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. total_score'**
  String get trTargetHint;

  /// No description provided for @trNewVar.
  ///
  /// In en, this message translates to:
  /// **'(new)'**
  String get trNewVar;

  /// No description provided for @trExpr.
  ///
  /// In en, this message translates to:
  /// **'Expression'**
  String get trExpr;

  /// No description provided for @trExprHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. pre + post, or sqrt(hours) * 2'**
  String get trExprHint;

  /// No description provided for @trComputeHelp.
  ///
  /// In en, this message translates to:
  /// **'Supports + - * / ( ) and abs sqrt ln exp log10 sin cos tan round trunc'**
  String get trComputeHelp;

  /// No description provided for @trSourceVar.
  ///
  /// In en, this message translates to:
  /// **'Source variable'**
  String get trSourceVar;

  /// No description provided for @trRecodeTargetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. method_label'**
  String get trRecodeTargetHint;

  /// No description provided for @trRules.
  ///
  /// In en, this message translates to:
  /// **'Rules (old=new, comma separated)'**
  String get trRules;

  /// No description provided for @trRulesHint.
  ///
  /// In en, this message translates to:
  /// **'1=lecture, 2=inquiry, 3=blended'**
  String get trRulesHint;

  /// No description provided for @trCountTargetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. n_pass'**
  String get trCountTargetHint;

  /// No description provided for @trCountVars.
  ///
  /// In en, this message translates to:
  /// **'Variables to count'**
  String get trCountVars;

  /// No description provided for @trMatchValue.
  ///
  /// In en, this message translates to:
  /// **'Match value'**
  String get trMatchValue;

  /// No description provided for @trRankDescending.
  ///
  /// In en, this message translates to:
  /// **'Rank descending'**
  String get trRankDescending;

  /// No description provided for @trSortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get trSortDescending;

  /// No description provided for @trSortKeys.
  ///
  /// In en, this message translates to:
  /// **'Sort keys (in order)'**
  String get trSortKeys;

  /// No description provided for @trCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition expression'**
  String get trCondition;

  /// No description provided for @trConditionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. post >= 70 && method == 2'**
  String get trConditionHint;

  /// No description provided for @trConditionHelp.
  ///
  /// In en, this message translates to:
  /// **'Supports > < >= <= == != with && ||'**
  String get trConditionHelp;

  /// No description provided for @trGroupVar.
  ///
  /// In en, this message translates to:
  /// **'Group variable'**
  String get trGroupVar;

  /// No description provided for @trAggVars.
  ///
  /// In en, this message translates to:
  /// **'Numeric variables to aggregate (mean)'**
  String get trAggVars;

  /// No description provided for @trFlipNote.
  ///
  /// In en, this message translates to:
  /// **'Swap rows and columns (transpose) to create a new dataset.'**
  String get trFlipNote;

  /// No description provided for @trCurrentData.
  ///
  /// In en, this message translates to:
  /// **'Current data'**
  String get trCurrentData;

  /// No description provided for @trDataset.
  ///
  /// In en, this message translates to:
  /// **'Dataset'**
  String get trDataset;

  /// No description provided for @trResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get trResult;

  /// No description provided for @trNeedTargetExpr.
  ///
  /// In en, this message translates to:
  /// **'Enter a target variable and an expression'**
  String get trNeedTargetExpr;

  /// No description provided for @trNeedSource.
  ///
  /// In en, this message translates to:
  /// **'Select a source variable'**
  String get trNeedSource;

  /// No description provided for @trNeedVars.
  ///
  /// In en, this message translates to:
  /// **'Select at least one variable'**
  String get trNeedVars;

  /// No description provided for @trNeedSortKeys.
  ///
  /// In en, this message translates to:
  /// **'Select sort keys'**
  String get trNeedSortKeys;

  /// No description provided for @trNeedCondition.
  ///
  /// In en, this message translates to:
  /// **'Enter a condition'**
  String get trNeedCondition;

  /// No description provided for @trNeedGroupAndVars.
  ///
  /// In en, this message translates to:
  /// **'Select a group variable and variables to aggregate'**
  String get trNeedGroupAndVars;

  /// No description provided for @trUnknownOp.
  ///
  /// In en, this message translates to:
  /// **'Unknown operation'**
  String get trUnknownOp;

  /// No description provided for @trError.
  ///
  /// In en, this message translates to:
  /// **'Error: {msg}'**
  String trError(String msg);

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @stCurrentDataset.
  ///
  /// In en, this message translates to:
  /// **'Current dataset'**
  String get stCurrentDataset;

  /// No description provided for @stStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage location'**
  String get stStorage;

  /// No description provided for @abInfoTab.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get abInfoTab;

  /// No description provided for @abReadmeZh.
  ///
  /// In en, this message translates to:
  /// **'中文 README'**
  String get abReadmeZh;

  /// No description provided for @abReadmeEn.
  ///
  /// In en, this message translates to:
  /// **'English README'**
  String get abReadmeEn;

  /// No description provided for @abReadmeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load README: {msg}'**
  String abReadmeFailed(String msg);

  /// No description provided for @abIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get abIntroTitle;

  /// No description provided for @abIntroBody.
  ///
  /// In en, this message translates to:
  /// **'A project-based statistical analysis suite covering data editing, statistical procedures, data transformation, learning and testing. The statistics kernel is the standalone pure-Dart package statkit.'**
  String get abIntroBody;

  /// No description provided for @abDocs.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get abDocs;

  /// No description provided for @abLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get abLicense;

  /// No description provided for @abLicenseValue.
  ///
  /// In en, this message translates to:
  /// **'AGPL-3.0 · open source'**
  String get abLicenseValue;

  /// No description provided for @abStack.
  ///
  /// In en, this message translates to:
  /// **'Tech stack'**
  String get abStack;

  /// No description provided for @abStackValue.
  ///
  /// In en, this message translates to:
  /// **'Flutter · Dart'**
  String get abStackValue;

  /// No description provided for @abRuntime.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get abRuntime;

  /// No description provided for @abPlatform.
  ///
  /// In en, this message translates to:
  /// **'Flutter app · Windows / macOS / Linux / Android / iOS'**
  String get abPlatform;

  /// No description provided for @abKernel.
  ///
  /// In en, this message translates to:
  /// **'Statistics kernel: packages/statkit (pure Dart, 13 test groups)'**
  String get abKernel;

  /// No description provided for @abUiLang.
  ///
  /// In en, this message translates to:
  /// **'UI language: 中文 / English (switch in Settings)'**
  String get abUiLang;

  /// No description provided for @abTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme: light / dark / system · 8 seed colors'**
  String get abTheme;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noVariablesMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching variables'**
  String get noVariablesMatch;

  /// No description provided for @learnIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Master descriptive statistics, hypothesis testing, regression, non-parametric methods and reliability through short lessons. Each lesson has key points and core formulas; finish it and head to the Quiz to practise.'**
  String get learnIntroBody;

  /// No description provided for @keyFormulas.
  ///
  /// In en, this message translates to:
  /// **'Core formulas'**
  String get keyFormulas;

  /// No description provided for @quizSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Random questions · instant scoring'**
  String get quizSetupTitle;

  /// No description provided for @quizSetupBody.
  ///
  /// In en, this message translates to:
  /// **'The bank holds {n} questions covering descriptive statistics, t-tests, ANOVA, correlation, regression, chi-square, non-parametric tests and reliability. Submit to see explanations and your mistakes.'**
  String quizSetupBody(int n);

  /// No description provided for @quizCount.
  ///
  /// In en, this message translates to:
  /// **'Number of questions'**
  String get quizCount;

  /// No description provided for @quizNQuestions.
  ///
  /// In en, this message translates to:
  /// **'{n} questions'**
  String quizNQuestions(int n);

  /// No description provided for @quizStart.
  ///
  /// In en, this message translates to:
  /// **'Start quiz'**
  String get quizStart;

  /// No description provided for @quizProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {a} of {b}'**
  String quizProgress(int a, int b);

  /// No description provided for @quizScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Your score'**
  String get quizScoreLabel;

  /// No description provided for @quizFeedbackHigh.
  ///
  /// In en, this message translates to:
  /// **'Excellent! Try a bigger set, or practise the same methods in Data analysis.'**
  String get quizFeedbackHigh;

  /// No description provided for @quizFeedbackMid.
  ///
  /// In en, this message translates to:
  /// **'Not bad — review the explanations for the questions you missed.'**
  String get quizFeedbackMid;

  /// No description provided for @quizFeedbackLow.
  ///
  /// In en, this message translates to:
  /// **'Go through the Learn module to consolidate the concepts, then try again.'**
  String get quizFeedbackLow;

  /// No description provided for @quizTryAgain.
  ///
  /// In en, this message translates to:
  /// **'New set'**
  String get quizTryAgain;

  /// No description provided for @quizBackToSetup.
  ///
  /// In en, this message translates to:
  /// **'Back to setup'**
  String get quizBackToSetup;

  /// No description provided for @quizReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get quizReview;

  /// No description provided for @quizUnanswered.
  ///
  /// In en, this message translates to:
  /// **'You have {n} unanswered question(s). Submit anyway?'**
  String quizUnanswered(int n);

  /// No description provided for @quizItemTopic.
  ///
  /// In en, this message translates to:
  /// **'Q{i} · {topic}'**
  String quizItemTopic(int i, String topic);

  /// No description provided for @quizCorrect.
  ///
  /// In en, this message translates to:
  /// **'correct'**
  String get quizCorrect;

  /// No description provided for @quizYourChoice.
  ///
  /// In en, this message translates to:
  /// **'your choice'**
  String get quizYourChoice;

  /// No description provided for @quizExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation: {text}'**
  String quizExplanation(String text);

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get removeFavorite;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSelection;

  /// No description provided for @searchVariables.
  ///
  /// In en, this message translates to:
  /// **'Search variables…'**
  String get searchVariables;

  /// No description provided for @significanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Significance {stars}'**
  String significanceLabel(String stars);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @mvTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing values · {name}'**
  String mvTitle(String name);

  /// No description provided for @mvDiscrete.
  ///
  /// In en, this message translates to:
  /// **'Discrete missing values (comma separated)'**
  String get mvDiscrete;

  /// No description provided for @mvDiscreteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. -99, -98'**
  String get mvDiscreteHint;

  /// No description provided for @mvRangeLow.
  ///
  /// In en, this message translates to:
  /// **'Range lower bound (optional)'**
  String get mvRangeLow;

  /// No description provided for @mvRangeHigh.
  ///
  /// In en, this message translates to:
  /// **'Range upper bound (optional)'**
  String get mvRangeHigh;

  /// No description provided for @mvNote.
  ///
  /// In en, this message translates to:
  /// **'Blank cells always count as missing. A range and discrete values can be used together.'**
  String get mvNote;

  /// No description provided for @vlTitle.
  ///
  /// In en, this message translates to:
  /// **'Value labels · {name}'**
  String vlTitle(String name);

  /// No description provided for @vlCount.
  ///
  /// In en, this message translates to:
  /// **'{n} label(s)'**
  String vlCount(int n);

  /// No description provided for @vlClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get vlClearAll;

  /// No description provided for @vlEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No value labels yet — add one above.'**
  String get vlEmptyHint;

  /// No description provided for @savImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {cases} cases × {vars} variables ({product})'**
  String savImported(int cases, int vars, String product);

  /// No description provided for @savImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import .sav: {msg}'**
  String savImportFailed(String msg);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
