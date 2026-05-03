import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:easy_localization/easy_localization.dart';

class SleepTimerWidget extends StatefulWidget {
  final AudioService audioService;

  const SleepTimerWidget({super.key, required this.audioService});

  @override
  State<SleepTimerWidget> createState() => _SleepTimerWidgetState();
}

class _SleepTimerWidgetState extends State<SleepTimerWidget> {
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Widget _timerOption(int minutes) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined, color: AppColors.blue),
      title: Text(
        "common.minutes_count".tr(args: [minutes.toString()]),
        style: const TextStyle(color: AppColors.white),
      ),
      onTap: () {
        Navigator.pop(context);
        widget.audioService.setSleepTimer(Duration(minutes: minutes));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "sleep_timer_status".tr(args: [minutes.toString()]),
            ),
            backgroundColor: AppColors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  void showTimerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "settings.sleep_timer".tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _timerOption(5),
                    _timerOption(10),
                    _timerOption(15),
                    _timerOption(20),
                    _timerOption(30),
                    _timerOption(45),
                    _timerOption(60),
                    _timerOption(90),
                    const Divider(color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.timer_off, color: Colors.red),
                      title: Text(
                        "settings.off".tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.audioService.stopSleepTimer();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(
            Icons.timer_outlined,
            color: AppColors.white,
            size: 28,
          ),
          onPressed: showTimerOptions,
        ),
        ValueListenableBuilder<Duration?>(
          valueListenable: widget.audioService.sleepTimerRemainingNotifier,
          builder: (context, remaining, child) {
            if (remaining == null) return const SizedBox.shrink();
            return Text(
              _formatDuration(remaining),
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ],
    );
  }
}
