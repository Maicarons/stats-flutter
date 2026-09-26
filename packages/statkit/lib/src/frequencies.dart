/// 频率表与直方图分箱
library;

import 'dart:math' as math;

import 'descriptives.dart';

class FrequencyRow {
  final String label;
  final double value;
  final int frequency;
  final double percent;
  final double validPercent;
  final double cumulativePercent;
  const FrequencyRow({
    required this.label,
    required this.value,
    required this.frequency,
    required this.percent,
    required this.validPercent,
    required this.cumulativePercent,
  });
}

class FrequencyTable {
  final List<FrequencyRow> rows;
  final int nValid;
  final int nMissing;
  final int nTotal;
  final String variableName;

  const FrequencyTable({
    required this.rows,
    required this.nValid,
    required this.nMissing,
    required this.nTotal,
    required this.variableName,
  });
}

class HistogramBin {
  final double start;
  final double end;
  final int count;
  const HistogramBin({required this.start, required this.end, required this.count});
  double get midpoint => (start + end) / 2;
}

class Frequencies {
  static FrequencyTable compute(
    List<Object?> raw, {
    required String variableName,
    Map<num, String>? valueLabels,
    bool Function(Object?)? isMissing,
  }) {
    final miss = isMissing ??
        (v) => v == null || (v is String && v.trim().isEmpty);
    final counts = <Object?, int>{};
    var nMissing = 0;
    for (final v in raw) {
      if (miss(v)) {
        nMissing++;
        continue;
      }
      counts[v] = (counts[v] ?? 0) + 1;
    }
    final nValid = raw.length - nMissing;
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final ka = a.key;
        final kb = b.key;
        if (ka is num && kb is num) return ka.compareTo(kb);
        return ka.toString().compareTo(kb.toString());
      });

    double cum = 0;
    final rows = <FrequencyRow>[];
    for (final e in entries) {
      final pct = raw.isEmpty ? 0.0 : e.value / raw.length * 100;
      final vpct = nValid == 0 ? 0.0 : e.value / nValid * 100;
      cum += vpct;
      final String label;
      if (e.key is num &&
          valueLabels != null &&
          valueLabels.containsKey(e.key)) {
        label = valueLabels[e.key as num]!;
      } else {
        label = e.key.toString();
      }
      rows.add(FrequencyRow(
        label: label,
        value: e.key is num ? (e.key as num).toDouble() : rows.length.toDouble(),
        frequency: e.value,
        percent: pct,
        validPercent: vpct,
        cumulativePercent: cum,
      ));
    }

    return FrequencyTable(
      rows: rows,
      nValid: nValid,
      nMissing: nMissing,
      nTotal: raw.length,
      variableName: variableName,
    );
  }

  /// 直方图分箱（Sturges / Freedman-Diaconis）
  static List<HistogramBin> histogramBins(
    List<double> values, {
    int? bins,
  }) {
    if (values.isEmpty) return [];
    final sorted = List.of(values)..sort();
    final d = Descriptives.compute(sorted);
    final n = d.n;
    int k;
    if (bins != null && bins > 0) {
      k = bins;
    } else {
      final sturges = (math.log(n) / math.ln2 + 1).ceil();
      final iqr = d.iqr;
      double fd = 0;
      if (iqr > 0) {
        fd = (2 * iqr / math.pow(n, 1 / 3)).toDouble();
        if (fd < 1) fd = 1;
      }
      k = fd > 0
          ? fd.round().clamp(3, 40)
          : sturges.clamp(3, 40);
    }
    final range = d.range <= 0 ? 1.0 : d.range;
    final width = range / k;
    final counts = List.filled(k, 0);
    for (final v in sorted) {
      var idx = ((v - d.min) / width).floor();
      if (idx >= k) idx = k - 1;
      if (idx < 0) idx = 0;
      counts[idx]++;
    }
    return List.generate(
      k,
      (i) => HistogramBin(
        start: d.min + i * width,
        end: d.min + (i + 1) * width,
        count: counts[i],
      ),
    );
  }
}
