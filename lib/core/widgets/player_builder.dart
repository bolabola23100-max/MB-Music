import 'package:flutter/material.dart';
import 'package:music/core/services/cache_helper.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music/features/player/screens/player_screen.dart';
import 'package:music/features/player/screens/player_screen1.dart';

typedef PlayerBuilder =
    Widget Function({
      required List<SongModel> songs,
      required int index,
      Future<void> Function(List<SongModel> songs)? onDeleteSongs,
    });

/// كل الثيمات المتاحة هنا - عشان تضيف ثيم جديد زود سطر واحد بس
final Map<int, PlayerBuilder> playerThemes = {
  1: ({required songs, required index, onDeleteSongs}) =>
      PlayerScreen(songs: songs, index: index, onDeleteSongs: onDeleteSongs),
  2: ({required songs, required index, onDeleteSongs}) =>
      PlayerScreen1(songs: songs, index: index, onDeleteSongs: onDeleteSongs),
};

Widget resolvePlayerScreen({
  required List<SongModel> songs,
  required int index,
  Future<void> Function(List<SongModel> songs)? onDeleteSongs,
}) {
  final themeStyle = CacheHelper.playerThemeStyle;
  final builder = playerThemes[themeStyle] ?? playerThemes[1]!;
  return builder(songs: songs, index: index, onDeleteSongs: onDeleteSongs);
}
