import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:music/core/services/playlist/playlist_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlaylistDialogs {
  static final PlaylistService _playlistService = PlaylistService();

  static void showCreateDialog(
    BuildContext context,
    void Function(int id) onCreated,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "playlist_dialogs.create_title".tr(),
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.white),
          decoration: InputDecoration(
            hintText: "playlist_dialogs.enter_name".tr(),
            hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "common.cancel".tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final id = await _playlistService.createPlaylist(
                  controller.text.trim(),
                );
                Navigator.pop(context);
                onCreated(id);
              }
            },
            child: Text("common.create".tr()),
          ),
        ],
      ),
    );
  }

  static void showRenameDialog(
    BuildContext context,
    PlaylistModels playlist,
    VoidCallback onRenamed,
  ) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "playlist_dialogs.rename_title".tr(),
          style: const TextStyle(color: AppColors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.white),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.black26,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("common.cancel".tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              await _playlistService.renamePlaylist(
                playlist.id!,
                controller.text.trim(),
              );
              Navigator.pop(context);
              onRenamed();
            },
            child: Text("common.save".tr()),
          ),
        ],
      ),
    );
  }

  static void showDeleteDialog(
    BuildContext context,
    PlaylistModels playlist,
    VoidCallback onDeleted,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: Text(
          "playlist_dialogs.delete_title".tr(),
          style: const TextStyle(color: AppColors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("common.cancel".tr()),
          ),
          TextButton(
            onPressed: () async {
              await _playlistService.deletePlaylist(playlist.id!);
              Navigator.pop(context);
              onDeleted();
            },
            child: Text(
              "options.delete".tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  static void showAddSongsDialog(
    BuildContext context,
    int playlistId,
    List<SongModel> allSongs,
    VoidCallback onDone,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.gray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => _AddSongsView(
        playlistId: playlistId,
        allSongs: allSongs,
        onDone: onDone,
      ),
    );
  }
}

class _AddSongsView extends StatefulWidget {
  final int playlistId;
  final List<SongModel> allSongs;
  final VoidCallback onDone;

  const _AddSongsView({
    required this.playlistId,
    required this.allSongs,
    required this.onDone,
  });

  @override
  State<_AddSongsView> createState() => _AddSongsViewState();
}

class _AddSongsViewState extends State<_AddSongsView> {
  final Set<int> _selectedIds = {};
  final PlaylistService _service = PlaylistService();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "options.add_to_playlist".tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isSaving)
                const CircularProgressIndicator(color: AppColors.blue)
              else if (_selectedIds.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    setState(() => _isSaving = true);
                    for (var id in _selectedIds) {
                      final song = widget.allSongs.firstWhere(
                        (s) => s.id == id,
                      );
                      await _service.addSongToPlaylist(widget.playlistId, song);
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      widget.onDone();
                    }
                  },
                  child: Text(
                    "common.save".tr(),
                    style: const TextStyle(color: AppColors.blue, fontSize: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              itemCount: widget.allSongs.length,
              itemBuilder: (context, index) {
                final song = widget.allSongs[index];
                final isSelected = _selectedIds.contains(song.id);
                return CheckboxListTile(
                  value: isSelected,
                  controlAffinity: ListTileControlAffinity.trailing,
                  secondary: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    song.artist ?? "Unknown",
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  activeColor: AppColors.blue,
                  checkColor: Colors.black,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedIds.add(song.id);
                      } else {
                        _selectedIds.remove(song.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
