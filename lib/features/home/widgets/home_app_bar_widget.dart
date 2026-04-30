import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/constants/app_icons.dart';
// import 'package:music/core/routing/app_navigator.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/sort_button.dart';
// import 'package:music/features/settings/settings.dart';
import 'package:on_audio_query/on_audio_query.dart';

class HomeAppBarWidget extends StatefulWidget {
  final List<SongModel> songs;
  final AudioService audioService;

  /// الليست اللي بتتعرض حاليًا
  final List<SongModel> displaySongs;

  /// callback يرجّع الليست بعد الترتيب للـ Parent
  final ValueChanged<List<SongModel>> onDisplaySongsChanged;

  final VoidCallback onRescan;

  const HomeAppBarWidget({
    super.key,
    required this.songs,
    required this.audioService,
    required this.displaySongs,
    required this.onDisplaySongsChanged,
    required this.onRescan,
  });

  @override
  State<HomeAppBarWidget> createState() => _HomeAppBarWidgetState();
}

class _HomeAppBarWidgetState extends State<HomeAppBarWidget> {
  bool isAscending = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 16, top: 10),
          child: IconButton(
            icon: Icon(Icons.grade, color: AppColors.blue, size: 25),
            onPressed: () {
              final snackBar = SnackBar(
                content: Text("settings_coming_soon".tr()),
                backgroundColor: AppColors.blue,
                duration: Duration(seconds: 2),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);

              // AppNavigator.push(
              //   context,
              //   SettingsScreen(
              //     songs: widget.songs,
              //     audioService: widget.audioService,
              //     onRescan: widget.onRescan,
              //   ),
              // );
            },
          ),
        ),
        Image.asset(AppIcons.mbMusic, width: 70),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 16, top: 10),
          child: SortButton(
            isAscending: isAscending,
            onPressed: () {
              setState(() {
                isAscending = !isAscending;
              });

              widget.onDisplaySongsChanged(sortSongs());
            },
          ),
        ),
      ],
    );
  }

  List<SongModel> sortSongs() {
    return isAscending
        ? [...widget.songs]
        : [...widget.songs].reversed.toList();
  }
}
