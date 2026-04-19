import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SoundsScreen extends StatelessWidget {
  final List<SongModel> songs;
  final AudioService audioService;
  final Future<void> Function(List<SongModel> songs)? onDeleteSongs;

  const SoundsScreen({
    super.key,
    required this.songs,
    required this.audioService,
    this.onDeleteSongs,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return  Center(
        child: Text('no_sounds_found'.tr(), style: TextStyle(color: Colors.white54)),
      );
    }

    return SongListWidget(
      songs: songs,
      audioService: audioService,
      isTitle: false,
      showMiniPlayer: true,
      openPlayerOnSongTap: true,
      isf: false,
      onDeleteSongs: onDeleteSongs,
    );
  }
}
