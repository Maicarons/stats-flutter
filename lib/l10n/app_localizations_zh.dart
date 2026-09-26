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
  String get aboutDesc => '灵感来自 GNU PSPP 的移动优先统计分析套件，内置学习与测试模块。';

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
  String get learnIntro => '对照 PSPP 统计过程，用短课掌握假设检验、回归、非参数与信度。学完可直接去「测试」练手。';

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
  String get doubleClickEdit => '双击单元格即可编辑';

  @override
  String get cellEditHint => 'Enter 确认 · Tab 下一格 · Esc 取消';

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
}
