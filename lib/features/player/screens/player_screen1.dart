import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music/features/player/screens/player_screen.dart';

/// Backward-compatible entry point kept for existing imports.
class PlayerScreen1 extends PlayerScreen {
  const PlayerScreen1({
    super.key,
    required List<SongModel> songs,
    required int index,
    Future<void> Function(List<SongModel> songs)? onDeleteSongs,
  }) : super(
          songs: songs,
          index: index,
          onDeleteSongs: onDeleteSongs,
        );
}

class PlayerView1 extends PlayerView {
  const PlayerView1({
    super.key,
    Future<void> Function(List<SongModel> songs)? onDeleteSongs,
  }) : super(onDeleteSongs: onDeleteSongs);
}
