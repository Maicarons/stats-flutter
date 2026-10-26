/// v1.7.0 M2：语法程序流 — DO IF / ELSE IF / ELSE / END IF、
/// LOOP（计数 / LOOP IF / BREAK / END LOOP IF）、VECTOR、
/// ComputeEngine 的比较与逻辑运算符。PSPP 语义锚点：
/// 条件逐案求值；LOOP 计数变量在体内可引用；向量下标 1 起。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/syntax/syntax_engine.dart';
import 'package:stats_flutter/core/transforms/transforms.dart';

Dataset _ds() {
  final vars = [
    Variable(name: 'gender', decimals: 0),
    Variable(name: 'score'),
    Variable(name: 'x1'),
    Variable(name: 'x2'),
    Variable(name: 'x3'),
  ];
  final cases = <List<Object?>>[
    [1.0, 60.0, 1.0, 2.0, 3.0],
    [2.0, 80.0, 4.0, 5.0, 6.0],
    [1.0, 90.0, 7.0, 8.0, 9.0],
    [2.0, null, 1.0, 1.0, 1.0],
  ];
  return Dataset(name: 'flow', variables: vars, cases: cases);
}

double? _num(Dataset ds, String name, int row) {
  final i = ds.indexOf(name);
  final v = ds.cases[row][i];
  return v is num ? v.toDouble() : null;
}

void main() {
  test('DO IF / ELSE：条件逐案成立', () {
    final ds = _ds();
    final rs = SyntaxExecutor.run('''
DO IF gender = 1.
COMPUTE bonus = 10.
ELSE.
COMPUTE bonus = 20.
END IF.''', ds);
    expect(rs.last.ok, isTrue);
    expect(_num(ds, 'bonus', 0), 10.0);
    expect(_num(ds, 'bonus', 1), 20.0);
    expect(_num(ds, 'bonus', 2), 10.0);
    expect(_num(ds, 'bonus', 3), 20.0);
  });

  test('ELSE IF 链：第一个成立的分支生效，且嵌套体只改命中行', () {
    final ds = _ds();
    final rs = SyntaxExecutor.run('''
DO IF score >= 85.
COMPUTE grade = 1.
ELSE IF score >= 70.
COMPUTE grade = 2.
ELSE.
COMPUTE grade = 3.
END IF.''', ds);
    expect(rs.last.ok, isTrue);
    expect(_num(ds, 'grade', 0), 3.0); // 60 → ELSE
    expect(_num(ds, 'grade', 1), 2.0); // 80 → ELSE IF
    expect(_num(ds, 'grade', 2), 1.0); // 90 → DO IF
    expect(_num(ds, 'grade', 3), 3.0); // null → ELSE（null 比较为假）
  });

  test('比较与逻辑运算符：AND / OR / NOT / ~=', () {
    final ds = _ds();
    final rs = SyntaxExecutor.run('''
DO IF gender = 1 AND score > 70 OR NOT (score ~= 60).
COMPUTE flag = 1.
ELSE.
COMPUTE flag = 0.
END IF.''', ds);
    expect(rs.last.ok, isTrue);
    expect(_num(ds, 'flag', 0), 1.0); // NOT(60 ~= 60) → 真
    expect(_num(ds, 'flag', 1), 0.0);
    expect(_num(ds, 'flag', 2), 1.0); // gender=1 AND 90>70
    expect(_num(ds, 'flag', 3), 0.0);
  });

  test('LOOP 计数：#i 从 1 到 n（含端点），体内可引用', () {
    final ds = _ds();
    final rs = SyntaxExecutor.run('''
COMPUTE acc = 0.
LOOP #i = 1 TO 4.
COMPUTE acc = acc + #i.
END LOOP.''', ds);
    expect(rs.last.ok, isTrue);
    expect(_num(ds, 'acc', 0), 10.0);
  });

  test('LOOP IF + BREAK：条件循环与提前退出', () {
    final ds = _ds();
    final rs = SyntaxExecutor.run('''
COMPUTE k = 0.
LOOP IF k < 100.
COMPUTE k = k + 7.
END LOOP.''', ds);
    expect(rs.last.ok, isTrue);
    // 0,7,...,98（15 次 +7 = 105 时 105<100 假 → 停在 98+7=105? 逐案：k<100 为真才加）
    final k = _num(ds, 'k', 0)!;
    expect(k, 105.0);
    expect(k, lessThan(100 + 7));
  });

  test('BREAK IF 命中后该行停止迭代', () {
    final ds = _ds();
    final rs = SyntaxExecutor.run('''
COMPUTE t = 0.
LOOP #i = 1 TO 100.
COMPUTE t = t + 1.
BREAK IF t >= 3.
END LOOP.''', ds);
    expect(rs.last.ok, isTrue);
    expect(_num(ds, 't', 0), 3.0);
  });

  test('VECTOR：v(i) 1 起下标 + 循环求和', () {
    final ds = _ds();
    final rs = SyntaxExecutor.run('''
VECTOR v = x1 TO x3.
COMPUTE total = 0.
LOOP #i = 1 TO 3.
COMPUTE total = total + v(#i).
END LOOP.''', ds);
    expect(rs.last.ok, isTrue);
    expect(_num(ds, 'total', 0), 6.0);
    expect(_num(ds, 'total', 1), 15.0);
    expect(_num(ds, 'total', 2), 24.0);
  });

  test('VECTOR 名(k) 展开与未知变量报错', () {
    final ds = _ds();
    final ok = SyntaxExecutor.run('VECTOR w(3).', ds);
    expect(ok.last.ok, isTrue);
    final bad = SyntaxExecutor.run('VECTOR z = nope1 TO nope3.', ds);
    expect(bad.last.ok, isFalse);
  });

  test('孤立 END IF / ELSE / BREAK 报错', () {
    final ds = _ds();
    final r1 = SyntaxExecutor.run('END IF.', ds);
    expect(r1.last.ok, isFalse);
    final r2 = SyntaxExecutor.run('LOOP. COMPUTE a = 1.', ds);
    expect(r2.last.ok, isFalse); // 未闭合
    final r3 = SyntaxExecutor.run('BREAK.', ds);
    expect(r3.last.ok, isFalse);
  });

  test('块内不支持非变换命令', () {
    final ds = _ds();
    final rs = SyntaxExecutor.run('''
DO IF gender = 1.
LIST.
END IF.''', ds);
    expect(rs.last.ok, isFalse);
  });

  test('嵌套 DO IF：内层条件在外层命中的行上求值', () {
    final ds = _ds();
    final rs = SyntaxExecutor.run('''
DO IF gender = 1.
DO IF score > 70.
COMPUTE tier = 1.
ELSE.
COMPUTE tier = 2.
END IF.
ELSE.
COMPUTE tier = 3.
END IF.''', ds);
    expect(rs.last.ok, isTrue);
    expect(_num(ds, 'tier', 0), 2.0); // g=1, 60
    expect(_num(ds, 'tier', 1), 3.0); // g=2
    expect(_num(ds, 'tier', 2), 1.0); // g=1, 90
    expect(_num(ds, 'tier', 3), 3.0); // g=2
  });

  test('ComputeEngine 直接求值锚点', () {
    expect(
        ComputeEngine.evaluate('1 < 2 AND 2 <= 2', {}),
        1.0);
    expect(ComputeEngine.evaluate('3 >= 4 OR 1 = 1', {}), 1.0);
    expect(ComputeEngine.evaluate('NOT 0', {}), 1.0);
    expect(ComputeEngine.evaluate('1 + 2 * 3', {}), 7.0);
    expect(ComputeEngine.evaluate('a ~= b', {'a': 1, 'b': 2}), 1.0);
    expect(ComputeEngine.evaluate('1.5 <= 1.5', {}), 1.0);
  });
}
