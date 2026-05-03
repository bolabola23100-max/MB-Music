import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/features/settings/cubit/settings_cubit.dart';
import 'package:music/features/settings/widgets/timer_option.dart';

void showSleepTimerDialog(BuildContext context, SettingsCubit cubit) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.black,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.gray.withOpacity(0.5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'settings.sleep_timer'.tr(),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'settings.automatically_stop_playback_after'.tr(),
              style: TextStyle(
                color: AppColors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.6,
              children: [
                timerOption(context, 'settings.off'.tr(), null, cubit),
                timerOption(context, '15m', const Duration(minutes: 15), cubit),
                timerOption(context, '30m', const Duration(minutes: 30), cubit),
                timerOption(context, '45m', const Duration(minutes: 45), cubit),
                timerOption(context, '1h', const Duration(hours: 1), cubit),
                timerOption(context, '2h', const Duration(hours: 2), cubit),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    },
  );
}
