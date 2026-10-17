/// `.sps` 文本与字节之间的编解码（v1.5.0 M3.5）。
///
/// 约定：
/// - 读入：接受 UTF-8 BOM 并剥离；非法 UTF-8 字节用 U+FFFD 替换而不是抛异常；
/// - 写出：统一 UTF-8、不写 BOM，换行原样保留（不做 CRLF/LF 转换）。
///
/// 只依赖 `dart:convert`，因此不引入 `dart:io`，可在纯单元测试里往返验证。
library;

import 'dart:convert';

/// 一次解码的结果。
class SpsDecoded {
  const SpsDecoded(this.text, {this.hadBom = false, this.replaced = false});

  final String text;

  /// 输入以 UTF-8 BOM 开头（已剥离）。
  final bool hadBom;

  /// 输入含非法 UTF-8 字节（已替换为 U+FFFD）。
  final bool replaced;
}

/// `.sps` 编解码。
class SpsCodec {
  const SpsCodec._();

  static const List<int> _bom = <int>[0xEF, 0xBB, 0xBF];

  /// 字节 → 文本。
  static SpsDecoded decode(List<int> bytes) {
    var hadBom = false;
    var body = bytes;
    if (bytes.length >= 3 &&
        bytes[0] == _bom[0] &&
        bytes[1] == _bom[1] &&
        bytes[2] == _bom[2]) {
      hadBom = true;
      body = bytes.sublist(3);
    }
    try {
      return SpsDecoded(utf8.decode(body), hadBom: hadBom);
    } on FormatException {
      return SpsDecoded(
        utf8.decode(body, allowMalformed: true),
        hadBom: hadBom,
        replaced: true,
      );
    }
  }

  /// 文本 → 字节。
  static List<int> encode(String text) => utf8.encode(text);
}
