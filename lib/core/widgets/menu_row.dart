import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';

class MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color colors;
  const MenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.blue,
    this.colors = AppColors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.all(8),
        height: 50,
        width: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: color,
        ),

        child: Row(
          children: [
            Icon(icon, color: colors, size: 20),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: colors, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
