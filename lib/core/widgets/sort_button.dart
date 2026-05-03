import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';

class SortButton extends StatelessWidget {
  const SortButton({
    super.key,
    required this.isAscending,
    required this.onPressed,
  });

  final bool isAscending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            RotationTransition(turns: animation, child: child),
        child: SizedBox(
          width: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                key: ValueKey(isAscending),
                color: AppColors.blue,
                size: 20,
              ),
              Text(
                isAscending ? "الأحدث" : "الأقدم",
                style: TextStyle(fontSize: 10, color: AppColors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
