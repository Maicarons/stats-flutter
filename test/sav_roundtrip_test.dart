import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:stats_flutter/core/io/sav_io.dart';
import 'package:stats_flutter/core/io/sav_write.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/syntax/syntax_engine.dart';

void main() {
  test('sav write→read round-trip: numeric + string + labels + missing', () {
    final vars = [
      Variable(name: 'id', label: 'ID', decimals: 0)
        ..missingValues.addAll([999]),
      Variable(name: 'score', label: '得分', decimals: 1),
      Variable(name: 'gender', label: '性别', decimals: 0)
        ..valueLabels.addAll({1: '男', 2: '女'}),
      Variable(name: 'name', type: VarType.string, measure: MeasureLevel.nominal),
    ];
    final cases = <List<Object?>>[
      [1.0, 85.5, 1.0, 'Alice'],
      [2.0, 90.0, 2.0, 'Bo'],
      [999.0, null, 2.0, '长名字符串测试值'],
      [4.0, 78.25, 1.0, null],
    ];
    final ds = Dataset(name: 'rt', variables: vars, cases: cases);

    final bytes = SavWriter.writeBytes(ds, fileLabel: 'round trip');
    final back = SavReader.readBytes(bytes).dataset;

    expect(back.nVars, 4);
    expect(back.nCases, 4);

    final id = back.variables.firstWhere((v) => v.name == 'id');
    expect(id.label, 'ID');
    expect(id.missingValues, contains(999));

    final score = back.columnByName('score');
    expect(score[0] as double, closeTo(85.5, 1e-9));
    expect(score[3] as double, closeTo(78.25, 1e-9));

    final gender = back.variables.firstWhere((v) => v.name == 'gender');
    expect(gender.valueLabels[1], '男');
    expect(gender.valueLabels[2], '女');

    final name = back.columnByName('name');
    expect((name[0] as String).trim(), 'Alice');
    expect((name[1] as String).trim(), 'Bo');

    // id=999 is a declared missing value → reader marks cell as missing (null)
    final idCol = back.columnByName('id');
    expect(idCol[1] as double, 2.0);
  });

  test('sav writer produces PSPP-readable header fields', () {
    final ds = Dataset.demoScores();
    final bytes = SavWriter.writeBytes(ds);
    expect(bytes.length, greaterThan(176));
    expect(String.fromCharCodes(bytes.sublist(0, 4)), r'$FL2');
    final bd = ByteData.sublistView(bytes);
    expect(bd.getInt32(64, Endian.little), 2); // layout
    expect(bd.getInt32(72, Endian.little), 0); // uncompressed
    expect(bd.getInt32(80, Endian.little), ds.nCases);
  });

  test('sav file write/read on disk', () {
    final ds = Dataset.demoScores();
    final tmp = Directory.systemTemp.createTempSync('savtest');
    final path = '${tmp.path}${Platform.pathSeparator}out.sav';
    SavWriter.write(ds, path, fileLabel: 'demo');
    final f = File(path);
    expect(f.existsSync(), isTrue);
    final back = SavReader.readBytes(f.readAsBytesSync()).dataset;
    expect(back.nCases, ds.nCases);
    expect(back.nVars, ds.nVars);
    tmp.deleteSync(recursive: true);
  });

  test('syntax SAVE OUTFILE via saver callback', () {
    final ds = Dataset.demoScores();
    String? savedPath;
    Dataset? saved;
    final results = SyntaxExecutor.run(
      "SAVE OUTFILE='out.sav'.",
      ds,
      saver: (p, d) {
        savedPath = p;
        saved = d;
        return true;
      },
    );
    expect(results.last.ok, isTrue);
    expect(savedPath, 'out.sav');
    expect(saved!.nCases, ds.nCases);
  });

  test('syntax SAVE without saver reports unavailable', () {
    final results = SyntaxExecutor.run("SAVE OUTFILE='out.sav'.",
        Dataset.demoScores());
    expect(results.last.ok, isFalse);
  });

  test('syntax SPLIT FILE BY / OFF sets dataset.splitVariable', () {
    final ds = Dataset.demoScores();
    final r1 = SyntaxExecutor.run('SPLIT FILE BY gender.', ds);
    expect(r1.last.ok, isTrue);
    expect(ds.splitVariable, 'gender');
    final r2 = SyntaxExecutor.run('SPLIT FILE OFF.', ds);
    expect(r2.last.ok, isTrue);
    expect(ds.splitVariable, isNull);
  });

  test('syntax SPLIT FILE unknown variable errors', () {
    final ds = Dataset.demoScores();
    final r = SyntaxExecutor.run('SPLIT FILE BY nosuch.', ds);
    expect(r.last.ok, isFalse);
    expect(ds.splitVariable, isNull);
  });

  test('long variable names round-trip via 7/13 record', () {
    final vars = [
      Variable(name: 'aVeryLongVariableName', decimals: 0),
      Variable(name: 'x'),
    ];
    final ds = Dataset(
      name: 'ln',
      variables: vars,
      cases: [
        [1.0, 2.0],
        [3.0, 4.0],
      ],
    );
    final back = SavWriter.writeBytes(ds);
    final rd = SavReader.readBytes(back).dataset;
    expect(rd.variables.map((v) => v.name), contains('aVeryLongVariableName'));
  });
}
