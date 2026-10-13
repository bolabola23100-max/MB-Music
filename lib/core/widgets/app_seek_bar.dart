import 'dart:async';

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
  StreamSubscription<Duration>? _positionSubscription;

  double _progress = 0;
  Duration _duration = Duration.zero;
  bool _audioReady = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      await widget.audioService.ready;
      if (!mounted) return;

      _audioReady = true;
      _duration = widget.audioService.duration ?? Duration.zero;

      _positionSubscription = widget.audioService.positionStream.listen((position) {
        if (!mounted) return;

        final duration = widget.audioService.duration ?? Duration.zero;
        if (duration.inMilliseconds > 0) {
          setState(() {
            _duration = duration;
            _progress =
                (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
          });
        }
      });

      setState(() {});
    } catch (_) {
      // Keep the seek bar in its safe empty state if audio initialization fails.
    }
  }

  void _onTick(Duration elapsed) {
    if (!_audioReady || !mounted || _duration.inMilliseconds == 0) return;

    final isPlaying = widget.audioService.isPlaying;

    if (isPlaying) {
      setState(() {
        _progress += (1 / _duration.inMilliseconds) * 16;
        _progress = _progress.clamp(0.0, 1.0);
      });
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MusicWaveform(
            maxWidth: widget.maxWidth,
            progress: _progress,
            onSeek: (value) {
              if (!_audioReady) return;

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
                Text(
                  _formatDuration(position),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
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
