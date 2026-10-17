/// v1.5.0 M3.5：`.sps` 编解码（BOM / 非法字节 / 往返）。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/features/syntax/sps_codec.dart';

void main() {
  group('.sps 解码', () {
    test('纯 ASCII 与中文按 UTF-8 读入', () {
      expect(SpsCodec.decode(utf8.encode('LIST.')).text, 'LIST.');
      expect(SpsCodec.decode(utf8.encode('* 说明.\nLIST.')).text, '* 说明.\nLIST.');
      expect(SpsCodec.decode(utf8.encode('LIST.')).hadBom, isFalse);
    });

    test('UTF-8 BOM 被剥离', () {
      final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode('LIST.')];
      final d = SpsCodec.decode(bytes);
      expect(d.hadBom, isTrue);
      expect(d.text, 'LIST.');
    });

    test('非法字节替换为 U+FFFD 而不抛异常', () {
      // 0xFF / 0xFE 不是合法 UTF-8 起始字节
      final d = SpsCodec.decode(<int>[0x4C, 0xFF, 0xFE, 0x2E]);
      expect(d.replaced, isTrue);
      expect(d.text.startsWith('L'), isTrue);
      expect(d.text.endsWith('.'), isTrue);
      expect(d.text.contains('\uFFFD'), isTrue);
    });

    test('CRLF 换行原样保留', () {
      final d = SpsCodec.decode(utf8.encode('LIST.\r\nNOPE.\r\n'));
      expect(d.text, 'LIST.\r\nNOPE.\r\n');
      expect(d.replaced, isFalse);
    });
  });

  group('.sps 往返', () {
    test('编码不带 BOM，且解码回同一文本', () {
      const text = '* 说明.\n'
          'DEFINE !desc(!POSITIONAL !TOKENS(1))\n'
          '  DESCRIPTIVES !1.\n'
          '!ENDDEFINE.\n'
          '!desc pre.\n';
      final bytes = SpsCodec.encode(text);
      expect(bytes.sublist(0, 3), isNot(<int>[0xEF, 0xBB, 0xBF]));
      final back = SpsCodec.decode(bytes);
      expect(back.text, text);
      expect(back.hadBom, isFalse);
      expect(back.replaced, isFalse);
    });

    test('先带 BOM 读入、再写出后不再带 BOM（幂等）', () {
      final first = SpsCodec.decode(<int>[0xEF, 0xBB, 0xBF, ...utf8.encode('LIST.')]);
      final second = SpsCodec.decode(SpsCodec.encode(first.text));
      expect(second.text, 'LIST.');
      expect(second.hadBom, isFalse);
    });
  });
}
