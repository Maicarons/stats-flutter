import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/features/output/report_builder.dart';
import 'package:stats_flutter/features/output/report_style.dart';

ReportTable _t(List<String> headers, List<List<String>> rows) =>
    ReportTable(headers: headers, rows: rows);

void main() {
  group('p 值列与数值列判定', () {
    test('表头识别 p / p值 / Sig. / 显著性（大小写不敏感）', () {
      for (final h in ['p', 'P', 'p值', 'Sig.', 'sig', '显著性']) {
        expect(pHeaderRe.hasMatch(h), isTrue, reason: h);
      }
      for (final h in ['Mean', 'SD', 'n', 'Power', '说明']) {
        expect(pHeaderRe.hasMatch(h), isFalse, reason: h);
      }
    });

    test('整列数值 → 右对齐（首列除外，含千分位与百分号）', () {
      final t = _t(
        ['Group', 'n', 'Mean', 'Share'],
        [
          ['A', '12', '78.40', '12.5%'],
          ['B', '1,204', '-3.10', '99%'],
        ],
      );
      final s = ReportTableStyle.of(t);
      expect(s.numericAt(0), isFalse, reason: '首列永远是标签列');
      expect(s.numericAt(1), isTrue);
      expect(s.numericAt(2), isTrue);
      expect(s.numericAt(3), isTrue);
    });

    test('SPSS 风格 p 值（`.023` `<.001`）与科学计数法也算数值列', () {
      final s = ReportTableStyle.of(
        _t(
          ['Group', 'p', 'est'],
          [
            ['A', '.023', '1.2e-05'],
            ['B', '<.001', '3.40'],
          ],
        ),
      );
      expect(isNumericCell('.023'), isTrue);
      expect(isNumericCell('<.001'), isTrue);
      expect(isNumericCell('≤0.05'), isTrue);
      expect(isNumericCell('1.2e-05'), isTrue);
      expect(isNumericCell('−∞'), isFalse);
      expect(isNumericCell('∞'), isFalse);
      expect(s.numericAt(1), isTrue, reason: 'p 值列右对齐');
      expect(s.numericAt(2), isTrue);
    });

    test('尾随星号不影响数值判定（相关系数表右对齐）', () {
      expect(isNumericCell('0.62 **'), isTrue);
      expect(isNumericCell('-0.04'), isTrue);
      expect(isNumericCell('不适用'), isFalse);
    });

    test('列里混入文字 → 不右对齐；空列不算数值列', () {
      final s = ReportTableStyle.of(
        _t(
          ['Group', 'Value', 'Empty'],
          [
            ['A', '12', ''],
            ['B', '不适用', ''],
          ],
        ),
      );
      expect(s.numericAt(1), isFalse);
      expect(s.numericAt(2), isFalse);
    });
  });

  group('p 值解析', () {
    test('普通小数 / 省略前导零 / 千分位', () {
      expect(parseP('.023'), closeTo(0.023, 1e-9));
      expect(parseP('0.412'), closeTo(0.412, 1e-9));
      expect(parseP('1,234'), closeTo(1234, 1e-9));
      expect(parseP('—'), isNull);
      expect(parseP('-'), isNull);
      expect(parseP(''), isNull);
    });

    test('`<x` 取界值一半，作为保守估计', () {
      expect(parseP('<.001'), closeTo(0.0005, 1e-9));
      expect(parseP('≤0.05'), closeTo(0.025, 1e-9));
    });
  });

  group('单元格样式', () {
    final style = ReportTableStyle.of(
      _t(
        ['Group', 'n', 'r', 'p'],
        [
          ['A', '12', '0.62 **', '.023'],
          ['B', '13', '0.71 ***', '<.001'],
          ['C', '11', '-0.04', '.412'],
        ],
      ),
    );

    test('p 值列：由 p 值加星，p 值保留原文本', () {
      final cell = styleBodyCell(style, '.023', 3);
      expect(cell.label, '.023');
      expect(cell.stars, '*');
      expect(cell.p, closeTo(0.023, 1e-9));
      expect(cell.significant, isTrue);

      final strong = styleBodyCell(style, '<.001', 3);
      expect(strong.stars, '***');

      final none = styleBodyCell(style, '.412', 3);
      expect(none.stars, '');
      expect(none.p, closeTo(0.412, 1e-9));
      expect(none.significant, isFalse);
      expect(none.numeric, isTrue);
    });

    test('非 p 值列：拆出单元格自带的尾随星号（如相关系数）', () {
      final cell = styleBodyCell(style, '0.62 **', 2);
      expect(cell.label, '0.62');
      expect(cell.stars, '**');
      expect(cell.p, closeTo(0.005, 1e-9));

      final plain = styleBodyCell(style, '-0.04', 2);
      expect(plain.label, '-0.04');
      expect(plain.stars, '');
      expect(plain.p, isNull);
    });

    test('表头与空单元格不带星号', () {
      final head = styleHeaderCell(style, 'p', 3);
      expect(head.label, 'p');
      expect(head.stars, '');
      expect(head.numeric, isTrue, reason: '表头继承列的对齐属性');

      final empty = styleBodyCell(style, '  ', 3);
      expect(empty.stars, '');
      expect(empty.p, isNull);
    });

    test('星号反推的 p 值只用于配色，与 statkit 阈值一致', () {
      expect(pForStars('***'), lessThan(0.001));
      expect(pForStars('**'), lessThan(0.01));
      expect(pForStars('*'), lessThan(0.05));
    });
  });
}
