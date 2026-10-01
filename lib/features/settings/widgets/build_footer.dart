import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/constants/app_icons.dart';

Widget buildFooter() {
  return Center(
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gray,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Image.asset(
            AppIcons.logo,
            height: 50,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.music_note_rounded,
              size: 50,
              color: AppColors.blue,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'MB Music Player',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'settings.made_with_love'.tr(),
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 50),
      ],
    ),
  );
}
