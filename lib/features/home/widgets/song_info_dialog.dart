import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:easy_localization/easy_localization.dart';

class SongInfoDialog extends StatelessWidget {
  final SongModel song;

  const SongInfoDialog({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        "song_info_title".tr(),
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow("song_info.title".tr(), song.title),
            const SizedBox(height: 8),
            _infoRow(
              "song_info.artist".tr(),
              song.artist == null || song.artist == "<unknown>"
                  ? "common.unknown".tr()
                  : song.artist!,
            ),
            const SizedBox(height: 8),
            _infoRow(
              "song_info.album".tr(),
              song.album == null || song.album == "<unknown>"
                  ? "common.unknown".tr()
                  : song.album!,
            ),
            const SizedBox(height: 8),
            _infoRow("song_info.duration".tr(), _formatDuration(song.duration)),
            const SizedBox(height: 8),
            _infoRow("song_info.path".tr(), song.data),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "common.close".tr(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String title, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "$title: ",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null) return "common.unknown".tr();

    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return "$minutes:$seconds";
  }
}
