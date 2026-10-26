/// Stata 数据文件 (.dta) 读取器 — v1.8.0 M3
/// 支持 117 / 118 / 119（XML 标签布局）：
/// 变量名、变量标签、数值型（byte/int16/int32/float/double，含大小端）
/// 与定长字符串；数值超出 Stata 数据上限按缺失处理（. … .z 口径）。
/// 限制：strL 长字符串读为空；值标签（value_labels 段）暂不读取。
/// 旧格式（≤115 经典二进制布局）不支持。
library;

import 'dart:convert';
import 'dart:typed_data';

import '../models/dataset.dart';

class DtaException implements Exception {
  final String message;
  DtaException(this.message);
  @override
  String toString() => 'DtaException: $message';
}

class DtaReader {
  static Dataset readBytes(Uint8List bytes, {String name = 'dta'}) {
    final magic = '<stata_dta>';
    if (bytes.length < magic.length ||
        latin1.decode(bytes.sublist(0, magic.length), allowInvalid: true) !=
            magic) {
      throw DtaException('not a Stata 117/118/119 .dta file');
    }
    final text = latin1.decode(bytes, allowInvalid: true);

    String tag(String t) {
      final open = '<$t>';
      final close = '</$t>';
      final i = text.indexOf(open);
      if (i < 0) throw DtaException('missing <$t> section');
      return text.substring(i + open.length, text.indexOf(close, i));
    }

    int tagOffset(String t) => text.indexOf('<$t>') + t.length + 2;

    final release = int.parse(tag('release'));
    if (release != 117 && release != 118 && release != 119) {
      throw DtaException('unsupported .dta release $release (need 117/118/119)');
    }
    final littleEndian = tag('byteorder') == 'LSF';
    final bd = ByteData.sublistView(bytes);

    int u16(int off) => bd.getUint16(off, littleEndian ? Endian.little : Endian.big);
    int i32(int off) => bd.getInt32(off, littleEndian ? Endian.little : Endian.big);
    int i64(int off) => bd.getInt64(off, littleEndian ? Endian.little : Endian.big);

    final kOff = tagOffset('K');
    final k = u16(kOff);
    if (k <= 0) throw DtaException('no variables');
    final nOff = tagOffset('N');
    final n = release == 117 ? i32(nOff) : i64(nOff);

    // variable types: 2 bytes each
    final typesOff = tagOffset('variable_types');
    final types = [for (var i = 0; i < k; i++) u16(typesOff + 2 * i)];

    // varnames: 129 bytes each (118/119) / 33 (117), null-padded UTF-8
    final nameW = release == 117 ? 33 : 129;
    final namesOff = tagOffset('varnames');
    final names = <String>[];
    for (var i = 0; i < k; i++) {
      final raw = bytes.sublist(
          namesOff + i * nameW, namesOff + (i + 1) * nameW);
      names.add(_utf8z(raw));
    }

    // varlabels: 321 bytes each (118/119) / 81 (117), null-padded
    final labelW = release == 117 ? 81 : 321;
    final labelsOff = tagOffset('varlabels');
    final labels = <String>[];
    for (var i = 0; i < k; i++) {
      final raw = bytes.sublist(
          labelsOff + i * labelW, labelsOff + (i + 1) * labelW);
      labels.add(_utf8z(raw));
    }

    // data: sequential byte-aligned records
    final dataOff = tagOffset('data');
    final vars = <Variable>[];
    final widths = <int>[];
    for (var i = 0; i < k; i++) {
      final t = types[i];
      if (t >= 1 && t <= 2045) {
        vars.add(Variable(
            name: names[i],
            label: labels[i],
            type: VarType.string,
            measure: MeasureLevel.nominal));
        widths.add(t);
      } else if (t == 32768) {
        // strL：读取为空（限制）
        vars.add(Variable(
            name: names[i],
            label: labels[i],
            type: VarType.string,
            measure: MeasureLevel.nominal));
        widths.add(8);
      } else {
        vars.add(Variable(
          name: names[i],
          label: labels[i],
          type: VarType.numeric,
          measure: MeasureLevel.scale,
          decimals: t == 65526 || t == 65527 ? 2 : 0,
        ));
        widths.add(switch (t) {
          65530 => 1,
          65529 => 2,
          65528 => 4,
          65527 => 4,
          65526 => 8,
          _ => throw DtaException('unknown variable type $t for ${names[i]}'),
        });
      }
    }

    final cases = <List<Object?>>[];
    var off = dataOff;
    for (var r = 0; r < n && off + widths.fold<int>(0, (a, b) => a + b) <= bytes.length; r++) {
      final row = <Object?>[];
      for (var i = 0; i < k; i++) {
        final t = types[i];
        final w = widths[i];
        if (t >= 1 && t <= 2045) {
          final s = _utf8z(bytes.sublist(off, off + w));
          row.add(s.isEmpty ? null : s);
          off += w;
        } else if (t == 32768) {
          row.add(null); // strL 暂不读取
          off += w;
        } else {
          row.add(_numeric(bytes, off, t, littleEndian));
          off += w;
        }
      }
      cases.add(row);
    }

    return Dataset(name: name, variables: vars, cases: cases);
  }

  static String _utf8z(Uint8List raw) {
    var end = raw.length;
    for (var i = 0; i < raw.length; i++) {
      if (raw[i] == 0) {
        end = i;
        break;
      }
    }
    if (end == 0) return '';
    return utf8.decode(raw.sublist(0, end), allowMalformed: true).trim();
  }

  /// 数值读取；超出 Stata 数据上限的值按缺失（null）处理：
  /// byte ≥ 101，int16 ≥ 32741，int32 ≥ 2147483621，
  /// float ≥ 1.6885e38，double ≥ 8.9885e307（. … .z 区段）。
  static Object? _numeric(
      Uint8List bytes, int off, int type, bool littleEndian) {
    final endian = littleEndian ? Endian.little : Endian.big;
    final bd = ByteData.sublistView(bytes);
    switch (type) {
      case 65530: // int8
        final v = bytes[off];
        return v >= 101 ? null : v.toDouble();
      case 65529: // int16
        final v = bd.getInt16(off, endian);
        return v >= 32741 ? null : v.toDouble();
      case 65528: // int32
        final v = bd.getInt32(off, endian);
        return v >= 2147483621 ? null : v.toDouble();
      case 65527: // float32
        final v = bd.getFloat32(off, endian);
        return v >= 1.6885e38 || v <= -1.6885e38 ? null : v.toDouble();
      case 65526: // float64
        final v = bd.getFloat64(off, endian);
        return v >= 8.988465674311573e307 || v <= -8.988465674311573e307 || v.isNaN
            ? null
            : v;
      default:
        return null;
    }
  }
}

Dataset readDtaBytes(Uint8List bytes, {String name = 'dta'}) =>
    DtaReader.readBytes(bytes, name: name);
