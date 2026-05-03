import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/features/settings/cubit/settings_cubit.dart';

Widget timerOption(
  BuildContext context,
  String label,
  Duration? duration,
  SettingsCubit cubit,
) {
  return InkWell(
    onTap: () {
      if (duration == null) {
        cubit.stopSleepTimer();
      } else {
        cubit.setSleepTimer(duration);
      }
      Navigator.pop(context);
    },
    borderRadius: BorderRadius.circular(16),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    ),
  );
}
