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
  /// **'A mobile-first statistical analysis suite inspired by GNU PSPP, with learning and testing modules.'**
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
  /// **'Master hypothesis tests, regression, nonparametrics and reliability through short lessons aligned with PSPP procedures. Then practice in Quiz.'**
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
