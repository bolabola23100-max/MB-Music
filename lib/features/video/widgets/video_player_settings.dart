import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class VideoPlayerSettings {
  static Future<void> showVolume(
    BuildContext context,
    Player player,
    VoidCallback onChanged,
  ) async {
    var value = player.state.volume.clamp(0.0, 100.0).toDouble();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      showDragHandle: true,
      builder: (context) => _SliderSheet(
        icon: Icons.volume_up_rounded,
        title: 'Volume',
        value: value,
        min: 0,
        max: 100,
        suffix: '%',
        onChanged: (next) {
          value = next;
          player.setVolume(next);
          onChanged();
        },
      ),
    );
  }

  static Future<void> showBrightness(
    BuildContext context,
    double brightness,
    ValueChanged<double> onChanged,
  ) async {
    var value = brightness;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      showDragHandle: true,
      builder: (context) => _SliderSheet(
        icon: Icons.brightness_6_rounded,
        title: 'Brightness',
        value: value,
        min: 0.05,
        max: 1,
        suffix: '%',
        displayValue: (value * 100).round().toString(),
        onChanged: (next) {
          value = next;
          onChanged(next);
        },
      ),
    );
  }

  static Future<void> showSpeed(
    BuildContext context,
    Player player,
  ) async {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final current = player.state.rate;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetTitle(title: 'Playback speed'),
              const SizedBox(height: 8),
              ...speeds.map(
                (speed) => ListTile(
                  leading: Icon(
                    speed == current
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: Colors.white,
                  ),
                  title: Text(
                    speed == 1 ? 'Normal' : '${speed}x',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    await player.setRate(speed);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> showAspect(
    BuildContext context,
    double? currentRatio,
    BoxFit currentFit,
    ValueChanged<({double? ratio, BoxFit fit})> onSelected,
  ) async {
    const options = [
      ('Original', null, BoxFit.contain),
      ('16:9', 16 / 9, BoxFit.contain),
      ('4:3', 4 / 3, BoxFit.contain),
      ('Fill screen', null, BoxFit.cover),
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: _SheetTitle(title: 'Aspect ratio'),
            ),
            ...options.map(
              (option) => ListTile(
                leading: Icon(
                  currentRatio == option.$2 && currentFit == option.$3
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: Colors.white,
                ),
                title: Text(
                  option.$1,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  onSelected((ratio: option.$2, fit: option.$3));
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SliderSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final String? displayValue;
  final ValueChanged<double> onChanged;

  const _SliderSheet({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Slider(
                value: value,
                min: min,
                max: max,
                onChanged: (next) {
                  setState(() {});
                  onChanged(next);
                },
              ),
              Text(
                displayValue ?? '${value.round()}$suffix',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final String title;

  const _SheetTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Playback speed',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
