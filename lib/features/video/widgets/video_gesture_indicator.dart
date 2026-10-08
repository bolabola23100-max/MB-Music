import 'package:flutter/material.dart';

class VideoGestureIndicator extends StatelessWidget {
  final bool isVolume;
  final double value;

  const VideoGestureIndicator({
    super.key,
    required this.isVolume,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isVolume ? null : 28,
      right: isVolume ? 28 : null,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 42,
            height: 190,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Icon(
                  isVolume
                      ? (value <= 0
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded)
                      : Icons.brightness_6_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(color: Colors.white24),
                        FractionallySizedBox(
                          widthFactor: 1,
                          heightFactor: value,
                          child: Container(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
