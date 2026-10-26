/// 语法子集执行器：解析并运行常用命令
library;


import '../io/missing_aware.dart';
import '../models/dataset.dart';
import '../models/mrset.dart';
import '../transforms/combine_files.dart';
import '../transforms/transforms.dart';
import 'package:statkit/statkit.dart';
import 'syntax_macro.dart';
import 'syntax_preprocess.dart';

/// `INCLUDE` 的文件读取回调：给出脚本里写的文件名，返回文件内容；
/// 读取失败返回 `null`。相对路径以调用方决定的基准目录为准。
typedef SyntaxIncludeResolver = String? Function(String path);

/// `SAVE OUTFILE` 的写出回调：把活动数据集写成文件；返回是否成功。
typedef SyntaxSaver = bool Function(String path, Dataset ds);

class SyntaxCommand {
  final String verb;
  final List<String> args;
  final String raw;

  /// 命令在**原始源文本**里的起止偏移（注释剥离与宏展开后仍指回原位置）。
  final int start;
  final int end;

  SyntaxCommand(this.verb, this.args, this.raw, {this.start = 0, this.end = 0});
}

class SyntaxResult {
  final String command;
  final String output;
  final bool ok;

  /// 定位信息（1-based）；预处理期的问题同样带位置。
  final int? line;
  final int? column;

  /// 原始源文本里的偏移区间，供语法编辑器点击跳转。
  final int? start;
  final int? end;

  /// `INCLUDE` 引入的文件路径（主脚本为 `null`）。
  final String? file;

  /// 提示（非错误）：例如注释未以句点结束。
  final bool hint;

  const SyntaxResult({
    required this.command,
    required this.output,
    required this.ok,
    this.line,
    this.column,
    this.start,
    this.end,
    this.file,
    this.hint = false,
  });

  /// 补上位置信息（执行结果本身不带位置，由执行器统一附加）。
  SyntaxResult at({
    int? line,
    int? column,
    int? start,
    int? end,
    String? file,
    bool? hint,
  }) =>
      SyntaxResult(
        command: command,
        output: output,
        ok: ok,
        line: line ?? this.line,
        column: column ?? this.column,
        start: start ?? this.start,
        end: end ?? this.end,
        file: file ?? this.file,
        hint: hint ?? this.hint,
      );
}

/// 语法执行器的界面文案（中/英）。命令关键字与数值输出保持语言中立，
/// 仅提示与帮助文本随界面语言变化。
class SyntaxMessages {
  final String Function(String verb) unsupportedCommand;
  final String Function(String e) error;
  final String helpText;
  final String computeSyntax;
  final String recodeSyntax;
  final String corrNeedsTwo;
  final String rankSyntax;
  final String autorecodeSyntax;
  final String sampleSyntax;
  final String mrsetsSyntax;
  final String combineSyntax;

  /// 源变量数与目标变量数不一致
  final String Function(int, int) autorecodeCountMismatch;

  /// 宏未定义
  final String Function(String) macroUndefined;

  /// 明确未支持的宏构造（本版不做）
  final String Function(String) macroUnsupported;

  /// `!LET` / `!IF` / `!DO` / 宏函数出现在宏体之外
  final String Function(String) macroOutsideBody;

  /// `DEFINE` 本身写错
  final String Function(String) macroBadDefinition;

  /// 宏递归过深
  final String macroRecursion;

  /// `*` / `COMMENT` 注释吞掉了后续行（提示，非错误；参数是被吞掉的行文本）
  final String Function(String) commentSwallowed;

  /// `INCLUDE` 用法提示
  final String includeSyntax;

  /// 当前环境没有提供文件读取器
  final String includeUnavailable;

  /// 无法读取被包含的文件
  final String Function(String) includeNotFound;

  /// 循环包含
  final String Function(String) includeCycle;

  /// 包含层级过深
  final String includeTooDeep;

  /// 成功包含：`path` 与其中执行的命令数
  final String Function(String, int) includeSummary;

  /// `SAVE` 用法提示
  final String saveSyntax;

  /// 当前环境没有提供文件写出器
  final String saveUnavailable;

  /// 写出失败
  final String saveFailed;

  /// 成功写出：路径、个案数、变量数
  final String Function(String, int, int) saveSuccess;

  /// `SPLIT FILE` 用法提示
  final String splitSyntax;

  /// 拆分变量不存在
  final String Function(String) splitUnknownVar;

  const SyntaxMessages({
    required this.unsupportedCommand,
    required this.error,
    required this.helpText,
    required this.computeSyntax,
    required this.recodeSyntax,
    required this.corrNeedsTwo,
    required this.rankSyntax,
    required this.autorecodeSyntax,
    required this.sampleSyntax,
    required this.mrsetsSyntax,
    required this.combineSyntax,
    required this.autorecodeCountMismatch,
    required this.macroUndefined,
    required this.macroUnsupported,
    required this.macroOutsideBody,
    required this.macroBadDefinition,
    required this.macroRecursion,
    required this.commentSwallowed,
    required this.includeSyntax,
    required this.includeUnavailable,
    required this.includeNotFound,
    required this.includeCycle,
    required this.includeTooDeep,
    required this.includeSummary,
    required this.saveSyntax,
    required this.saveUnavailable,
    required this.saveFailed,
    required this.saveSuccess,
    required this.splitSyntax,
    required this.splitUnknownVar,
  });

  static const zh = SyntaxMessages(
    unsupportedCommand: _zhUnsupported,
    error: _zhError,
    helpText: _zhHelp,
    computeSyntax: 'COMPUTE 语法: COMPUTE target = expression.',
    recodeSyntax: 'RECODE 语法: RECODE v (old=new) INTO t.',
    corrNeedsTwo: 'CORRELATIONS 需要至少 2 个变量',
    rankSyntax: 'RANK 语法: RANK VARIABLES=v (A|D) /RANK|/N|/PERCENT|/NORMAL|'
        '/PROPORTION|/RFRACTION|/NTILES(k) /TIES=MEAN|LOW|HIGH|CONDENSE',
    autorecodeSyntax: 'AUTORECODE 语法: AUTORECODE VARIABLES=a b [/INTO=an bn]'
        ' [/DESCENDING] [/GROUP] [/BLANK=VALID|MISSING]',
    sampleSyntax: 'SAMPLE 语法: SAMPLE p 或 SAMPLE n FROM N [/SEED=123]',
    mrsetsSyntax: 'MRSETS 语法: MRSETS /MDGROUP NAME=\$m VARIABLES=a b VALUE=1 '
        '[/MCGROUP NAME=\$c VARIABLES=x y] [/DELETE NAME=\$m|ALL] '
        '[/DISPLAY NAME=\$m|ALL] [/FREQUENCIES NAME=\$m] '
        '[/CROSSTABS NAME=\$m BY=变量]',
    combineSyntax: 'COMBINE FILES 语法: ADD FILES /FILE=* /FILE=文件名 '
        '[/RENAME=(旧=新)] [/IN=指示变量] [/BY 变量] [/KEEP=变量] [/DROP=变量]；'
        'MATCH FILES /FILE=* /TABLE=文件名 /BY 变量（文件名需先在语法编辑器里附加）',
    autorecodeCountMismatch: _zhArcCountMismatch,
    macroUndefined: _zhMacroUndefined,
    macroUnsupported: _zhMacroUnsupported,
    macroOutsideBody: _zhMacroOutsideBody,
    macroBadDefinition: _zhMacroBadDefinition,
    macroRecursion: '宏展开递归过深（可能是宏调用自身）',
    commentSwallowed: _zhCommentSwallowed,
    includeSyntax: 'INCLUDE 语法: INCLUDE [FILE=]\'文件名\' [ENCODING=\'编码\']',
    includeUnavailable: 'INCLUDE 需要调用方提供文件读取器（当前环境未提供）',
    includeNotFound: _zhIncludeNotFound,
    includeCycle: _zhIncludeCycle,
    includeTooDeep: 'INCLUDE 嵌套层数过深（上限 16 层）',
    includeSummary: _zhIncludeSummary,
    saveSyntax: "SAVE 语法: SAVE OUTFILE='文件名.sav' [FILELABEL='标签']",
    saveUnavailable: 'SAVE 需要调用方提供文件写出器（当前环境未提供）',
    saveFailed: '写出失败: 路径不可写或被占用',
    saveSuccess: _zhSaveSuccess,
    splitSyntax: 'SPLIT FILE 语法: SPLIT FILE BY 变量1 变量2 … 或 SPLIT FILE OFF',
    splitUnknownVar: _zhSplitUnknown,
  );

  static const en = SyntaxMessages(
    unsupportedCommand: _enUnsupported,
    error: _enError,
    helpText: _enHelp,
    computeSyntax: 'COMPUTE syntax: COMPUTE target = expression.',
    recodeSyntax: 'RECODE syntax: RECODE v (old=new) INTO t.',
    corrNeedsTwo: 'CORRELATIONS needs at least 2 variables',
    rankSyntax: 'RANK syntax: RANK VARIABLES=v (A|D) /RANK|/N|/PERCENT|/NORMAL|'
        '/PROPORTION|/RFRACTION|/NTILES(k) /TIES=MEAN|LOW|HIGH|CONDENSE',
    autorecodeSyntax: 'AUTORECODE syntax: AUTORECODE VARIABLES=a b [/INTO=an bn]'
        ' [/DESCENDING] [/GROUP] [/BLANK=VALID|MISSING]',
    sampleSyntax: 'SAMPLE syntax: SAMPLE p or SAMPLE n FROM N [/SEED=123]',
    mrsetsSyntax: 'MRSETS syntax: MRSETS /MDGROUP NAME=\$m VARIABLES=a b VALUE=1 '
        '[/MCGROUP NAME=\$c VARIABLES=x y] [/DELETE NAME=\$m|ALL] '
        '[/DISPLAY NAME=\$m|ALL] [/FREQUENCIES NAME=\$m] '
        '[/CROSSTABS NAME=\$m BY=var]',
    combineSyntax: 'COMBINE FILES syntax: ADD FILES /FILE=* /FILE=name '
        '[/RENAME=(old=new)] [/IN=indicator] [/BY vars] [/KEEP=vars] [/DROP=vars]; '
        'MATCH FILES /FILE=* /TABLE=name /BY vars (attach the file in the syntax editor first)',
    autorecodeCountMismatch: _enArcCountMismatch,
    macroUndefined: _enMacroUndefined,
    macroUnsupported: _enMacroUnsupported,
    macroOutsideBody: _enMacroOutsideBody,
    macroBadDefinition: _enMacroBadDefinition,
    macroRecursion: 'Macro expansion is too deeply nested (self-recursive call?)',
    commentSwallowed: _enCommentSwallowed,
    includeSyntax: 'INCLUDE syntax: INCLUDE [FILE=\'name\'] [ENCODING=\'enc\']',
    includeUnavailable:
        'INCLUDE needs a file reader supplied by the caller (none in this environment)',
    includeNotFound: _enIncludeNotFound,
    includeCycle: _enIncludeCycle,
    includeTooDeep: 'INCLUDE nesting is too deep (limit 16 levels)',
    includeSummary: _enIncludeSummary,
    saveSyntax: "SAVE syntax: SAVE OUTFILE='file.sav' [FILELABEL='label']",
    saveUnavailable:
        'SAVE needs a file writer supplied by the caller (none in this environment)',
    saveFailed: 'Write failed: path is not writable',
    saveSuccess: _enSaveSuccess,
    splitSyntax: 'SPLIT FILE syntax: SPLIT FILE BY var1 var2 … or SPLIT FILE OFF',
    splitUnknownVar: _enSplitUnknown,
  );
}

String _zhUnsupported(String verb) => '尚未支持的命令: $verb\n输入 HELP 查看支持列表';
String _enUnsupported(String verb) =>
    'Unsupported command: $verb\nType HELP for the supported list';
String _zhError(String e) => '错误: $e';
String _enError(String e) => 'Error: $e';
String _zhSaveSuccess(String path, int cases, int vars) =>
    '已写出 .sav 文件: $path（$cases 个个案 × $vars 个变量，未压缩）';
String _enSaveSuccess(String path, int cases, int vars) =>
    'Wrote .sav file: $path ($cases cases × $vars variables, uncompressed)';
String _zhSplitUnknown(String name) => 'SPLIT FILE: 变量不存在: $name';
String _enSplitUnknown(String name) => 'SPLIT FILE: unknown variable: $name';
String _zhArcCountMismatch(int a, int b) => '源变量数（$a）与目标变量数（$b）不一致';
String _enArcCountMismatch(int a, int b) =>
    'Source variable count ($a) does not match target variable count ($b)';

String _zhMacroUndefined(String name) => '未定义的宏: !$name';
String _enMacroUndefined(String name) => 'Undefined macro: !$name';
String _zhMacroUnsupported(String name) =>
    '本版未支持的宏构造: !$name（!ENCLOSE、!DO … !IN、!OFFEXPAND/!ONEXPAND/!NOEXPAND 等暂不支持）';
String _enMacroUnsupported(String name) =>
    'Unsupported macro construct: !$name (!ENCLOSE, !DO … !IN, '
    '!OFFEXPAND/!ONEXPAND/!NOEXPAND are not supported yet)';
String _zhMacroOutsideBody(String name) => '宏构造 !$name 只能出现在宏体内';
String _enMacroOutsideBody(String name) =>
    'Macro construct !$name is only valid inside a macro body';
String _zhMacroBadDefinition(String name) =>
    'DEFINE 定义有误: ${name.isEmpty ? '(缺少宏名)' : '!$name'}';
String _enMacroBadDefinition(String name) =>
    'Malformed DEFINE: ${name.isEmpty ? '(missing macro name)' : '!$name'}';
String _zhIncludeNotFound(String path) => '无法读取被包含的文件: $path';
String _enIncludeNotFound(String path) => 'Cannot read included file: $path';
String _zhIncludeCycle(String path) => '循环包含: $path';
String _enIncludeCycle(String path) => 'Circular INCLUDE: $path';
String _zhIncludeSummary(String path, int count) =>
    'INCLUDE $path  （执行 $count 条命令）';
String _enIncludeSummary(String path, int count) =>
    'INCLUDE $path  ($count commands)';
String _zhCommentSwallowed(String detail) => detail.isEmpty
    ? '提示：`*` / COMMENT 注释一直到文件末尾都没有行尾句点，'
        '其后内容都被当作注释文本了'
    : '提示：`*` / COMMENT 注释按 PSPP 规则持续到「行尾句点」，'
        '已吞掉后续行「$detail」；只想注释一行时请在注释文字末尾加 `.`';
String _enCommentSwallowed(String detail) => detail.isEmpty
    ? 'Hint: this `*` / COMMENT comment never reached a dot at end of line, '
        'so the rest of the file was treated as comment text'
    : 'Hint: this `*` / COMMENT comment runs to a dot at the end of a line '
        '(PSPP rule) and swallowed the following line "$detail"; add `.` at the '
        'end of the comment text to end it after one line';

/// 语法执行器**已实现**的命令动词（与 `_execute` 的分支一一对应）。
///
/// 高亮表与帮助文档都从这里取，避免与实现漂移；`commandVerbs` 是它的超集。
const implementedVerbs = <String>{
  'ADD', 'AUTORECODE', 'COMPUTE', 'CORR', 'CORRELATIONS', 'DESCRIPTIVE',
  'DESCRIPTIVES', 'DISPLAY', 'FREQUENCIES', 'HELP', 'INCLUDE', 'LIST', 'MATCH',
  'MRSETS', 'RANK', 'RECODE', 'SAMPLE', 'SELECT', 'SHOW', 'SORT', 'SPLIT',
  'T-TEST', 'TTEST', 'SAVE',
};

/// 命令动词表：用于识别「注释吞掉了后续命令」这类误用（提示用）。
///
/// 比 [implementedVerbs] 多——被注释吞掉的也可能是本版尚未实现的 SPSS 命令，
/// 这时给出提示同样有用。
const commandVerbs = <String>{
  'ADD', 'MATCH', 'COMPUTE', 'RECODE', 'RANK', 'AUTORECODE', 'SAMPLE', 'MRSETS',
  'SORT', 'SELECT', 'DESCRIPTIVES', 'DESCRIPTIVE', 'FREQUENCIES', 'T-TEST',
  'TTEST', 'CORRELATIONS', 'CORR', 'LIST', 'DISPLAY', 'SHOW', 'HELP', 'INCLUDE',
  'DEFINE', 'CTABLES', 'FACTOR', 'REGRESSION', 'MEANS', 'ONEWAY', 'UNIANOVA',
  'GLM', 'LOGISTIC', 'NONPAR', 'EXAMINE', 'PROCESS', 'TABLES', 'VALUE',
  'MISSING', 'WEIGHT', 'SPLIT', 'USE', 'DATASET', 'SAVE', 'GET', 'OUTPUT',
};

const _zhHelp = '''
支持的命令（子集）:
  COMPUTE newvar = expression.
  RECODE var (old=new) ...
  AUTORECODE VARIABLES=a b [/INTO=an bn] [/DESCENDING] [/GROUP].
  SAMPLE p  或  SAMPLE n FROM N  [/SEED=123].
  MRSETS /MDGROUP NAME=\$m VARIABLES=a b VALUE=1.
         /DISPLAY NAME=ALL   /FREQUENCIES NAME=\$m   /CROSSTABS NAME=\$m BY=g.
  ADD FILES /FILE=* /FILE=其它文件 [/IN=来源] [/BY 变量].
  MATCH FILES /FILE=* /TABLE=查表文件 /BY 键变量.
  RANK VARIABLES=v (A|D) /RANK|/N|/PERCENT|/NORMAL|/NTILES(4) /TIES=MEAN.
  SORT CASES BY var1 var2.
  SELECT IF condition.
  DESCRIPTIVES var1 var2.
  FREQUENCIES var.
  T-TEST /TESTVAL=0 /VARIABLES=var.
  CORRELATIONS /VARIABLES=v1 v2.
  LIST.
  DISPLAY 或 SHOW.
  INCLUDE '文件名.sps'.
  DEFINE !名字(!参数 !TOKENS(1)) … !ENDDEFINE.    !名字(取值).
  SAVE OUTFILE='文件名.sav' [FILELABEL='标签'].
  SPLIT FILE BY 变量 …  /  SPLIT FILE OFF.
  HELP.
注释: `* 文字.` 与 `COMMENT 文字.` 到行尾句点或空行结束；行内用 /* 注释 */。
宏支持 !LET、!IF/!THEN/!ELSE/!ENDIF、!DO … !TO !BY … !DOEND。
表达式支持 + - * / ( ) 与 abs sqrt ln exp log10 sin cos tan round trunc''';

const _enHelp = '''
Supported commands (subset):
  COMPUTE newvar = expression.
  RECODE var (old=new) ...
  AUTORECODE VARIABLES=a b [/INTO=an bn] [/DESCENDING] [/GROUP].
  SAMPLE p  or  SAMPLE n FROM N  [/SEED=123].
  MRSETS /MDGROUP NAME=\$m VARIABLES=a b VALUE=1.
         /DISPLAY NAME=ALL   /FREQUENCIES NAME=\$m   /CROSSTABS NAME=\$m BY=g.
  ADD FILES /FILE=* /FILE=name [/IN=source] [/BY vars].
  MATCH FILES /FILE=* /TABLE=name /BY key_vars.
  RANK VARIABLES=v (A|D) /RANK|/N|/PERCENT|/NORMAL|/NTILES(4) /TIES=MEAN.
  SORT CASES BY var1 var2.
  SELECT IF condition.
  DESCRIPTIVES var1 var2.
  FREQUENCIES var.
  T-TEST /TESTVAL=0 /VARIABLES=var.
  CORRELATIONS /VARIABLES=v1 v2.
  LIST.
  DISPLAY or SHOW.
  INCLUDE 'file.sps'.
  DEFINE !name(!arg !TOKENS(1)) … !ENDDEFINE.    !name(value).
  SAVE OUTFILE='file.sav' [FILELABEL='label'].
  SPLIT FILE BY vars …  /  SPLIT FILE OFF.
  HELP.
Comments: `* text.` and `COMMENT text.` end at a dot at end of line or a blank
  line; inline comments use /* … */.
Macros support !LET, !IF/!THEN/!ELSE/!ENDIF and !DO … !TO !BY … !DOEND.
Expressions support + - * / ( ) and abs sqrt ln exp log10 sin cos tan round trunc''';

/// 一条命令在**预处理后文本**里的位置（偏移以干净文本计）。
class SyntaxCommandSpan {
  const SyntaxCommandSpan(this.text, this.start, this.end);

  final String text;
  final int start;
  final int end;
}

class SyntaxParser {
  /// 按句点切分命令（字符串内句点与数字小数点不算终止符），
  /// 同时给出每条命令在干净文本里的偏移区间。
  static List<SyntaxCommandSpan> splitCommandSpans(String source) {
    final out = <SyntaxCommandSpan>[];
    final buf = StringBuffer();
    var bufStart = 0;
    var inStr = false;
    var quote = '';
    for (var i = 0; i < source.length; i++) {
      final ch = source[i];
      final decimal = ch == '.' &&
          i > 0 &&
          i + 1 < source.length &&
          _digit(source[i - 1]) &&
          _digit(source[i + 1]);
      if (ch == '.' && !inStr && !decimal) {
        _emit(out, buf, bufStart);
        buf.clear();
        bufStart = i + 1;
        continue;
      }
      if (!inStr && (ch == '"' || ch == "'")) {
        inStr = true;
        quote = ch;
      } else if (inStr && ch == quote) {
        inStr = false;
      }
      if (buf.isEmpty) bufStart = i;
      buf.write(ch);
    }
    _emit(out, buf, bufStart);
    return out;
  }

  static List<String> splitCommands(String source) =>
      [for (final span in splitCommandSpans(source)) span.text];

  static void _emit(
      List<SyntaxCommandSpan> out, StringBuffer buf, int bufStart) {
    if (buf.isEmpty) return;
    final raw = buf.toString();
    final text = raw.trim();
    if (text.isEmpty) return;
    final left = raw.length - raw.trimLeft().length;
    final start = bufStart + left;
    out.add(SyntaxCommandSpan(text, start, start + text.length));
  }

  static bool _digit(String c) {
    final u = c.codeUnitAt(0) - 48;
    return u >= 0 && u <= 9;
  }

  /// [start]/[end] 是命令在原始源文本里的偏移（由调用方从预处理映射得到）。
  static SyntaxCommand? parse(String cmd, {int start = 0, int end = 0}) {
    final body = cmd.trim();
    if (body.isEmpty) return null;
    final first = RegExp(r'^\S+').firstMatch(body);
    if (first == null) return null;
    final verb = first.group(0)!.toUpperCase();
    // 预处理已剥离注释；直接调用 [parse] 时仍把行首 `*` 当注释丢弃
    if (verb.startsWith('*')) return null;
    // 只有动词、没有参数时（如 `LIST`）不允许 substring(-1)
    final ws = body.indexOf(RegExp(r'\s+'));
    final rest = ws < 0 ? '' : body.substring(ws).trim();
    final args = _splitArgs(rest);
    return SyntaxCommand(
      verb,
      args,
      body,
      start: start,
      end: end == 0 ? start + body.length : end,
    );
  }

  static List<String> _splitArgs(String s) {
    // 按 / 与 逗号粗分，保留整体 token
    final out = <String>[];
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == ',') {
        final t = buf.toString().trim();
        if (t.isNotEmpty) out.add(t);
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    final last = buf.toString().trim();
    if (last.isNotEmpty) out.add(last);
    return out;
  }
}

/// 一次执行（含 `INCLUDE` 嵌套）的共享上下文：宏表与包含栈在其中延续。
class _RunContext {
  _RunContext({
    required this.messages,
    required this.files,
    required this.macros,
    required this.include,
    required this.saver,
  });

  final SyntaxMessages messages;
  final Map<String, Dataset> files;
  final MacroTable macros;
  final SyntaxIncludeResolver? include;
  final SyntaxSaver? saver;
  final Set<String> includeStack = {};
  int includeDepth = 0;
}

/// 结果 + 它在原始源文本里的偏移 + 稳定排序用的序号。
class _Entry {
  _Entry(this.offset, this.seq, this.result);

  final int offset;
  final int seq;
  final SyntaxResult result;
}

class SyntaxExecutor {
  /// 执行脚本。
  ///
  /// [macros] 可在多次调用之间复用（宏定义跨次运行保留，与 PSPP 会话一致）；
  /// [include] 提供 `INCLUDE` 的文件读取能力，缺省时 `INCLUDE` 明确报错。
  static List<SyntaxResult> run(
    String source,
    Dataset ds, {
    SyntaxMessages messages = SyntaxMessages.zh,
    Map<String, Dataset> files = const {},
    MacroTable? macros,
    SyntaxIncludeResolver? include,
    SyntaxSaver? saver,
  }) {
    final ctx = _RunContext(
      messages: messages,
      files: files,
      macros: macros ?? MacroTable(),
      include: include,
      saver: saver,
    );
    return _runSource(source, ds, ctx, null);
  }

  /// 执行一段脚本：注释剥离 → 宏展开 → 逐条命令执行，结果带回原始位置。
  ///
  /// `INCLUDE` 之后会**重新预处理**余下部分：这样被包含文件里 `DEFINE` 的宏
  /// 立刻对后面的命令生效（与 PSPP 的解析顺序一致）。
  static List<SyntaxResult> _runSource(
      String source, Dataset ds, _RunContext ctx, String? file) {
    final entries = <_Entry>[];
    var seq = 0;
    var consumed = 0;

    while (true) {
      final pre = SyntaxPreprocessor.process(
        source.substring(consumed),
        macros: ctx.macros,
        commandVerbs: commandVerbs,
        offsetShift: consumed,
        fullSource: source,
      );

      for (final issue in pre.issues) {
        final (line, column) = pre.lineColumn(issue.offset);
        entries.add(_Entry(
          issue.offset,
          seq++,
          _issueResult(issue, ctx.messages, pre, line, column, file),
        ));
      }

      var restart = false;
      var stop = false;
      for (final span in SyntaxParser.splitCommandSpans(pre.text)) {
        final (start, end) = pre.toSourceRange(span.start, span.end);
        final cmd = SyntaxParser.parse(span.text, start: start, end: end);
        if (cmd == null) continue;
        final (line, column) = pre.lineColumn(start);

        if (cmd.verb == 'INCLUDE') {
          final (marker, nested) = _include(cmd, ds, ctx, line, column, file);
          entries.add(_Entry(start, seq++, marker));
          for (final r in nested) {
            entries.add(_Entry(start, seq++, r));
          }
          if (!marker.ok) {
            stop = true; // 被包含文件出错 → 停止后续命令（PSPP）
            break;
          }
          consumed = end;
          restart = true;
          // 被包含文件之前的这次预处理看不到它的宏定义，余下部分的
          // 问题（如「未定义的宏」）丢弃，下一轮重新预处理后再报。
          entries.removeWhere((e) => e.offset >= end);
          break;
        }

        final r = _execute(cmd, ds, ctx.messages, ctx.files, saver: ctx.saver);
        entries.add(_Entry(
          start,
          seq++,
          r.at(line: line, column: column, start: start, end: end, file: file),
        ));
        // 被包含文件内出错 → 停止该文件后续命令（PSPP），主脚本保持宽松
        if (!r.ok && file != null) {
          stop = true;
          break;
        }
      }

      if (stop || !restart) break;
    }

    entries.sort((a, b) {
      final c = a.offset.compareTo(b.offset);
      return c != 0 ? c : a.seq.compareTo(b.seq);
    });
    return [for (final e in entries) e.result];
  }

  /// 预处理期问题（宏未定义、注释未结束等）转成结果。
  static SyntaxResult _issueResult(MacroIssue issue, SyntaxMessages messages,
      SyntaxSource pre, int line, int column, String? file) {
    var ok = false;
    var hint = false;
    final String output;
    switch (issue.kind) {
      case MacroIssueKind.undefined:
        output = messages.macroUndefined(issue.name);
      case MacroIssueKind.unsupported:
        output = messages.macroUnsupported(issue.name);
      case MacroIssueKind.constructOutsideBody:
        output = messages.macroOutsideBody(issue.name);
      case MacroIssueKind.badDefinition:
        output = messages.macroBadDefinition(issue.name);
      case MacroIssueKind.recursion:
        output = messages.macroRecursion;
      case MacroIssueKind.unterminatedComment:
      case MacroIssueKind.swallowedCommand:
        output = messages.commentSwallowed(issue.name);
        ok = true;
        hint = true;
    }
    final text = pre.lineText(line);
    return SyntaxResult(
      command: text.trim(),
      ok: ok,
      output: output,
      line: line,
      column: column,
      start: pre.lineStartOffset(line),
      end: pre.lineStartOffset(line) + text.length,
      file: file,
      hint: hint,
    );
  }

  /// `INCLUDE`：读取被包含文件并递归执行，返回（INCLUDE 结果, 嵌套结果）。
  static (SyntaxResult, List<SyntaxResult>) _include(SyntaxCommand cmd,
      Dataset ds, _RunContext ctx, int line, int column, String? fromFile) {
    SyntaxResult fail(String msg) => SyntaxResult(
          command: cmd.raw,
          ok: false,
          output: msg,
          line: line,
          column: column,
          start: cmd.start,
          end: cmd.end,
          file: fromFile,
        );

    final path = _includePath(cmd);
    if (path == null) return (fail(ctx.messages.includeSyntax), const []);
    if (ctx.include == null) {
      return (fail(ctx.messages.includeUnavailable), const []);
    }
    final key = path.toLowerCase();
    if (ctx.includeStack.contains(key)) {
      return (fail(ctx.messages.includeCycle(path)), const []);
    }
    if (ctx.includeDepth >= 16) {
      return (fail(ctx.messages.includeTooDeep), const []);
    }
    final text = ctx.include!(path);
    if (text == null) {
      return (fail(ctx.messages.includeNotFound(path)), const []);
    }
    ctx.includeStack.add(key);
    ctx.includeDepth++;
    final nested = _runSource(text, ds, ctx, path);
    ctx.includeDepth--;
    ctx.includeStack.remove(key);
    final marker = SyntaxResult(
      command: cmd.raw,
      ok: nested.every((r) => r.ok),
      output: ctx.messages.includeSummary(path, nested.length),
      line: line,
      column: column,
      start: cmd.start,
      end: cmd.end,
      file: fromFile,
    );
    return (marker, nested);
  }

  /// `INCLUDE [FILE=]'名字' [ENCODING='…']`：取引号里的名字，或 `FILE=` 后的裸记号。
  static String? _includePath(SyntaxCommand cmd) {
    final rest = cmd.raw.replaceFirst(
        RegExp(r'^\s*INCLUDE\b', caseSensitive: false), '');
    final quoted = RegExp('''['"]([^'"]+)['"]''').firstMatch(rest);
    if (quoted != null) return quoted.group(1);
    final bare = RegExp(r'(?:FILE\s*=\s*)?(\S+)', caseSensitive: false)
        .firstMatch(rest.trim());
    final v = bare?.group(1);
    if (v == null || v.isEmpty || v.toUpperCase() == 'FILE') return null;
    return v;
  }

  static SyntaxResult _execute(SyntaxCommand cmd, Dataset ds,
      SyntaxMessages messages, Map<String, Dataset> files,
      {SyntaxSaver? saver}) {
    try {
      switch (cmd.verb) {
        case 'ADD':
        case 'MATCH':
          // `ADD FILES` / `MATCH FILES`：第二个记号必须是 FILES
          if (RegExp(r'^\s*(ADD|MATCH)\s+FILES\b',
                  caseSensitive: false)
              .hasMatch(cmd.raw)) {
            return _combine(cmd, ds, messages, files);
          }
          return SyntaxResult(
            command: cmd.raw,
            ok: false,
            output: messages.combineSyntax,
          );
        case 'COMPUTE':
          return _compute(cmd, ds, messages);
        case 'RECODE':
          return _recode(cmd, ds, messages);
        case 'RANK':
          return _rank(cmd, ds, messages);
        case 'AUTORECODE':
          return _autorecode(cmd, ds, messages);
        case 'SAMPLE':
          return _sample(cmd, ds, messages);
        case 'MRSETS':
          return _mrsets(cmd, ds, messages);
        case 'SORT':
          return _sort(cmd, ds);
        case 'SELECT':
          return _select(cmd, ds);
        case 'DESCRIPTIVES':
        case 'DESCRIPTIVE':
          return _descriptives(cmd, ds);
        case 'FREQUENCIES':
          return _frequencies(cmd, ds);
        case 'T-TEST':
        case 'TTEST':
          return _ttest(cmd, ds);
        case 'CORRELATIONS':
        case 'CORR':
          return _corr(cmd, ds, messages);
        case 'LIST':
          return _list(cmd, ds);
        case 'DISPLAY':
        case 'SHOW':
          return SyntaxResult(
            command: cmd.raw,
            ok: true,
            output: 'Dataset ${ds.name}\n'
                'Cases: ${ds.nCases}  Variables: ${ds.nVars}\n'
                'Vars: ${ds.variables.map((v) => v.name).join(", ")}',
          );
        case 'HELP':
          return SyntaxResult(
            command: cmd.raw,
            ok: true,
            output: messages.helpText,
          );
        case 'SAVE':
          return _save(cmd, ds, messages, saver: saver);
        case 'SPLIT':
          return _split(cmd, ds, messages);
        default:
          return SyntaxResult(
            command: cmd.raw,
            ok: false,
            output: messages.unsupportedCommand(cmd.verb),
          );
      }
    } catch (e) {
      return SyntaxResult(
        command: cmd.raw,
        ok: false,
        output: messages.error('$e'),
      );
    }
  }

  /// `SAVE OUTFILE='path' [FILELABEL='label']`：经调用方的写出器写成 .sav。
  static SyntaxResult _save(SyntaxCommand cmd, Dataset ds, SyntaxMessages messages,
      {SyntaxSaver? saver}) {
    final rest = cmd.raw.replaceFirst(
        RegExp(r'^\s*SAVE\b', caseSensitive: false), '');
    final outMatch =
        RegExp(r'''OUTFILE\s*=\s*['"]([^'"]+)['"]''', caseSensitive: false)
            .firstMatch(rest);
    final quoted = RegExp('''['"]([^'"]+)['"]''').firstMatch(rest);
    final path = outMatch?.group(1) ?? quoted?.group(1);
    if (path == null || path.isEmpty) {
      return SyntaxResult(command: cmd.raw, ok: false,
          output: messages.saveSyntax);
    }
    if (saver == null) {
      return SyntaxResult(command: cmd.raw, ok: false,
          output: messages.saveUnavailable);
    }
    final ok = saver(path, ds);
    if (!ok) {
      return SyntaxResult(command: cmd.raw, ok: false,
          output: messages.saveFailed);
    }
    return SyntaxResult(command: cmd.raw, ok: true,
        output: messages.saveSuccess(path, ds.nCases, ds.nVars));
  }

  /// `SPLIT FILE BY v1 v2 …` / `SPLIT FILE OFF`：设置活动数据集的拆分变量。
  ///
  /// 存为逗号分隔的名字（模型沿用单一字符串字段），分析层负责按组合分组。
  static SyntaxResult _split(
      SyntaxCommand cmd, Dataset ds, SyntaxMessages messages) {
    final rest = cmd.raw.replaceFirst(
        RegExp(r'^\s*SPLIT\s+FILE\b', caseSensitive: false), '').trim();
    if (RegExp(r'^OFF\b', caseSensitive: false).hasMatch(rest)) {
      ds.splitVariable = null;
      return SyntaxResult(command: cmd.raw, ok: true,
          output: 'SPLIT FILE OFF');
    }
    final by = rest.replaceFirst(
        RegExp(r'^BY\b', caseSensitive: false), '').trim();
    if (by.isEmpty) {
      return SyntaxResult(command: cmd.raw, ok: false,
          output: messages.splitSyntax);
    }
    final names = by
        .split(RegExp(r'[\s,]+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      return SyntaxResult(command: cmd.raw, ok: false,
          output: messages.splitSyntax);
    }
    for (final n in names) {
      if (ds.indexOf(n) < 0) {
        return SyntaxResult(command: cmd.raw, ok: false,
            output: messages.splitUnknownVar(n));
      }
    }
    ds.splitVariable = names.join(',');
    return SyntaxResult(command: cmd.raw, ok: true,
        output: 'SPLIT FILE BY ${names.join(", ")} '
            '(${ds.nCases} cases)');
  }

  static SyntaxResult _compute(
      SyntaxCommand cmd, Dataset ds, SyntaxMessages messages) {
    final raw = cmd.args.join(' ');
    final m = RegExp(r'^(\w+)\s*=\s*(.+)$', caseSensitive: false).firstMatch(raw);
    if (m == null) {
      return SyntaxResult(
          command: cmd.raw, ok: false, output: messages.computeSyntax);
    }
    final r = Transforms.compute(
      ds,
      targetVar: m.group(1)!,
      expression: m.group(2)!,
    );
    return SyntaxResult(command: cmd.raw, ok: true, output: r.message);
  }

  static SyntaxResult _recode(
      SyntaxCommand cmd, Dataset ds, SyntaxMessages messages) {
    // RECODE a (1=10) (2=20) INTO b.  简化
    final raw = cmd.args.join(' ');
    final intoM = RegExp(r'INTO\s+(\w+)', caseSensitive: false).firstMatch(raw);
    final target = intoM?.group(1) ?? 'recoded';
    final varM = RegExp(r'^(\w+)').firstMatch(raw.trim());
    if (varM == null) {
      return SyntaxResult(
          command: cmd.raw, ok: false, output: messages.recodeSyntax);
    }
    final rules = <String, String>{};
    for (final m in RegExp(r'\(([^)]+)\)').allMatches(raw)) {
      final kv = m.group(1)!.split('=');
      if (kv.length == 2) rules[kv[0].trim()] = kv[1].trim();
    }
    final r = Transforms.recode(
      ds,
      sourceVar: varM.group(1)!,
      targetVar: target,
      rules: rules,
    );
    return SyntaxResult(command: cmd.raw, ok: true, output: r.message);
  }

  /// AUTORECODE：`AUTORECODE VARIABLES=a b /INTO=an bn /DESCENDING /GROUP
  /// /BLANK=VALID`。
  ///
  /// `/INTO` 可省略，此时按「源名_n」命名；数量不一致时报错。
  static SyntaxResult _autorecode(
      SyntaxCommand cmd, Dataset ds, SyntaxMessages messages) {
    final up = cmd.raw.toUpperCase();
    final varsM =
        RegExp(r'VARIABLES\s*=([^/]*)', caseSensitive: false).firstMatch(cmd.raw);
    final head = varsM?.group(1) ??
        cmd.raw
            .split('/')
            .first
            .replaceFirst(RegExp(r'^\s*AUTORECODE\b', caseSensitive: false), '');
    final srcs = _names(head);
    if (srcs.isEmpty) {
      return SyntaxResult(
          command: cmd.raw, ok: false, output: messages.autorecodeSyntax);
    }
    final intoM =
        RegExp(r'INTO\s*=?\s*([^/]*)', caseSensitive: false).firstMatch(cmd.raw);
    final dsts = intoM == null ? null : _names(intoM.group(1)!);
    if (dsts != null && dsts.length != srcs.length) {
      return SyntaxResult(
        command: cmd.raw,
        ok: false,
        output: messages.autorecodeCountMismatch(srcs.length, dsts.length),
      );
    }
    final r = Transforms.autorecode(
      ds,
      sourceVars: srcs,
      targetVars: dsts,
      descending: RegExp(r'DESCENDING\b').hasMatch(up),
      group: RegExp(r'/GROUP\b').hasMatch(up),
      blankValid: RegExp(r'BLANK\s*=\s*VALID\b').hasMatch(up),
    );
    return SyntaxResult(command: cmd.raw, ok: true, output: r.message);
  }

  /// SAMPLE：`SAMPLE 0.5`（按比例）或 `SAMPLE 5 FROM 10`（n FROM N），
  /// 可加 `/SEED=123` 指定种子（默认固定种子，便于复现）。
  static SyntaxResult _sample(
      SyntaxCommand cmd, Dataset ds, SyntaxMessages messages) {
    final raw = cmd.raw
        .replaceFirst(RegExp(r'^\s*SAMPLE\b', caseSensitive: false), '')
        .trim();
    final seedM =
        RegExp(r'SEED\s*=\s*(\d+)', caseSensitive: false).firstMatch(raw);
    final seed = int.tryParse(seedM?.group(1) ?? '') ?? 20261016;
    final body =
        raw.replaceAll(RegExp(r'SEED\s*=\s*\d+', caseSensitive: false), ' ');
    final fromM =
        RegExp(r'^(\d+)\s+FROM\s+(\d+)', caseSensitive: false).firstMatch(body.trim());
    if (fromM != null) {
      final r = Transforms.sample(
        ds,
        n: int.parse(fromM.group(1)!),
        from: int.parse(fromM.group(2)!),
        seed: seed,
      );
      return SyntaxResult(command: cmd.raw, ok: true, output: r.message);
    }
    final fracM = RegExp(r'^(\d*\.?\d+)').firstMatch(body.trim());
    final frac = fracM == null ? null : double.tryParse(fracM.group(1)!);
    if (frac == null) {
      return SyntaxResult(
          command: cmd.raw, ok: false, output: messages.sampleSyntax);
    }
    final r = Transforms.sample(ds, fraction: frac, seed: seed);
    return SyntaxResult(command: cmd.raw, ok: true, output: r.message);
  }

  /// MRSETS：`MRSETS /MDGROUP NAME=$m LABEL='…' VARIABLES=v1 v2 VALUE=1
  /// /MCGROUP NAME=$c VARIABLES=a b /DELETE NAME=$m /DISPLAY NAME=ALL`。
  ///
  /// 应用扩展（PSPP 里多响应表由 CTABLES 提供）：`/FREQUENCIES NAME=$m` 与
  /// `/CROSSTABS NAME=$m BY=gender`。
  static SyntaxResult _mrsets(
      SyntaxCommand cmd, Dataset ds, SyntaxMessages messages) {
    final parts = cmd.raw.split(RegExp(r'\s*/\s*'));
    final outs = <String>[];
    for (final part in parts.skip(1)) {
      final m = RegExp(r'^([A-Za-z]+)\s*(.*)$', dotAll: true)
          .firstMatch(part.trim());
      if (m == null) continue;
      final sub = m.group(1)!.toUpperCase();
      final body = m.group(2)!;
      switch (sub) {
        case 'MDGROUP':
        case 'MCGROUP':
          final isMd = sub == 'MDGROUP';
          final catM = RegExp(r'CATEGORYLABELS\s*=\s*(\w+)', caseSensitive: false)
              .firstMatch(body);
          final set = MRSets.define(
            ds,
            name: _opt(body, 'NAME') ?? '',
            type: isMd ? MrSetType.md : MrSetType.mc,
            variables: _optVars(body),
            label: _optQuoted(body, 'LABEL') ?? '',
            counted: isMd ? _optValue(body) : null,
            categoryLabels: (catM?.group(1) ?? '').toUpperCase() ==
                    'COUNTEDVALUES'
                ? MrCategorySource.countedValues
                : MrCategorySource.varLabels,
          );
          outs.add('MRSETS ${set.type.verb} ${set.name} defined '
              '(${set.variables.length} variables'
              '${isMd ? ', VALUE=${set.counted}' : ''})');
          break;
        case 'DELETE':
          final n = MRSets.delete(ds, _mrsetNames(body, ds));
          outs.add('MRSETS /DELETE removed $n set(s); '
              '${ds.mrSets.length} remaining');
          break;
        case 'DISPLAY':
          final names = _mrsetNames(body, ds);
          final sets = names.isEmpty
              ? ds.mrSets
              : [for (final n in names) _lookupOrThrow(ds, n)];
          outs.add(MRSetsText.display(sets));
          break;
        case 'FREQUENCIES':
          final names = _mrsetNames(body, ds);
          final targets = names.isEmpty
              ? [for (final s in ds.mrSets) s.name]
              : names;
          if (targets.isEmpty) {
            outs.add('MRSETS /FREQUENCIES (no multiple response sets)');
            break;
          }
          for (final n in targets) {
            outs.add(MRSetsText.frequencies(
                MRSets.frequencies(ds, _lookupOrThrow(ds, n))));
          }
          break;
        case 'CROSSTABS':
          final by = _opt(body, 'BY') ??
              RegExp(r'\bBY\s+(\S+)', caseSensitive: false)
                  .firstMatch(body)
                  ?.group(1);
          if (by == null) {
            return SyntaxResult(
                command: cmd.raw, ok: false, output: messages.mrsetsSyntax);
          }
          final names = _mrsetNames(body, ds);
          final targets = names.isEmpty
              ? [for (final s in ds.mrSets) s.name]
              : names;
          if (targets.isEmpty) {
            outs.add('MRSETS /CROSSTABS (no multiple response sets)');
            break;
          }
          for (final n in targets) {
            outs.add(MRSetsText.crosstab(
                MRSets.crosstab(ds, _lookupOrThrow(ds, n), by)));
          }
          break;
        default:
          return SyntaxResult(
              command: cmd.raw, ok: false, output: messages.mrsetsSyntax);
      }
    }
    if (outs.isEmpty) {
      return SyntaxResult(
          command: cmd.raw, ok: false, output: messages.mrsetsSyntax);
    }
    return SyntaxResult(command: cmd.raw, ok: true, output: outs.join('\n'));
  }

  /// `ADD FILES` / `MATCH FILES`（COMBINE FILES）。
  ///
  /// `ADD FILES /FILE=* /FILE='其它文件' [/RENAME=(旧=新)] [/IN=指示变量]`
  /// `MATCH FILES /FILE=* /TABLE='查表文件' /BY 键变量 [/IN=…]`
  ///
  /// `/FILE=*` 是当前数据集；其它文件用 [files] 注册表里的名字（键可以是文件
  /// 路径或文件名，大小写不敏感）。命令行里引用的每个文件必须先由调用方读入，
  /// 语法执行器本身不做文件 I/O。
  static SyntaxResult _combine(SyntaxCommand cmd, Dataset ds,
      SyntaxMessages messages, Map<String, Dataset> files) {
    final isMatch = cmd.raw.trimLeft().toUpperCase().startsWith('MATCH');
    final groups = cmd.raw.split(RegExp(r'\s*/\s*'));
    // 每组：FILE=/TABLE= 开一个输入，其后 RENAME=/IN= 属于该输入
    final refs = <String>[];
    final isTable = <bool>[];
    final renames = <Map<String, String>>[];
    final inVars = <String?>[];
    List<String>? by;
    List<String>? keep;
    List<String>? drop;
    var current = -1;
    for (final group in groups.skip(1)) {
      final g = group.trim();
      if (g.isEmpty) continue;
      final up = g.toUpperCase();
      if (up.startsWith('FILE=') || up.startsWith('TABLE=')) {
        final isTbl = up.startsWith('TABLE=');
        final rest = g.substring(isTbl ? 6 : 5).trim();
        refs.add(_bare(rest.split(RegExp(r'\s+')).first));
        isTable.add(isTbl);
        renames.add({});
        inVars.add(null);
        current++;
        continue;
      }
      if (current < 0) {
        return SyntaxResult(
            command: cmd.raw, ok: false, output: messages.combineSyntax);
      }
      if (up.startsWith('RENAME=')) {
        final m = RegExp(r'\((.*)\)', dotAll: true).firstMatch(g);
        if (m != null) {
          for (final pair in m.group(1)!.split(RegExp(r'[\s,]+'))) {
            final eq = pair.indexOf('=');
            if (eq <= 0) continue;
            renames[current][pair.substring(0, eq).trim()] =
                pair.substring(eq + 1).trim();
          }
        }
        continue;
      }
      if (up.startsWith('IN=')) {
        inVars[current] = _bare(g.substring(3).trim());
        continue;
      }
      if (up.startsWith('BY')) {
        by = _names(g.substring(2).replaceFirst('=', ' '));
        continue;
      }
      if (up.startsWith('KEEP=')) {
        keep = _names(g.substring(5));
        continue;
      }
      if (up.startsWith('DROP=')) {
        drop = _names(g.substring(5));
        continue;
      }
      // SORT / FIRST / LAST / MAP 等本应用未实现
      return SyntaxResult(
          command: cmd.raw, ok: false, output: messages.combineSyntax);
    }
    if (refs.isEmpty) {
      return SyntaxResult(
          command: cmd.raw, ok: false, output: messages.combineSyntax);
    }
    final inputs = <CombineInput>[];
    for (var k = 0; k < refs.length; k++) {
      final d = _fileByName(refs[k], ds, files);
      if (d == null) {
        throw ArgumentError('file not found: ${refs[k]}');
      }
      if (isTable[k] && !isMatch) {
        throw ArgumentError('TABLE= is only valid with MATCH FILES');
      }
      inputs.add(CombineInput(d, rename: renames[k], inVar: inVars[k]));
    }
    final CombineResult result;
    if (isMatch) {
      final mainAt = isTable.indexOf(false);
      if (mainAt < 0) {
        throw ArgumentError('MATCH FILES requires a FILE= input');
      }
      final main = inputs.removeAt(mainAt);
      isTable.removeAt(mainAt);
      refs.removeAt(mainAt);
      result = CombineFiles.matchFiles(main, inputs,
          by: by, keep: keep, drop: drop);
    } else {
      result = CombineFiles.addFiles(inputs, by: by, keep: keep, drop: drop);
    }
    ds.replaceWith(result.dataset);
    return SyntaxResult(command: cmd.raw, ok: true, output: result.message);
  }

  /// `'名字'` / `"名字"` / `名字` 都取裸文本
  static String _bare(String token) {
    if (token.length >= 2 &&
        (token.startsWith("'") && token.endsWith("'") ||
            token.startsWith('"') && token.endsWith('"'))) {
      return token.substring(1, token.length - 1);
    }
    return token;
  }

  /// 文件引用：`*` 是活动数据集；否则在 [files] 里按全名或文件名查找
  static Dataset? _fileByName(
      String ref, Dataset ds, Map<String, Dataset> files) {
    if (ref == '*') return ds;
    final key = ref.toLowerCase();
    for (final e in files.entries) {
      if (e.key.toLowerCase() == key) return e.value;
    }
    for (final e in files.entries) {
      final base = e.key.split(RegExp(r'[\\/]')).last.toLowerCase();
      if (base == key) return e.value;
    }
    return null;
  }

  static MrSet _lookupOrThrow(Dataset ds, String name) {
    final s = MRSets.lookup(ds, name);
    if (s == null) throw ArgumentError('no multiple response set named $name');
    return s;
  }

  /// `KEY=token`（单个记号）
  static String? _opt(String body, String key) =>
      RegExp('$key\\s*=\\s*([^\\s/]+)', caseSensitive: false)
          .firstMatch(body)
          ?.group(1);

  /// `KEY='…'`（带引号的文本）
  static String? _optQuoted(String body, String key) {
    final m = RegExp("$key\\s*=\\s*('[^']*'|\"[^\"]*\")", caseSensitive: false)
        .firstMatch(body);
    if (m == null) return null;
    final t = m.group(1)!;
    return t.substring(1, t.length - 1);
  }

  /// `VALUE=`：数字取值转 num，带引号或非数字保持字符串（类型与变量一致由定义校验）
  static Object? _optValue(String body) {
    final m = RegExp("VALUE\\s*=\\s*('[^']*'|\"[^\"]*\"|[^\\s/]+)",
            caseSensitive: false)
        .firstMatch(body);
    if (m == null) return null;
    final t = m.group(1)!;
    if (t.startsWith("'") || t.startsWith('"')) {
      return t.substring(1, t.length - 1);
    }
    return double.tryParse(t) ?? t;
  }

  /// `VARIABLES=`：取到下一个选项关键字为止
  static List<String> _optVars(String body) {
    final m = RegExp(r'VARIABLES\s*=([^/]*)', caseSensitive: false)
        .firstMatch(body);
    if (m == null) return const [];
    var text = m.group(1)!;
    final stop = RegExp(r'\b(NAME|LABEL|LABELSOURCE|VALUE|CATEGORYLABELS)\s*=',
            caseSensitive: false)
        .firstMatch(text);
    if (stop != null) text = text.substring(0, stop.start);
    return _names(text);
  }

  /// `/DELETE`、`/DISPLAY` 等的 `NAME=`：支持 `NAME=$m`、`NAME=[$a $b]` 与 `NAME=ALL`
  static List<String> _mrsetNames(String body, Dataset ds) {
    final m = RegExp(r'NAME\s*=\s*(\[[^\]]*\]|\S+)', caseSensitive: false)
        .firstMatch(body);
    if (m == null) return const [];
    final t = m.group(1)!;
    if (t.toUpperCase() == 'ALL') {
      return [for (final s in ds.mrSets) s.name];
    }
    if (t.startsWith('[')) return _names(t);
    return [t];
  }

  /// 从变量表文本里取变量名：忽略括号内容，按空白 / 逗号分列。
  static List<String> _names(String s) => s
      .replaceAll(RegExp(r'\([^)]*\)'), ' ')
      .split(RegExp(r'[\s,]+'))
      .where((e) => RegExp(r'^[A-Za-z_]\w*$').hasMatch(e))
      .toList();

  /// RANK：`RANK VARIABLES=v1 (A) v2 (D) /NTILES(4) /TIES=MEAN`。
  ///
  /// 自变量（VARIABLES=）之后到第一个 `/` 之前是变量表，每个变量可各带
  /// `(A)` 升序或 `(D)` 降序；随后是输出函数与结处理选项。
  static SyntaxResult _rank(
      SyntaxCommand cmd, Dataset ds, SyntaxMessages messages) {
    final up = cmd.raw.toUpperCase();

    // 变量表：VARIABLES= 之后，或命令动词之后到第一个 '/' 之前
    final varsM =
        RegExp(r'VARIABLES\s*=([^/]*)', caseSensitive: false).firstMatch(cmd.raw);
    final head = varsM?.group(1) ??
        cmd.raw
            .split('/')
            .first
            .replaceFirst(RegExp(r'^\s*RANK\b', caseSensitive: false), '');
    final specs = <(String, bool)>[];
    for (final m
        in RegExp(r'([A-Za-z_]\w*)\s*(\(\s*([ADad])\s*\))?').allMatches(head)) {
      specs.add((m.group(1)!, (m.group(3) ?? 'A').toUpperCase() == 'D'));
    }
    if (specs.isEmpty) {
      return SyntaxResult(
          command: cmd.raw, ok: false, output: messages.rankSyntax);
    }

    // 输出函数（NTILES 与 NORMAL 都含 /N，先判长名）
    var function = RankFunction.rank;
    var ntiles = 4;
    if (RegExp(r'NTILES\b').hasMatch(up)) {
      function = RankFunction.ntiles;
      final m = RegExp(r'NTILES\s*\(\s*(\d+)\s*\)').firstMatch(up);
      ntiles = int.tryParse(m?.group(1) ?? '') ?? 4;
    } else if (RegExp(r'/NORMAL\b').hasMatch(up)) {
      function = RankFunction.normal;
    } else if (RegExp(r'/PERCENT\b').hasMatch(up)) {
      function = RankFunction.percent;
    } else if (RegExp(r'/PROPORTION\b').hasMatch(up)) {
      function = RankFunction.proportion;
    } else if (RegExp(r'/RFRACTION\b').hasMatch(up)) {
      function = RankFunction.rFraction;
    } else if (RegExp(r'/N\b').hasMatch(up)) {
      function = RankFunction.n;
    }

    var ties = RankTies.mean;
    final tm = RegExp(r'TIES\s*=\s*(\w+)').firstMatch(up);
    if (tm != null) {
      ties = switch (tm.group(1)!) {
        'LOW' => RankTies.low,
        'HIGH' => RankTies.high,
        'CONDENSE' => RankTies.condense,
        _ => RankTies.mean,
      };
    }

    final out = <String>[];
    for (final (name, desc) in specs) {
      out.add(Transforms.rank(
        ds,
        sourceVar: name,
        descending: desc,
        function: function,
        ties: ties,
        ntiles: ntiles,
      ).message);
    }
    return SyntaxResult(command: cmd.raw, ok: true, output: out.join('\n'));
  }

  static SyntaxResult _sort(SyntaxCommand cmd, Dataset ds) {
    final keys = cmd.args
        .expand((e) => e.split(RegExp(r'\s+')))
        .where((e) => e.isNotEmpty && e.toUpperCase() != 'BY' && e.toUpperCase() != 'DESCENDING')
        .toList();
    final desc = cmd.raw.toUpperCase().contains('DESCENDING') ||
        cmd.raw.toUpperCase().contains('/DESCENDING');
    final r = Transforms.sortCases(ds, keys: keys, descending: desc);
    return SyntaxResult(command: cmd.raw, ok: true, output: r.message);
  }

  static SyntaxResult _select(SyntaxCommand cmd, Dataset ds) {
    final cond = cmd.args.join(' ').replaceFirst(RegExp(r'^IF\s+', caseSensitive: false), '');
    final r = Transforms.selectIf(ds, condition: cond);
    return SyntaxResult(command: cmd.raw, ok: true, output: r.message);
  }

  static SyntaxResult _descriptives(SyntaxCommand cmd, Dataset ds) {
    final names = _varList(cmd.args.join(' '));
    final buf = StringBuffer('Descriptives\n');
    for (final n in names) {
      final d = Descriptives.compute(ds.numericColumn(n));
      buf.writeln(
          '$n  N=${d.n}  Mean=${formatNum(d.mean)}  SD=${formatNum(d.sd)}  '
          'Min=${formatNum(d.min)}  Max=${formatNum(d.max)}');
    }
    return SyntaxResult(command: cmd.raw, ok: true, output: buf.toString());
  }

  static SyntaxResult _frequencies(SyntaxCommand cmd, Dataset ds) {
    final names = _varList(cmd.args.join(' '));
    final buf = StringBuffer('Frequencies\n');
    for (final n in names) {
      final f = Frequencies.compute(MissingAware.raw(ds, n), variableName: n);
      buf.writeln('$n  Valid=${f.nValid}  Missing=${f.nMissing}');
      for (final r in f.rows.take(15)) {
        buf.writeln('  ${r.label}: ${r.frequency}  ${formatNum(r.validPercent, digits: 1)}%');
      }
    }
    return SyntaxResult(command: cmd.raw, ok: true, output: buf.toString());
  }

  static SyntaxResult _ttest(SyntaxCommand cmd, Dataset ds) {
    final joined = cmd.args.join(' ');
    final testvalM =
        RegExp(r'TESTVAL\s*=\s*([\d.\-]+)', caseSensitive: false).firstMatch(joined);
    final mu = double.tryParse(testvalM?.group(1) ?? '') ?? 0;
    final names = _varList(joined);
    final buf = StringBuffer('T-Test  mu=$mu\n');
    for (final n in names) {
      final r = TTest.oneSample(ds.numericColumn(n), mu0: mu);
      buf.writeln(
          '$n  t=${formatNum(r.t)}  df=${formatNum(r.df, digits: 0)}  p=${formatP(r.pTwoTail)}  '
          'Mean=${formatNum(r.mean1)}  95%CI=[${formatNum(r.ciLower95)}, ${formatNum(r.ciUpper95)}]');
    }
    return SyntaxResult(command: cmd.raw, ok: true, output: buf.toString());
  }

  static SyntaxResult _corr(
      SyntaxCommand cmd, Dataset ds, SyntaxMessages messages) {
    final names = _varList(cmd.args.join(' '));
    if (names.length < 2) {
      return SyntaxResult(
          command: cmd.raw, ok: false, output: messages.corrNeedsTwo);
    }
    // 规则 B（成对删除，PSPP / SPSS 默认）：每一对单独取两者都有效的个案
    final buf = StringBuffer('Correlation Matrix\n');
    buf.writeln(names.map((n) => n.padLeft(10)).join(''));
    for (var i = 0; i < names.length; i++) {
      final row = <String>[];
      for (var j = 0; j < names.length; j++) {
        if (i == j) {
          row.add(formatNum(1).padLeft(10));
          continue;
        }
        final (x, y) = MissingAware.pairs(ds, names[i], names[j]);
        row.add(formatNum(Correlation.pearson(x, y).r).padLeft(10));
      }
      buf.writeln('${names[i].padRight(10)}${row.join()}');
    }
    return SyntaxResult(command: cmd.raw, ok: true, output: buf.toString());
  }

  static SyntaxResult _list(SyntaxCommand cmd, Dataset ds) {
    final buf = StringBuffer('LIST  (${ds.nCases} cases)\n');
    buf.writeln(ds.variables.map((v) => v.name.padLeft(10)).join());
    for (var i = 0; i < ds.nCases && i < 50; i++) {
      buf.writeln(ds.cases[i]
          .map((e) => (e?.toString() ?? '').padLeft(10))
          .join());
    }
    if (ds.nCases > 50) buf.writeln('... ${ds.nCases - 50} more');
    return SyntaxResult(command: cmd.raw, ok: true, output: buf.toString());
  }

  static List<String> _varList(String s) {
    final tokens = s
        .replaceAll(RegExp(r'VARIABLES\s*=', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\/\w+', caseSensitive: false), ' ')
        .split(RegExp(r'[\s,=]+'))
        .where((e) => RegExp(r'^\w+$').hasMatch(e))
        .where((e) {
          final u = e.toUpperCase();
          return !const {
            'TO', 'BY', 'WITH', 'ALL', 'TESTVAL', 'VARIABLES', 'DESCRIPTIVES',
            'FREQUENCIES', 'CORRELATIONS', 'T-TEST', 'INTO',
          }.contains(u);
        })
        .toList();
    return tokens;
  }
}
