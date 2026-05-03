import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/features/settings/cubit/settings_cubit.dart';
import 'package:music/features/settings/widgets/language_option.dart';

void showLanguageDialog(BuildContext context, SettingsCubit cubit) {
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
              'settings.language'.tr(),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            languageOption(
              context,
              'settings.english'.tr(),
              'en',
              context.locale.languageCode == 'en',
              cubit,
            ),
            languageOption(
              context,
              'settings.arabic'.tr(),
              'ar',
              context.locale.languageCode == 'ar',
              cubit,
            ),
            const SizedBox(height: 32),
          ],
        ),            
      );
    },
  );
}
