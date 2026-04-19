import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/features/home/widgets/music_waveform.dart';

class AppSeekBar extends StatefulWidget {
  final AudioService audioService;
  final double maxWidth;
  final bool isT;
  const AppSeekBar({
    super.key,
    required this.audioService,
    this.maxWidth = 60,
    this.isT = false,
  });

  @override
  State<AppSeekBar> createState() => _AppSeekBarState();
}

class _AppSeekBarState extends State<AppSeekBar>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  double _progress = 0;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(_onTick)..start();

    widget.audioService.positionStream.listen((position) {
      final duration = widget.audioService.duration ?? Duration.zero;

      if (duration.inMilliseconds > 0) {
        _duration = duration;
        _progress = position.inMilliseconds / duration.inMilliseconds;
      }
    });
  }

  void _onTick(Duration elapsed) {
    if (_duration.inMilliseconds == 0) return;

    final isPlaying = widget.audioService.isPlaying;

    if (isPlaying) {
      setState(() {
        _progress += (1 / _duration.inMilliseconds) * 16; // تقريبًا 60fps
        _progress = _progress.clamp(0.0, 1.0);
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = Duration(
      milliseconds: (_progress * _duration.inMilliseconds).toInt(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          MusicWaveform(
            maxWidth: widget.maxWidth,
            progress: _progress,
            onSeek: (value) {
              final seekPosition = Duration(
                milliseconds: (value * _duration.inMilliseconds).toInt(),
              );

              widget.audioService.seek(seekPosition);

              setState(() {
                _progress = value;
              });
            },
          ),
          const SizedBox(height: 8),
          if (widget.isT)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position)),
                Text(_formatDuration(_duration)),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
