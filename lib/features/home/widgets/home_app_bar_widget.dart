import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/sort_button.dart';
import 'package:music/features/settings/settings.dart';
import 'package:on_audio_query/on_audio_query.dart';

class HomeAppBarWidget extends StatelessWidget {
  final List<SongModel> songs;
  final AudioService audioService;

  /// الليست اللي بتتعرض حاليًا
  final List<SongModel> displaySongs;

  /// callback يرجّع الليست بعد الترتيب للـ Parent
  final ValueChanged<List<SongModel>> onDisplaySongsChanged;

  const HomeAppBarWidget({
    super.key,
    required this.songs,
    required this.audioService,
    required this.displaySongs,
    required this.onDisplaySongsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 16, top: 10),
          child: IconButton(
            icon: Icon(Icons.settings, color: AppColors.blue, size: 25),
            onPressed: () {
              AppNavigator.push(
                context,
                SettingsScreen(songs: songs, audioService: audioService),
              );
            },
          ),
        ),
        Image.asset(AppIcons.mbMusic, width: 70),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 16, top: 10),
          child: SortButton(
            songs: displaySongs,
            onSongsSorted: onDisplaySongsChanged, // ✅ ابعت للـ Parent
          ),
        ),
      ],
    );
  }
}
