import 'package:music/core/services/song_delete_service.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/dialog/song_edit_dialog.dart';
import 'package:music/features/home/widgets/song_info_dialog.dart';
import 'package:music/features/playlist/widgets/add_to_playlist_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';

class SongOptionsBottomSheet extends StatelessWidget {
  static void show(
    BuildContext context, {
    required SongModel song,
    required int index,
    required AudioService audioService,
    bool Function(SongModel song)? isFavoriteChecker,
    Future<void> Function(SongModel song)? onToggleFavorite,
    bool playlist = true,
    Future<void> Function(List<SongModel> songs)? onDeleteSongs,
    bool isDelete = true,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SongOptionsBottomSheet(
          song: song,
          index: index,
          audioService: audioService,
          isFavoriteChecker: isFavoriteChecker,
          onToggleFavorite: onToggleFavorite,
          playlist: playlist,
          onDeleteSongs: onDeleteSongs,
          isDelete: isDelete,
        );
      },
    );
  }

  final SongModel song;
  final int index;
  final AudioService audioService;
  final bool Function(SongModel song)? isFavoriteChecker;
  final Future<void> Function(SongModel song)? onToggleFavorite;
  final bool playlist;
  final bool isDelete;
  final Future<void> Function(List<SongModel> songs)? onDeleteSongs;

  const SongOptionsBottomSheet({
    super.key,
    required this.song,
    required this.index,
    required this.audioService,
    this.isFavoriteChecker,
    this.onToggleFavorite,
    this.playlist = true,
    this.onDeleteSongs,
    this.isDelete = true,
  });

  Future<void> _playSong() async {
    await audioService.playSong(
      song.data,
      title: song.title,
      artist: song.artist,
      index: index,
      songId: song.id,
    );
  }

  Future<void> _shareSong() async {
    final params = ShareParams(text: song.title, files: [XFile(song.data)]);

    final result = await SharePlus.instance.share(params);

    switch (result.status) {
      case ShareResultStatus.success:
        debugPrint('Song shared successfully');
        break;
      case ShareResultStatus.dismissed:
        debugPrint('Share dismissed');
        break;
      case ShareResultStatus.unavailable:
        debugPrint('Share unavailable');
        break;
    }
  }

  void _showFavoriteSnackBar(BuildContext context, bool isFavorite) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? "options.removed_from_fav".tr(args: [song.title])
              : "options.added_to_fav".tr(args: [song.title]),
        ),
        backgroundColor: isFavorite ? Colors.orange : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFavorite = isFavoriteChecker?.call(song) ?? false;

    return SafeArea(
      child: Wrap(
        children: [
          if (playlist)
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white),
              title: Text(
                "options.add_to_playlist".tr(),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AddToPlaylistDialog(songs: [song]),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.play_arrow, color: Colors.white),
            title: Text(
              "options.play_now".tr(),
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _playSong();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white),
            title: Text(
              "options.song_info".tr(),
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => SongInfoDialog(song: song),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white),
            title: Text(
              'options.edit_song'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => SongEditDialog(song: song),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white),
            title: Text(
              "options.share".tr(),
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _shareSong();
            },
          ),
          if (isDelete)
            ListTile(
              leading: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
              ),
              title: Text(
                isFavorite
                    ? "options.remove_from_favorite".tr()
                    : "options.add_to_favorite".tr(),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);

                if (onToggleFavorite != null) {
                  await onToggleFavorite!(song);
                }

                if (context.mounted) {
                  _showFavoriteSnackBar(context, isFavorite);
                }
              },
            ),
          if (isDelete)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                "options.delete".tr(),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    backgroundColor: AppColors.black,
                    title: Text(
                      "options.delete_confirm_title".tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    content: Text(
                      "options.delete_confirm_content"
                          .tr(args: [song.title]),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: Text("common.cancel".tr()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: Text(
                          "options.delete".tr(),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (ok == true) {
                  final messenger = context.mounted
                      ? ScaffoldMessenger.of(context)
                      : null;

                  if (context.mounted) Navigator.pop(context);

                  final deleteResult = await SongDeleteService.deleteSongs([
                    song.id,
                  ]);

                  if (deleteResult.success) {
                    if (onDeleteSongs != null) {
                      await onDeleteSongs!([song]);
                    }

                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text("options.delete_success".tr()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text("options.delete_failed".tr()),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}
