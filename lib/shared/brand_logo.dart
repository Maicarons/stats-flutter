/// 统一 Logo 绘制器（开屏 / 关于 / 品牌位）
library;

import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool onPrimary; // true: 画在主题色底上（白底徽章）

  const BrandLogo({
    super.key,
    this.size = 112,
    this.onPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandLogoPainter(onPrimary: onPrimary),
      ),
    );
  }
}

class _BrandLogoPainter extends CustomPainter {
  final bool onPrimary;
  _BrandLogoPainter({required this.onPrimary});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const blue = Color(0xFF2F6FED);
    const cyan = Color(0xFF5CE1E6);

    if (onPrimary) {
      // 白色圆角徽章
      final bg = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(w * 0.24),
      );
      canvas.drawRRect(
        bg,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
    }

    // 画布留白
    final pad = w * 0.16;
    final iw = w - pad * 2;
    final ih = h - pad * 2;
    final ox = pad;
    final oy = pad;

    void bar(double x, double top, Color color) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          ox + x * iw,
          oy + top * ih,
          0.16 * iw,
          (0.88 - top) * ih,
        ),
        Radius.circular(iw * 0.05),
      );
      canvas.drawRRect(r, Paint()..color = color);
    }

    bar(0.12, 0.42, blue);
    bar(0.42, 0.30, blue);
    bar(0.72, 0.18, cyan);

    final path = Path();
    path.moveTo(ox + 0.10 * iw, oy + 0.48 * ih);
    path.cubicTo(
      ox + 0.30 * iw,
      oy + 0.28 * ih,
      ox + 0.55 * iw,
      oy + 0.16 * ih,
      ox + 0.92 * iw,
      oy + 0.12 * ih,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (iw * 0.045).clamp(2.0, 10.0)
        ..strokeCap = StrokeCap.round
        ..color = cyan,
    );
  }

  @override
  bool shouldRepaint(covariant _BrandLogoPainter oldDelegate) =>
      oldDelegate.onPrimary != onPrimary;
}
