import 'dart:math';
import 'package:flutter/material.dart';

class PremiumWavePainter extends CustomPainter {
  final double progress;

  PremiumWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const barsCount = 45;
    final barWidth = size.width / barsCount;
    final centerY = size.height / 2;

    final random = Random(4);

    final heights = List.generate(
      barsCount,
      (_) => size.height * (0.2 + random.nextDouble() * 0.8),
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final gradient = const LinearGradient(
      colors: [Color(0xff00FFA3), Color(0xff00C2FF)],
    );

    for (int i = 0; i < barsCount; i++) {
      final x = i * barWidth + barWidth / 2;

      final barStart = i / barsCount;
      final barEnd = (i + 1) / barsCount;

      double fillPercent = 0;

      if (progress >= barEnd) {
        fillPercent = 1;
      } else if (progress > barStart) {
        fillPercent = (progress - barStart) / (barEnd - barStart);
      }

      final fullHeight = heights[i];
      final filledHeight = fullHeight * fillPercent;

      /// inactive
      final inactivePaint = Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..strokeWidth = barWidth * 0.45
        ..strokeCap = StrokeCap.round;

      /// glow
      final glowPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..strokeWidth = barWidth * 0.8
        ..strokeCap = StrokeCap.round;

      /// active
      final activePaint = Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = barWidth * 0.55
        ..strokeCap = StrokeCap.round;

      /// draw inactive
      canvas.drawLine(
        Offset(x, centerY - fullHeight / 2),
        Offset(x, centerY + fullHeight / 2),
        inactivePaint,
      );

      /// draw glow
      canvas.drawLine(
        Offset(x, centerY - fullHeight / 2),
        Offset(x, centerY - fullHeight / 2 + filledHeight),
        glowPaint,
      );

      /// draw active
      canvas.drawLine(
        Offset(x, centerY - fullHeight / 2),
        Offset(x, centerY - fullHeight / 2 + filledHeight),
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PremiumWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
