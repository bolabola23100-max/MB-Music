import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';

Widget buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsetsDirectional.only(start: 6, bottom: 12, top: 4),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.blue,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    ),
  );
}
