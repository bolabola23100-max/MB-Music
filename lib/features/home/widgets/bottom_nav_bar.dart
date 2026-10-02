import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/features/home/widgets/svg_or_image.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isVideoMode;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isVideoMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = isVideoMode
        ? <BottomNavigationBarItem>[
            _buildMaterialNavItem(Icons.video_library_rounded, 'Videos', 0),
            _buildMaterialNavItem(Icons.video_collection_rounded, 'Albums', 1),
          ]
        : <BottomNavigationBarItem>[
            _buildNavItem(AppIcons.song, 'Home', 0),
            _buildNavItem(AppIcons.sounds, 'sounds', 1),
            _buildNavItem(AppIcons.favorite, 'favorite', 2),
            _buildNavItem(AppIcons.playlist, 'playlist', 3),
            _buildNavItem(AppIcons.search, 'search', 4),
          ];

    final safeIndex = currentIndex.clamp(0, items.length - 1);

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(10),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: AppColors.gray,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.blue,
              unselectedItemColor: AppColors.white,
              currentIndex: safeIndex,
              onTap: onTap,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: items,
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    String icon,
    String label,
    int index,
  ) {
    return BottomNavigationBarItem(
      icon: svgOrImage(
        size: 20,
        icon,
        color: currentIndex == index ? AppColors.blue : AppColors.white,
      ),
      label: label,
    );
  }

  BottomNavigationBarItem _buildMaterialNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        size: 22,
        color: currentIndex == index ? AppColors.blue : AppColors.white,
      ),
      label: label,
    );
  }
}
