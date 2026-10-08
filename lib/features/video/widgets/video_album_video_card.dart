import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:music/features/video/screens/video_player_screen.dart';
import 'package:music/features/video/widgets/video_options_bottom_sheet.dart';
import 'package:music/features/video/widgets/video_thumbnail.dart';

class VideoAlbumVideoCard extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback? onLongPress;

  const VideoAlbumVideoCard({
    super.key,
    required this.asset,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: asset.duration);
    return ValueListenableBuilder<int>(
      valueListenable: VideoOptionsBottomSheet.renameChanges,
      builder: (context, _, _) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(asset: asset)),
        ),
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoThumbnail(
                    asset: asset,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    right: 7,
                    bottom: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 8,
                    top: 8,
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      onPressed: () =>
                          VideoOptionsBottomSheet.show(context, asset: asset),
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            FutureBuilder<String>(
              key: ValueKey(VideoOptionsBottomSheet.renameChanges.value),
              future: asset.titleAsync,
              builder: (context, snapshot) => Text(
                snapshot.data ?? 'Video',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration value) {
    final h = value.inHours;
    final m = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
