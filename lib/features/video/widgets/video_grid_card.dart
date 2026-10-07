import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:music/features/video/widgets/video_options_bottom_sheet.dart';
import 'package:music/features/video/widgets/video_thumbnail.dart';

class VideoGridCard extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showFavoriteIcon;

  const VideoGridCard({
    super.key,
    required this.asset,
    this.onTap,
    this.onLongPress,
    this.showFavoriteIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Positioned.fill(
            child: VideoThumbnail(
              asset: asset,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          if (showFavoriteIcon)
            const Positioned(
              left: 8,
              top: 8,
              child: Icon(Icons.favorite_rounded, color: Colors.redAccent),
            ),
          Positioned(
            right: 2,
            top: 2,
            child: IconButton(
              onPressed: () =>
                  VideoOptionsBottomSheet.show(context, asset: asset),
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: FutureBuilder<String>(
              future: asset.titleAsync,
              builder: (context, snapshot) => Text(
                snapshot.data ?? 'Video',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(blurRadius: 5, color: Colors.black),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
