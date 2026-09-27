/// SPSS system file (.sav) reader — v1.1
/// Supports $FL2 little-endian, dictionary, value labels, common compression.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../models/dataset.dart';

class SavException implements Exception {
  final String message;
  SavException(this.message);
  @override
  String toString() => 'SavException: $message';
}

class SavHeader {
  final String productName;
  final int layoutCode;
  final int nominalCaseSize;
  final bool compressed;
  final int ncases;
  final double bias;
  final String fileLabel;
  final String encoding;
  const SavHeader({
    required this.productName,
    required this.layoutCode,
    required this.nominalCaseSize,
    required this.compressed,
    required this.ncases,
    required this.bias,
    required this.fileLabel,
    required this.encoding,
  });
}

class SavFileInfo {
  final SavHeader header;
  final Dataset dataset;
  const SavFileInfo({required this.header, required this.dataset});
}

class SavReader {
  /// 解析 .sav 字节流为 Dataset
  static SavFileInfo readBytes(Uint8List bytes, {String name = 'sav'}) {
    if (bytes.length < 176) throw SavException('file too short');
    final magic = ascii.decode(bytes.sublist(0, 4), allowInvalid: true);
    if (magic != r'$FL2' && magic != r'$FL3') {
      throw SavException('not a SPSS system file (magic=$magic)');
    }
    final bd = ByteData.sublistView(bytes);
    String readStr(int offset, int len) {
      final s = ascii.decode(bytes.sublist(offset, offset + len), allowInvalid: true);
      return s.trim();
    }

    final productName = readStr(4, 60);
    final layout = bd.getInt32(64, Endian.little);
    final nominalCaseSize = bd.getInt32(68, Endian.little);
    final compression = bd.getInt32(72, Endian.little);
    // weightIndex at 76 unused in reader
    final ncases = bd.getInt32(80, Endian.little);
    final bias = bd.getFloat64(84, Endian.little);
    // creationDate at 92
    // creationTime at 101
    final fileLabel = readStr(109, 64);

    final header = SavHeader(
      productName: productName,
      layoutCode: layout,
      nominalCaseSize: nominalCaseSize,
      compressed: compression == 1,
      ncases: ncases,
      bias: bias,
      fileLabel: fileLabel,
      encoding: 'utf-8',
    );

    // Parse records
    var pos = 176;
    final vars = <_SavVar>[];
    final valueLabels = <int, Map<num, String>>{};
    final pendingLabels = <Map<num, String>>[];
    final longNames = <String, String>{}; // short -> long
    var dataStart = -1;

    while (pos + 4 <= bytes.length) {
      final recType = bd.getInt32(pos, Endian.little);
      pos += 4;
      if (recType == 2) {
        // variable record
        if (pos + 28 > bytes.length) break;
        final type = bd.getInt32(pos, Endian.little);
        final hasLabel = bd.getInt32(pos + 4, Endian.little);
        final nMissing = bd.getInt32(pos + 8, Endian.little);
        final printFmt = bd.getInt32(pos + 12, Endian.little);
        final writeFmt = bd.getInt32(pos + 16, Endian.little);
        final name = readStr(pos + 20, 8);
        pos += 28;
        String? label;
        if (hasLabel == 1) {
          final llen = bd.getInt32(pos, Endian.little);
          pos += 4;
          final padded = ((llen + 3) ~/ 4) * 4;
          label = ascii.decode(bytes.sublist(pos, pos + llen), allowInvalid: true).trim();
          pos += padded;
        }
        final miss = <double>[];
        if (nMissing.abs() > 0 && nMissing.abs() <= 3) {
          for (var i = 0; i < nMissing.abs(); i++) {
            miss.add(bd.getFloat64(pos, Endian.little));
            pos += 8;
          }
        }
        vars.add(_SavVar(
          name: name.isEmpty ? 'VAR${vars.length}' : name,
          type: type,
          label: label ?? '',
          printFmt: printFmt,
          writeFmt: writeFmt,
          missing: miss,
          isContinuation: name.startsWith(' ') || type == -1,
        ));
      } else if (recType == 3) {
        // value labels
        if (pos + 4 > bytes.length) break;
        final count = bd.getInt32(pos, Endian.little);
        pos += 4;
        final map = <num, String>{};
        for (var i = 0; i < count; i++) {
          final val = bd.getFloat64(pos, Endian.little);
          pos += 8;
          final len = bytes[pos];
          pos += 1;
          final s = ascii.decode(bytes.sublist(pos, pos + len), allowInvalid: true);
          pos += len;
          final pad = (8 - (len + 1) % 8) % 8;
          pos += pad;
          map[val] = s.trim();
        }
        pendingLabels.add(map);
      } else if (recType == 4) {
        // which vars the labels apply to
        if (pos + 4 > bytes.length) break;
        final count = bd.getInt32(pos, Endian.little);
        pos += 4;
        final idxs = <int>[];
        for (var i = 0; i < count; i++) {
          idxs.add(bd.getInt32(pos, Endian.little));
          pos += 4;
        }
        if (pendingLabels.isNotEmpty) {
          final m = pendingLabels.removeLast();
          for (final vi in idxs) {
            // var index is 1-based counting continuations
            final map = valueLabels.putIfAbsent(vi, () => {});
            map.addAll(m);
          }
        }
      } else if (recType == 6) {
        // document lines
        final n = bd.getInt32(pos, Endian.little);
        pos += 4 + n * 80;
      } else if (recType == 7) {
        // extension
        if (pos + 8 > bytes.length) break;
        final subtype = bd.getInt32(pos, Endian.little);
        final size = bd.getInt32(pos + 4, Endian.little);
        final count = bd.getInt32(pos + 8, Endian.little);
        pos += 12;
        final dataLen = size * count;
        final data = bytes.sublist(pos, pos + dataLen);
        pos += dataLen;
        if (subtype == 13) {
          // long variable names: short=long\t short2=long2
          final text = ascii.decode(data, allowInvalid: true);
          for (final part in text.split('\t')) {
            final kv = part.split('=');
            if (kv.length == 2) {
              longNames[kv[0].trim().toUpperCase()] = kv[1].trim();
            }
          }
        } else if (subtype == 20) {
          header.encoding.isEmpty;
        } else if (subtype == 7) {
          // ncases64
        }
      } else if (recType == 999) {
        pos += 4; // filler
        dataStart = pos;
        break;
      } else {
        // unknown — try to continue
        break;
      }
    }

    if (dataStart < 0) {
      throw SavException('dictionary terminator not found');
    }

    // Map dictionary variables (skip continuations)
    final dictVars = <_SavVar>[];
    final shortToDictIdx = <int, int>{}; // 1-based var record -> dict idx
    var recIdx = 1;
    for (var i = 0; i < vars.length; i++) {
      final v = vars[i];
      if (v.isContinuation || v.type == -1) {
        // continuation of previous string
        recIdx++;
        continue;
      }
      shortToDictIdx[recIdx] = dictVars.length;
      dictVars.add(v);
      recIdx++;
    }

    final outVars = <Variable>[];
    for (var i = 0; i < dictVars.length; i++) {
      final sv = dictVars[i];
      final isNum = sv.type == 0;
      final long = longNames[sv.name.toUpperCase()] ?? sv.name;
      final measure = isNum ? MeasureLevel.scale : MeasureLevel.nominal;
      outVars.add(Variable(
        name: long,
        label: sv.label,
        type: isNum ? VarType.numeric : VarType.string,
        measure: measure,
        decimals: 2,
      ));
      // missing
      if (sv.missing.isNotEmpty) {
        outVars.last.missingValues.addAll(sv.missing);
      }
    }

    // attach value labels — keys are 1-based dictionary positions
    valueLabels.forEach((varIdx, map) {
      final di = shortToDictIdx[varIdx] ?? (varIdx - 1);
      if (di >= 0 && di < outVars.length) {
        outVars[di].valueLabels.addAll(map);
      }
    });

    // Read data
    final cases = <List<Object?>>[];
    final caseSize = nominalCaseSize;
    if (compression == 1) {
      // bytecode compression
      final biasV = bias == 0 ? 100.0 : bias;
      final buf = <Object?>[];
      var p = dataStart;
      while (p + 8 <= bytes.length && cases.length < (ncases > 0 ? ncases : 1 << 24)) {
        final codes = bytes.sublist(p, p + 8);
        p += 8;
        for (final code in codes) {
          if (code == 0) continue;
          if (code == 252) {
            // uncompressed 8-byte value follows
            if (p + 8 > bytes.length) break;
            if (buf.length < caseSize) {
              buf.add(_readValue(bytes, p, dictVars, buf.length));
            }
            p += 8;
          } else if (code == 253) {
            if (buf.length < caseSize) buf.add(null);
          } else if (code == 254) {
            if (buf.length < caseSize) buf.add(' ');
          } else if (code == 255) {
            if (buf.length < caseSize) buf.add(null);
          } else {
            final v = code - biasV;
            if (buf.length < caseSize) {
              buf.add(dictVars.isNotEmpty &&
                      buf.length < dictVars.length &&
                      !dictVars[buf.length].isNumeric
                  ? v.toString()
                  : v);
            }
          }
          if (buf.length >= caseSize) {
            cases.add(List.of(buf));
            buf.clear();
          }
        }
      }
      if (buf.isNotEmpty && buf.length == caseSize) {
        cases.add(List.of(buf));
      }
    } else {
      // uncompressed
      var p = dataStart;
      while (p + 8 * caseSize <= bytes.length) {
        final row = List<Object?>.filled(caseSize, null);
        for (var i = 0; i < caseSize; i++) {
          row[i] = _readValue(bytes, p + i * 8, dictVars, i);
        }
        cases.add(row);
        p += 8 * caseSize;
        if (ncases > 0 && cases.length >= ncases) break;
      }
    }

    final ds = Dataset(name: name, variables: outVars, cases: cases);
    return SavFileInfo(header: header, dataset: ds);
  }

  static Object? _readValue(Uint8List bytes, int pos, List<_SavVar> dict, int idx) {
    final bd = ByteData.sublistView(bytes);
    final isNum = idx >= dict.length || dict[idx].isNumeric;
    if (isNum) {
      final v = bd.getFloat64(pos, Endian.little);
      // system missing often NaN
      return v.isNaN ? null : v;
    }
    // string: 8-byte field (or multiple for long strings — simplified)
    final s = ascii.decode(bytes.sublist(pos, pos + 8), allowInvalid: true);
    final t = s.trim();
    return t.isEmpty ? null : t;
  }
}

class _SavVar {
  final String name;
  final int type;
  final String label;
  final int printFmt;
  final int writeFmt;
  final List<double> missing;
  final bool isContinuation;
  const _SavVar({
    required this.name,
    required this.type,
    required this.label,
    required this.printFmt,
    required this.writeFmt,
    required this.missing,
    required this.isContinuation,
  });
  bool get isNumeric => type == 0;
}

/// 便捷入口
Dataset readSavBytes(Uint8List bytes, {String name = 'sav'}) =>
    SavReader.readBytes(bytes, name: name).dataset;

SavFileInfo readSavInfo(Uint8List bytes, {String name = 'sav'}) =>
    SavReader.readBytes(bytes, name: name);
