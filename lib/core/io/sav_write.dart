/// SPSS system file (.sav) writer — v1.6.0 M1
/// Writes $FL2 little-endian uncompressed system files: dictionary
/// (variables / value labels / missing values / long names / encoding)
/// plus case data, symmetric to [SavReader] in sav_io.dart.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/dataset.dart';

class SavWriteException implements Exception {
  final String message;
  SavWriteException(this.message);
  @override
  String toString() => 'SavWriteException: $message';
}

class SavWriter {
  /// Encode [ds] as a .sav byte stream.
  ///
  /// Strings longer than 255 chars are truncated (classic system file limit);
  /// value labels are written for numeric variables only (the dataset model
  /// only holds numeric-labelled values); range missing values are written as
  /// an SPSS open range (-2); discrete missings up to 3.
  static Uint8List writeBytes(Dataset ds, {String fileLabel = ''}) {
    final vars = <_WVar>[];
    // Build the write-side dictionary: 8-byte short names + segment layout.
    final usedShort = <String>{};
    for (var i = 0; i < ds.variables.length; i++) {
      final v = ds.variables[i];
      final isNum = v.isNumeric;
      var width = 8;
      if (!isNum) {
        var maxLen = 1;
        for (final row in ds.cases) {
          final cell = i < row.length ? row[i] : null;
          if (cell is String) {
            // .sav string fields are byte-oriented: measure UTF-8 length
            final bl = utf8.encode(cell).length;
            if (bl > maxLen) maxLen = bl;
          }
        }
        width = maxLen.clamp(1, 255);
      }
      final miss = _missingFor(v);
      final short = _shortName(v.name, usedShort);
      final segments = isNum ? 1 : (width + 7) ~/ 8;
      vars.add(_WVar(
        origin: i,
        name: short,
        longName: v.name,
        isNumeric: isNum,
        width: width,
        segments: segments,
        label: v.label,
        missing: miss,
        missingCount: _missingCount(miss, v),
        valueLabels: isNum && v.valueLabels.isNotEmpty
            ? Map.of(v.valueLabels)
            : null,
      ));
    }
    if (vars.isEmpty) throw SavWriteException('dataset has no variables');

    final caseSize =
        vars.fold<int>(0, (acc, v) => acc + v.segments);
    final out = BytesBuilder(copy: true);
    final bd = ByteData(8);

    void i32(int v) {
      bd.setInt32(0, v, Endian.little);
      out.add(bd.buffer.asUint8List(0, 4));
    }

    void f64(double v) {
      bd.setFloat64(0, v, Endian.little);
      out.add(bd.buffer.asUint8List(0, 8));
    }

    void str(String s, int len) {
      final bytes = utf8.encode(s);
      out.add(bytes.length >= len
          ? Uint8List.sublistView(bytes, 0, len)
          : (bytes + List.filled(len - bytes.length, 0x20)));
    }

    // string data fields: same padding rule, UTF-8 byte oriented
    void strField(String s, int len) => str(s, len);

    // ---- header (176 bytes) ----
    str(r'$FL2', 4);
    str('@SPSS Inc. statistics-flutter', 60);
    i32(2); // layout code
    i32(caseSize);
    i32(0); // uncompressed
    i32(_weightIndex(ds, vars));
    i32(ds.cases.length);
    f64(100.0); // compression bias
    str(_creationDate(), 9);
    str(_creationTime(), 8);
    str(fileLabel, 64);
    str('', 3); // padding

    // ---- variable records (type 2) ----
    var recIdx = 0; // 1-based record position incl. string segments
    for (final v in vars) {
      recIdx++;
      v.recordIndex = recIdx;
      i32(2);
      i32(v.isNumeric ? 0 : v.width);
      i32(v.label.isEmpty ? 0 : 1);
      i32(v.missingCount); // negative for open range
      final dec = v.isNumeric
          ? (ds.variables[v.origin].decimals.clamp(0, 16))
          : 0;
      final fmt = (dec << 16) | ((v.isNumeric ? 8 : v.width) << 8) |
          (v.isNumeric ? 5 : 1); // 5 = F, 1 = A
      i32(fmt);
      i32(fmt);
      str(v.name, 8);
      if (v.label.isNotEmpty) {
        final lb = utf8.encode(v.label);
        final take = lb.length > 255 ? lb.sublist(0, 255) : lb;
        i32(take.length);
        out.add(take);
        final pad = (4 - take.length % 4) % 4;
        if (pad > 0) out.add(List.filled(pad, 0x20));
      }
      for (final m in v.missing) {
        f64(m.toDouble());
      }
      // string continuation segments occupy extra record positions
      recIdx += v.segments - 1;
    }

    // ---- value labels (records 3 + 4), numeric vars only ----
    for (final v in vars) {
      final labels = v.valueLabels;
      if (labels == null || labels.isEmpty || v.recordIndex == 0) continue;
      final entries = labels.entries.toList();
      if (entries.isEmpty) continue;
      i32(3);
      i32(entries.length);
      for (final e in entries) {
        f64(e.key.toDouble());
        final lb = utf8.encode(e.value);
        final take = lb.length > 120 ? lb.sublist(0, 120) : lb;
        out.add([take.length]);
        out.add(take);
        final pad = (8 - (take.length + 1) % 8) % 8;
        if (pad > 0) out.add(List.filled(pad, 0x20));
      }
      i32(4);
      i32(1);
      i32(v.recordIndex);
    }

    // ---- long variable names (7/13) when short != long ----
    final longNames = vars
        .where((v) => v.longName != v.name)
        .map((v) => '${v.name}=${v.longName}')
        .join('\t');
    if (longNames.isNotEmpty) {
      final data = utf8.encode(longNames);
      i32(7);
      i32(13);
      i32(1);
      i32(data.length);
      out.add(data);
    }

    // ---- encoding (7/20) ----
    final enc = latin1.encode('UTF-8');
    i32(7);
    i32(20);
    i32(1);
    i32(enc.length);
    out.add(enc);

    // ---- dictionary terminator (999) ----
    i32(999);
    i32(0);

    // ---- data (uncompressed: caseSize 8-byte fields per case) ----
    const sysMissBytes = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F];
    for (final row in ds.cases) {
      for (final v in vars) {
        final cell = v.origin < row.length ? row[v.origin] : null;
        if (v.isNumeric) {
          final isMiss = cell == null ||
              (cell is num &&
                  (ds.variables[v.origin].isMissing(cell) ||
                      (cell is double && !cell.isFinite)));
          if (isMiss) {
            out.add(sysMissBytes);
          } else {
            f64((cell as num).toDouble());
          }
        } else {
          final s = cell == null ? '' : cell.toString();
          strField(s, v.segments * 8);
        }
      }
    }

    return out.toBytes();
  }

  /// Write [ds] to [path] as a .sav system file.
  static void write(Dataset ds, String path, {String fileLabel = ''}) {
    final bytes = writeBytes(ds, fileLabel: fileLabel);
    File(path).writeAsBytesSync(bytes, flush: true);
  }

  static List<double> _missingFor(Variable v) {
    if (!v.isNumeric) return const [];
    if (v.missingRangeLow != null && v.missingRangeHigh != null) {
      // open range; PSPP: nMissing = -2 (low, high)
      return [v.missingRangeLow!.toDouble(), v.missingRangeHigh!.toDouble()];
    }
    final disc = v.missingValues.take(3).map((e) => e.toDouble()).toList();
    return disc;
  }

  /// Missing count sign: negative marks an open range (low, high).
  static int _missingCount(List<double> miss, Variable v) {
    if (miss.length == 2 &&
        v.missingRangeLow != null &&
        v.missingRangeHigh != null) {
      return -2;
    }
    return miss.length;
  }

  static int _weightIndex(Dataset ds, List<_WVar> vars) {
    final w = ds.weightVariable;
    if (w == null || w.isEmpty) return 0;
    for (final v in vars) {
      if (v.isNumeric && v.longName.toLowerCase() == w.toLowerCase()) {
        return v.recordIndex;
      }
    }
    return 0;
  }

  static String _shortName(String name, Set<String> used) {
    var s = name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_]'), '_');
    if (s.isEmpty || RegExp(r'^[0-9]').hasMatch(s)) s = '_$s';
    if (s.length > 8) s = s.substring(0, 8);
    var cand = s;
    var i = 0;
    while (used.contains(cand)) {
      final suffix = (i + 1).toString();
      cand = s.substring(0, 8 - suffix.length) + suffix;
      i++;
      if (i > 99) break;
    }
    used.add(cand);
    return cand;
  }

  static String _creationDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final d = now.day.toString().padLeft(2, ' ');
    final y = (now.year % 100).toString().padLeft(2, '0');
    return '$d ${months[now.month - 1]} $y';
  }

  static String _creationTime() {
    final now = DateTime.now();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(now.hour)}:${p(now.minute)}:${p(now.second)}';
  }
}

class _WVar {
  final int origin;
  final String name;
  final String longName;
  final bool isNumeric;
  final int width;
  final int segments;
  final String label;
  final List<double> missing;
  final int missingCount;
  final Map<num, String>? valueLabels;
  int recordIndex = 0;
  _WVar({
    required this.origin,
    required this.name,
    required this.longName,
    required this.isNumeric,
    required this.width,
    required this.segments,
    required this.label,
    required this.missingCount,
    required this.missing,
    required this.valueLabels,
  });
}
