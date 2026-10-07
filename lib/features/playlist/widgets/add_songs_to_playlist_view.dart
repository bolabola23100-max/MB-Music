import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/playlist/playlist_service.dart';
import 'package:music/core/widgets/dialog/my_snack_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AddSongsToPlaylistView extends StatefulWidget {
  final int playlistId;
  final List<SongModel> allSongs;
  final VoidCallback onDone;

  const AddSongsToPlaylistView({
    super.key,
    required this.playlistId,
    required this.allSongs,
    required this.onDone,
  });

  @override
  State<AddSongsToPlaylistView> createState() => _AddSongsToPlaylistViewState();
}

class _AddSongsToPlaylistViewState extends State<AddSongsToPlaylistView> {
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
                  onPressed: _saveSelectedSongs,
                  child: Text(
                    "common.save".tr(),
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 18,
                    ),
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
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  activeColor: AppColors.blue,
                  checkColor: Colors.black,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
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

  Future<void> _saveSelectedSongs() async {
    setState(() => _isSaving = true);

    for (final id in _selectedIds) {
      final song = widget.allSongs.firstWhere((s) => s.id == id);
      await _service.addSongToPlaylist(widget.playlistId, song);
    }

    if (!mounted) return;

    final selectedCount = _selectedIds.length;
    Navigator.pop(context);
    widget.onDone();
    MySnackBar(context: context).showSnackBar(
      "$selectedCount songs added to playlist!",
      AppColors.blue,
    );
  }
}
