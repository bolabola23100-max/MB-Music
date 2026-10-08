import 'package:flutter/material.dart';

class VideoOptionsMenu extends StatelessWidget {
  final String title;
  final bool isFavorite;
  final ValueChanged<String> onAction;

  const VideoOptionsMenu({
    super.key,
    required this.title,
    required this.isFavorite,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite ? Colors.redAccent : Colors.white,
              ),
              title: Text(
                isFavorite ? 'Remove from favorites' : 'Add to favorites',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => onAction('favorite'),
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: Colors.white),
              title: const Text('Share video', style: TextStyle(color: Colors.white)),
              onTap: () => onAction('share'),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded, color: Colors.white),
              title: const Text('Add to playlist', style: TextStyle(color: Colors.white)),
              onTap: () => onAction('playlist'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.white),
              title: const Text('Rename video', style: TextStyle(color: Colors.white)),
              onTap: () => onAction('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: Colors.white),
              title: const Text('Video information', style: TextStyle(color: Colors.white)),
              onTap: () => onAction('info'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text(
                'Delete video from device',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () => onAction('delete'),
            ),
          ],
        ),
      ),
    );
  }
}
