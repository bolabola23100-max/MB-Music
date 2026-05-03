import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';

Widget buildBadge(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.blue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.blue, fontSize: 12),
    ),
  );
}
