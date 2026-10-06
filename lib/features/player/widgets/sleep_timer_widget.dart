import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/dialog/my_snack_bar.dart';

class SleepTimerWidget extends StatelessWidget {
  const SleepTimerWidget({super.key, required this.audioService});

  final AudioService audioService;

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _setTimer(BuildContext context, int minutes) {
    Navigator.pop(context);
    audioService.setSleepTimer(Duration(minutes: minutes));
    MySnackBar(context: context).showSnackBar(
      'sleep_timer_status'.tr(args: [minutes.toString()]),
      AppColors.blue,
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'settings.sleep_timer'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final minutes in [5, 10, 15, 20, 30, 45, 60, 90])
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: AppColors.blue),
                title: Text(
                  'common.minutes_count'.tr(args: [minutes.toString()]),
                  style: const TextStyle(color: AppColors.white),
                ),
                onTap: () => _setTimer(context, minutes),
              ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.timer_off, color: Colors.red),
              title: Text('settings.off'.tr(), style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                audioService.stopSleepTimer();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.timer_outlined, color: AppColors.white, size: 28),
          onPressed: () => _showOptions(context),
        ),
        ValueListenableBuilder<Duration?>(
          valueListenable: audioService.sleepTimerRemainingNotifier,
          builder: (_, remaining, __) => remaining == null
              ? const SizedBox.shrink()
              : Text(
                  _format(remaining),
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
