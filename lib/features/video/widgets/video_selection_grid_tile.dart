import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/features/video/widgets/video_thumbnail.dart';

class VideoSelectionGridTile extends StatelessWidget {
  final AssetEntity video;
  final bool selected;
  final VoidCallback onTap;
  final bool showTitle;

  const VideoSelectionGridTile({
    super.key,
    required this.video,
    required this.selected,
    required this.onTap,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoThumbnail(
            asset: video,
            width: double.infinity,
            height: double.infinity,
          ),
          if (selected)
            Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.blue, width: 3),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.blue : Colors.white,
              size: 28,
            ),
          ),
          if (showTitle)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: FutureBuilder<String>(
                future: video.titleAsync,
                builder: (context, snapshot) => Text(
                  snapshot.data ?? 'Video',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
