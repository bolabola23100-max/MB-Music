import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class VideoThumbnail extends StatelessWidget {
  final AssetEntity asset;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const VideoThumbnail({
    super.key,
    required this.asset,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: FutureBuilder<Uint8List?>(
        future: asset.thumbnailDataWithSize(
          const ThumbnailSize(600, 600),
          quality: 85,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            );
          }
          return Container(
            width: width,
            height: height,
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(Icons.movie_outlined, size: 36),
          );
        },
      ),
    );
  }
}
