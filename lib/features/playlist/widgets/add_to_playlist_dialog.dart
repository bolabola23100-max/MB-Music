import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/playlist/playlist_service.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;
import 'package:easy_localization/easy_localization.dart';

class AddToPlaylistDialog extends StatefulWidget {
  final List<SongModel> songs;

  const AddToPlaylistDialog({super.key, required this.songs});

  @override
  State<AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<AddToPlaylistDialog> {
  final PlaylistService _service = PlaylistService();
  List<PlaylistModels> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    _playlists = await _service.getPlaylists();
    setState(() => _isLoading = false);
  }

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "playlist_dialogs.new_playlist".tr(),
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "playlist_dialogs.playlist_name_hint".tr(),
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFF3A3A3A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.blue, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "common.cancel".tr(),
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final playlistId = await _service.createPlaylist(
                  controller.text.trim(),
                );
                Navigator.pop(context);

                if (playlistId > 0) {
                  final addedCount = await _service.addSongsToPlaylist(
                    playlistId,
                    widget.songs,
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "playlist_dialogs.create_and_add_success".tr(args: [
                          controller.text,
                          addedCount.toString(),
                        ]),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text("playlist_options.create_and_add".tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "playlist_dialogs.add_to_playlist".tr(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.blue),
              ),
            )
          : SizedBox(
              width: double.maxFinite,
              height: 350,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.add, color: AppColors.blue),
                      title: Text(
                        "playlist_dialogs.new_playlist".tr(),
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: _showCreatePlaylistDialog,
                    ),
                  ),
                  if (_playlists.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.queue_music,
                              size: 60,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "no_playlists".tr(),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "playlist_dialogs.no_playlists_hint".tr(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = _playlists[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.queue_music,
                                  color: AppColors.blue,
                                ),
                              ),
                              title: Text(
                                playlist.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                "playlist_dialogs.song_count".tr(
                                  args: [playlist.songCount.toString()],
                                ),
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                              onTap: () async {
                                final addedCount =
                                    await _service.addSongsToPlaylist(
                                  playlist.id!,
                                  widget.songs,
                                );
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      addedCount > 0
                                          ? "playlist_dialogs.added_items".tr(
                                              args: [
                                                addedCount.toString(),
                                                playlist.name
                                              ],
                                            )
                                          : "playlist_dialogs.items_already_exist"
                                              .tr(),
                                    ),
                                    backgroundColor: addedCount > 0
                                        ? AppColors.blue
                                        : Colors.orange,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "common.cancel".tr(),
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ],
    );
  }
}
