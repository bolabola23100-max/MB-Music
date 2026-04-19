import 'package:flutter/material.dart';
import 'package:music/features/home/widgets/custom_painter.dart';

class MusicWaveform extends StatelessWidget {
  final double progress;
  final Function(double) onSeek;
  final double maxWidth;
  final bool isT;

  const MusicWaveform({
    super.key,
    required this.progress,
    required this.onSeek,
    this.maxWidth = 60,
    this.isT = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                double newProgress =
                    details.localPosition.dx / constraints.maxWidth;
                newProgress = newProgress.clamp(0.0, 1.0);
                onSeek(newProgress);
              },
              onTapDown: (details) {
                double newProgress =
                    details.localPosition.dx / constraints.maxWidth;
                newProgress = newProgress.clamp(0.0, 1.0);
                onSeek(newProgress);
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 120),
                curve: Curves.linear,
                builder: (context, animatedValue, _) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, maxWidth),

                    painter: PremiumWavePainter(progress: animatedValue),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
