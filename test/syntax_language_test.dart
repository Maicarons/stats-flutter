/// v1.5.0 M3 语法语言层测试：注释、宏、INCLUDE、命令定位。
///
/// 语义对照 PSPP 2.1.2 文档：
/// - 注释：`_ref/pspp-2.1.2/doc/utilities.texi`（COMMENT 一节）
/// - 宏：`_ref/pspp-2.1.2/doc/flow-control.texi`（DEFINE 及其子节）
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/syntax/syntax_engine.dart';
import 'package:stats_flutter/core/syntax/syntax_preprocess.dart';

Dataset _ds(List<String> names, List<List<Object?>> cases) {
  final d = Dataset(name: 'test');
  for (final n in names) {
    d.addVariable(Variable(name: n));
  }
  for (final row in cases) {
    d.addCase(List<Object?>.of(row));
  }
  return d;
}

List<double?> _numCol(Dataset d, String name) =>
    [for (final v in d.rawColumn(name)) v == null ? null : (v as num).toDouble()];

List<String> _varNames(Dataset d) => [for (final v in d.variables) v.name];

String _why(List<SyntaxResult> rs) => rs
    .map((r) => '「${r.command}」 ok=${r.ok} hint=${r.hint}: ${r.output}')
    .join(' | ');

void main() {
  group('注释（PSPP 语义）', () {
    test('`*` 注释以行尾句点结束，后续命令照常执行', () {
      final d = _ds(['score'], [
        [1],
        [2],
      ]);
      final rs = SyntaxExecutor.run('* 说明行.\nCOMPUTE x = score + 1.', d);
      expect(rs.length, 1, reason: _why(rs));
      expect(rs.single.ok, isTrue, reason: _why(rs));
      expect(_numCol(d, 'x'), [2, 3]);
    });

    test('COMMENT 可跨多行，到行尾句点结束', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run(
          'COMMENT 这是一段\n跨行的注释.\nCOMPUTE x = score + 1.', d);
      expect(rs.length, 1, reason: _why(rs));
      expect(_numCol(d, 'x'), [2]);
    });

    test('空行结束注释', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run('* 注释\n\nCOMPUTE x = score + 1.', d);
      expect(rs.length, 1, reason: _why(rs));
      expect(_numCol(d, 'x'), [2]);
    });

    test('注释里非行尾的句点不结束注释', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run(
          '* 见 v1.2.0 说明（行内句点不结束注释）.\nCOMPUTE x = score + 1.', d);
      expect(rs.length, 1, reason: _why(rs));
      expect(_numCol(d, 'x'), [2]);
    });

    test('行内 /* … */ 注释被剥掉，参数不受影响', () {
      final d = _ds(['score'], [
        [1],
        [2],
      ]);
      final rs = SyntaxExecutor.run('COMPUTE x = score /* 加一 */ + 1.', d);
      expect(rs.length, 1, reason: _why(rs));
      expect(_numCol(d, 'x'), [2, 3]);
    });

    test('整行只有 /* … */ 时结束当前命令（PSPP）', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs =
          SyntaxExecutor.run('COMPUTE x = score + 1\n/* 说明 */\nLIST.', d);
      expect(rs.length, 2, reason: _why(rs));
      expect(rs[0].ok, isTrue, reason: _why(rs));
      expect(rs[0].command, 'COMPUTE x = score + 1');
      expect(rs[1].command, 'LIST');
      expect(_numCol(d, 'x'), [2]);
    });

    test('`*` 注释吞掉后续命令时给出提示（PSPP 规则）', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run('* 忘了加句点\nLIST.', d);
      expect(rs.length, 1, reason: _why(rs));
      expect(rs.single.hint, isTrue, reason: _why(rs));
      expect(rs.single.ok, isTrue);
      expect(rs.single.output, contains('吞掉'));
      expect(rs.single.output, contains('LIST'));
    });

    test('注释读到文件末尾时给出提示，且不执行任何命令', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run('* 一直没结束\nCOMPUTE x = score + 1', d);
      expect(rs.length, 1, reason: _why(rs));
      expect(rs.single.hint, isTrue, reason: _why(rs));
      expect(rs.single.output, contains('文件末尾'));
      expect(d.nVars, 1);
    });

    test('`*` 作为乘法时不当作注释', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run('COMPUTE x = 2 * 3.', d);
      expect(rs.length, 1, reason: _why(rs));
      expect(_numCol(d, 'x'), [6]);
    });

    test('命令带原始行号 / 列号 / 偏移（供编辑器跳转）', () {
      final d = _ds(['score'], [
        [1],
      ]);
      const src = '* 注释.\nCOMPUTE x = score + 1.\nLIST.';
      final rs = SyntaxExecutor.run(src, d);
      expect(rs.length, 2, reason: _why(rs));
      expect(rs[0].line, 2);
      expect(rs[0].column, 1);
      expect(rs[0].start, src.indexOf('COMPUTE'));
      expect(rs[0].end, src.indexOf('COMPUTE') + 'COMPUTE x = score + 1'.length);
      expect(rs[1].line, 3);
      expect(rs[1].start, src.indexOf('LIST'));
    });

    test('注释与宏展开之后仍能定位到原始位置', () {
      final d = _ds(['score'], [
        [1],
      ]);
      const src = 'DEFINE !m()\nLIST.\n!ENDDEFINE.\n* 一行注释.\n!m.';
      final rs = SyntaxExecutor.run(src, d);
      expect(rs.length, 1, reason: _why(rs));
      // 命令来自宏体 → 指向 DEFINE 里的那一行
      expect(rs.single.line, 2);
    });

    test('失败结果也带行号', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run('LIST.\nNOPE.', d);
      expect(rs.length, 2, reason: _why(rs));
      expect(rs[0].ok, isTrue);
      expect(rs[1].ok, isFalse);
      expect(rs[1].line, 2);
    });

    test('SyntaxSource 把干净文本偏移映射回原始文本', () {
      const src = '* 一段中文注释.\nCOMPUTE x = 1.';
      final pre = SyntaxPreprocessor.process(src);
      final at = pre.text.indexOf('COMPUTE');
      expect(at, greaterThanOrEqualTo(0));
      expect(pre.toSource(at), src.indexOf('COMPUTE'));
      expect(pre.lineColumn(pre.toSource(at)), (2, 1));
      expect(pre.lineText(1), '* 一段中文注释.');
    });
  });

  group('宏（DEFINE / !ENDDEFINE）', () {
    test('无参宏：调用处替换为宏体', () {
      final d = _ds(['score'], [
        [1],
        [2],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !addone()\nCOMPUTE x = score + 1.\n!ENDDEFINE.\n!addone.', d);
      expect(rs.length, 1, reason: _why(rs));
      expect(rs.single.ok, isTrue, reason: _why(rs));
      expect(_numCol(d, 'x'), [2, 3]);
    });

    test('宏可以写在命令中间（DESCRIPTIVES !vars.）', () {
      final d = _ds(['pre', 'post'], [
        [1, 2],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !vars()\npre post\n!ENDDEFINE.\nDESCRIPTIVES !vars.', d);
      expect(rs.length, 1, reason: _why(rs));
      expect(rs.single.output, contains('pre'));
      expect(rs.single.output, contains('post'));
    });

    test('!POSITIONAL + !CMDEND：PSPP 风格调用（实参跟在宏名后）', () {
      final d = _ds(['pre', 'post'], [
        [1, 2],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !show(!POSITIONAL !CMDEND)\n'
          'DESCRIPTIVES !1.\n'
          '!ENDDEFINE.\n'
          '!show pre post.',
          d);
      expect(rs.length, 1, reason: _why(rs));
      expect(rs.single.output, contains('pre'));
      expect(rs.single.output, contains('post'));
    });

    test('关键字参数 !TOKENS(1) 与 !DEFAULT', () {
      final d = _ds(['pre', 'post'], [
        [1, 2],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !show(vars=!DEFAULT(pre) !TOKENS(1))\n'
          'DESCRIPTIVES !vars.\n'
          '!ENDDEFINE.\n'
          '!show vars=post.\n'
          '!show.',
          d);
      expect(rs.length, 2, reason: _why(rs));
      expect(rs[0].output, contains('post'));
      expect(rs[1].output, contains('pre'));
    });

    test('位置参数与关键字参数混用', () {
      final d = _ds(['pre', 'post'], [
        [1, 2],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !m(!POSITIONAL !TOKENS(1) / vars=!DEFAULT(pre) !TOKENS(1))\n'
          'DESCRIPTIVES !1 !vars.\n'
          '!ENDDEFINE.\n'
          '!m post vars=pre.\n'
          '!m post.',
          d);
      expect(rs.length, 2, reason: _why(rs));
      expect(rs[0].output, contains('post'));
      expect(rs[0].output, contains('pre'));
      expect(rs[1].output, contains('post'));
      expect(rs[1].output, contains('pre'));
    });

    test('括号形式调用（兼容 SPSS 习惯）', () {
      final d = _ds(['pre', 'post'], [
        [1, 2],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !sum2(!POSITIONAL !TOKENS(1) / !POSITIONAL !TOKENS(1))\n'
          'DESCRIPTIVES !1 !2.\n'
          '!ENDDEFINE.\n'
          '!sum2(pre, post).',
          d);
      expect(rs.length, 1, reason: _why(rs));
      expect(rs.single.output, contains('pre'));
      expect(rs.single.output, contains('post'));
    });

    test('!CHAREND 取到定界符为止', () {
      final d = _ds(['pre', 'post'], [
        [1, 2],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !p(vars=!CHAREND(\'/\'))\n'
          'DESCRIPTIVES !vars.\n'
          '!ENDDEFINE.\n'
          '!p vars=pre post/.',
          d);
      expect(rs.length, 1, reason: _why(rs));
      expect(rs.single.output, contains('pre'));
      expect(rs.single.output, contains('post'));
    });

    test('宏函数取值', () {
      const src = 'DEFINE !f()\n'
          "LIST /A=!QUOTE(x) /B=!UPCASE(y) /C=!LENGTH(abcd) "
          '/D=!SUBSTR(abcdef,2,3) /E=!INDEX(hello,ll) /F=!EVAL(2*3+1) '
          "/G=!BLANKS(2)X /H=!NULL /I=!HEAD(a b c) /J=!TAIL(a b c) /K=!UNQUOTE('q')"
          '\n!ENDDEFINE.\n'
          '!f.';
      final pre = SyntaxPreprocessor.process(src);
      expect(pre.issues, isEmpty, reason: pre.issues.toString());
      final body = pre.text;
      expect(body, contains("/A='x'"));
      expect(body, contains('/B=Y'));
      expect(body, contains('/C=4'));
      expect(body, contains('/D=bcd'));
      expect(body, contains('/E=3'));
      expect(body, contains('/F=7'));
      expect(body, contains('/G=  X'));
      expect(body, contains('/H='));
      expect(body, contains('/I=a'));
      expect(body, contains('/J=b c'));
      expect(body, contains('/K=q'));
    });

    test('宏函数实参里的宏调用先展开（!CONCAT(!a, _2)）', () {
      final d = _ds(['pre'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !mk(!POSITIONAL !TOKENS(1))\n'
          'COMPUTE !CONCAT(!1, _2) = 1.\n'
          '!ENDDEFINE.\n'
          '!mk pre.',
          d);
      expect(rs.single.ok, isTrue, reason: _why(rs));
      expect(_varNames(d), contains('pre_2'));
    });

    test('!LET 定义局部变量', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !mk(!POSITIONAL !TOKENS(1))\n'
          '!LET !v = !CONCAT(v, !1)\n'
          'COMPUTE !v = 1.\n'
          '!ENDDEFINE.\n'
          '!mk 3.',
          d);
      expect(rs.single.ok, isTrue, reason: _why(rs));
      expect(_varNames(d), contains('v3'));
    });

    test('!DO … !TO … !BY … !DOEND 生成多条命令', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !mkvars()\n'
          '!DO !i = 1 !TO 3\n'
          'COMPUTE v!i = !i.\n'
          '!DOEND\n'
          '!ENDDEFINE.\n'
          '!mkvars.',
          d);
      expect(rs.length, 3, reason: _why(rs));
      expect(_varNames(d), ['score', 'v1', 'v2', 'v3']);
      expect(_numCol(d, 'v3'), [3]);
    });

    test('!DO 支持 !BY 与递减', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !mkvars()\n'
          '!DO !i = 4 !TO 2 !BY -2\n'
          'COMPUTE w!i = !i.\n'
          '!DOEND\n'
          '!ENDDEFINE.\n'
          '!mkvars.',
          d);
      expect(rs.length, 2, reason: _why(rs));
      expect(_varNames(d), ['score', 'w4', 'w2']);
    });

    test('!IF / !THEN / !ELSE / !ENDIF', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !pick(!POSITIONAL !TOKENS(1))\n'
          '!IF (!1 = 1) !THEN\n'
          'COMPUTE a = 1.\n'
          '!ELSE\n'
          'COMPUTE a = 2.\n'
          '!ENDIF\n'
          '!ENDDEFINE.\n'
          '!pick 1.\n'
          '!pick 2.',
          d);
      expect(rs.length, 2, reason: _why(rs));
      expect(rs[0].command, contains('COMPUTE a = 1'));
      expect(rs[1].command, contains('COMPUTE a = 2'));
      expect(_numCol(d, 'a'), [2]);
    });

    test('嵌套宏调用', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !inner(!POSITIONAL !TOKENS(1))\n'
          'COMPUTE x = !1.\n'
          '!ENDDEFINE.\n'
          'DEFINE !outer()\n'
          '!inner 7\n'
          '!ENDDEFINE.\n'
          '!outer.',
          d);
      expect(rs.single.ok, isTrue, reason: _why(rs));
      expect(_numCol(d, 'x'), [7]);
    });

    test('未定义宏 → 失败并带位置', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run('LIST.\n!nope.', d);
      expect(rs.length, 2, reason: _why(rs));
      expect(rs[1].ok, isFalse);
      expect(rs[1].output, contains('未定义的宏'));
      expect(rs[1].line, 2);
    });

    test('本版未支持的宏构造明确报错', () {
      final d = _ds(['score'], [
        [1],
      ]);
      var rs = SyntaxExecutor.run(
          'DEFINE !e(!POSITIONAL !ENCLOSE("(", ")"))\nLIST.\n!ENDDEFINE.', d);
      expect(rs.any((r) => r.output.contains('未支持')), isTrue, reason: _why(rs));

      rs = SyntaxExecutor.run(
          'DEFINE !f()\n!DO !i !IN (1 2)\nLIST.\n!DOEND\n!ENDDEFINE.\n!f.', d);
      expect(rs.any((r) => r.output.contains('未支持')), isTrue, reason: _why(rs));

      rs = SyntaxExecutor.run('!OFFEXPAND.', d);
      expect(rs.single.output, contains('未支持'), reason: _why(rs));
    });

    test('宏体里的问题定位到 DEFINE 所在行', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !bad()\nLIST !missing.\n!ENDDEFINE.\n!bad.', d);
      final issue = rs.firstWhere((r) => !r.ok, orElse: () => rs.first);
      expect(issue.output, contains('未定义的宏'));
      expect(issue.line, 2);
    });

    test('宏递归有深度上限', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run('DEFINE !r()\n!r\n!ENDDEFINE.\n!r.', d);
      expect(rs.any((r) => r.output.contains('递归')), isTrue, reason: _why(rs));
    });

    test('重复 DEFINE 覆盖旧定义', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run(
          'DEFINE !m() COMPUTE a = 1. !ENDDEFINE.\n'
          'DEFINE !m() COMPUTE a = 2. !ENDDEFINE.\n'
          '!m.',
          d);
      expect(_numCol(d, 'a'), [2], reason: _why(rs));
    });

    test('注释里的 DEFINE 不会被登记', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run(
          '* DEFINE !ghost() LIST. !ENDDEFINE.\nLIST.', d);
      expect(rs.length, 1, reason: _why(rs));
      expect(rs.single.command, 'LIST');
    });
  });

  group('INCLUDE 文件包含', () {
    test('包含文件里的命令被执行，结果按顺序排列', () {
      final d = _ds(['score'], [
        [1],
        [2],
      ]);
      final files = {'setup.sps': 'COMPUTE x = score + 1.\n'};
      final rs = SyntaxExecutor.run("INCLUDE 'setup.sps'.\nLIST.", d,
          include: (p) => files[p]);
      expect(rs.length, 3, reason: _why(rs));
      expect(rs[0].command, contains('INCLUDE'));
      expect(rs[0].output, contains('setup.sps'));
      expect(rs[1].command, 'COMPUTE x = score + 1');
      expect(rs[1].file, 'setup.sps');
      expect(rs[2].command, 'LIST');
      expect(rs[2].file, isNull);
      expect(_numCol(d, 'x'), [2, 3]);
    });

    test('没有文件读取器时报错（行内定位）', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run("INCLUDE FILE='a.sps'.", d);
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('文件读取器'));
      expect(rs.single.line, 1);
    });

    test('文件读不到时报错', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final rs =
          SyntaxExecutor.run("INCLUDE 'nope.sps'.", d, include: (p) => null);
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('nope.sps'));
    });

    test('循环包含被拦截', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final files = {'a.sps': "INCLUDE 'a.sps'."};
      final rs = SyntaxExecutor.run("INCLUDE 'a.sps'.", d,
          include: (p) => files[p]);
      expect(rs.any((r) => r.output.contains('循环')), isTrue, reason: _why(rs));
    });

    test('嵌套层数上限', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final files = <String, String>{
        for (var i = 1; i <= 20; i++) 'f$i.sps': "INCLUDE 'f${i + 1}.sps'.",
        'f21.sps': 'LIST.',
      };
      final rs = SyntaxExecutor.run("INCLUDE 'f1.sps'.", d,
          include: (p) => files[p]);
      expect(rs.any((r) => r.output.contains('嵌套层数')), isTrue,
          reason: _why(rs));
    });

    test('被包含文件出错后停止（PSPP）：该文件后续命令与主脚本后续命令都不执行', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final files = {'bad.sps': 'NOPE.\nLIST.'};
      final rs = SyntaxExecutor.run("INCLUDE 'bad.sps'.\nLIST.", d,
          include: (p) => files[p]);
      expect(rs.any((r) => !r.ok && r.output.contains('尚未支持')), isTrue,
          reason: _why(rs));
      expect(rs.where((r) => r.command == 'LIST').length, 0, reason: _why(rs));
    });

    test('被包含文件里的宏在包含之后可用', () {
      final d = _ds(['score'], [
        [1],
      ]);
      final files = {'m.sps': 'DEFINE !hi()\nLIST.\n!ENDDEFINE.\n'};
      final rs = SyntaxExecutor.run("INCLUDE 'm.sps'.\n!hi.", d,
          include: (p) => files[p]);
      expect(rs.any((r) => r.command == 'LIST'), isTrue, reason: _why(rs));
    });
  });

  group('动词表对齐（M3.6）', () {
    test('implementedVerbs 里的动词都不会被判为「尚未支持」', () {
      final d = _ds(['score'], [
        [1],
      ]);
      for (final verb in implementedVerbs) {
        final rs = SyntaxExecutor.run('$verb.', d);
        expect(
          rs.single.output,
          isNot(SyntaxMessages.en.unsupportedCommand(verb)),
          reason: '$verb 列进了 implementedVerbs，执行器却说未支持',
        );
      }
    });

    test('提示用动词表是已实现动词的超集', () {
      for (final verb in implementedVerbs) {
        expect(commandVerbs, contains(verb),
            reason: '$verb 已实现，却没进「注释吞掉命令」提示表');
      }
    });
  });
}
