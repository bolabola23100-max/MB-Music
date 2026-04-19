import 'package:flutter/material.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:easy_localization/easy_localization.dart';

class PlaylistOptionsBottomSheet extends StatelessWidget {
  final PlaylistSong song;
  final int playlistId;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const PlaylistOptionsBottomSheet({
    super.key,
    required this.song,
    required this.playlistId,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            song.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            song.artist,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.play_circle, color: Colors.greenAccent),
            title: Text(
              "common.play".tr(),
              style: const TextStyle(color: Colors.white),
            ),
            onTap: onPlay,
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle, color: Colors.redAccent),
            title: Text(
              "playlist_options.remove_from_list".tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
