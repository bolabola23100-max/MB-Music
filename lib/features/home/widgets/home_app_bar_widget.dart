import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/widgets/dialog/my_snack_bar.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/sort_button.dart';
import 'package:on_audio_query/on_audio_query.dart';

class HomeAppBarWidget extends StatefulWidget {
  final List<SongModel> songs;
  final AudioService audioService;

  final List<SongModel> displaySongs;

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
            icon: Icon(Icons.settings, color: AppColors.blue, size: 25),
            onPressed: () {
              MySnackBar(
                context: context,
              ).showSnackBar("settings_coming_soon".tr(), AppColors.blue);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Center(
            child: Hero(
              tag: "logo",
              child: Image.asset(AppIcons.logo, width: 70),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 12, top: 10),
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
