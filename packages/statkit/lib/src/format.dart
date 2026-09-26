/// 数值格式化
library;

/// 格式化 p 值（APA 风格）
String formatP(double p) {
  if (p.isNaN) return '—';
  if (p.isInfinite) return '—';
  if (p < 0.001) return '<.001';
  final s = p.toStringAsFixed(3);
  return s.startsWith('0.') ? '.${s.substring(2)}' : s;
}

/// 格式化数值
String formatNum(double v, {int digits = 3}) {
  if (v.isNaN) return '—';
  if (v.isInfinite) return v > 0 ? '∞' : '−∞';
  if (v == v.roundToDouble() && v.abs() < 1e15 && digits == 0) {
    return v.toInt().toString();
  }
  if (v.abs() >= 1e6 || (v != 0 && v.abs() < 1e-4)) {
    return v.toStringAsExponential(2);
  }
  return v.toStringAsFixed(digits);
}

/// 显著性星号
String significanceStars(double p) {
  if (p.isNaN) return '';
  if (p < 0.001) return '***';
  if (p < 0.01) return '**';
  if (p < 0.05) return '*';
  return '';
}
