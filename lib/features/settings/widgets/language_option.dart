import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/features/settings/cubit/settings_cubit.dart';

Widget languageOption(
  BuildContext context,
  String title,
  String languageCode,
  bool isSelected,
  SettingsCubit cubit,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: () async {
        await context.setLocale(Locale(languageCode));
        cubit.updateLanguage(languageCode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blue.withValues(alpha: 0.1)
              : AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.blue.withValues(alpha: 0.5)
                : AppColors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.blue : AppColors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.blue)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
