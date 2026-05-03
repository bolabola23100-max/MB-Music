import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/song_edit/song_edit_service.dart';
import 'package:music/core/widgets/app_artwork.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongTileWidget extends StatefulWidget {
  final SongModel song;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;
  final VoidCallback? onLongPress;

  const SongTileWidget({
    super.key,
    required this.song,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
    required this.onMoreTap,
    this.onLongPress,
  });

  @override
  State<SongTileWidget> createState() => _SongTileWidgetState();
}

class _SongTileWidgetState extends State<SongTileWidget> {
  String? _customTitle;
  String? _customArtist;
  String? _customArtPath;

  @override
  void initState() {
    super.initState();
    _loadEdit();
    SongEditService().editNotifier.addListener(_loadEdit);
  }

  @override
  void dispose() {
    SongEditService().editNotifier.removeListener(_loadEdit);
    super.dispose();
  }

  Future<void> _loadEdit() async {
    final edit = await SongEditService().getEdit(widget.song.id);
    if (mounted) {
      setState(() {
        _customTitle = edit?['title'];
        _customArtist = edit?['artist'];
        _customArtPath = edit?['artPath'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _customTitle ?? widget.song.title;
    final artist = _customArtist ?? widget.song.artist ?? 'Unknown';

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isCurrent
              ? AppColors.blue.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isCurrent ? AppColors.blue : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            AppArtwork(
              id: widget.song.id,
              isCurrent: widget.isCurrent,
              borderRadius: 100,
              customArtPath: _customArtPath,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.isCurrent
                          ? AppColors.blue
                          : AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isCurrent
                          ? AppColors.blue.withOpacity(0.8)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isCurrent)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Icon(
                  widget.isPlaying
                      ? Icons.graphic_eq
                      : Icons.pause_circle_outline,
                  color: AppColors.blue.withOpacity(0.8),
                ),
              ),
            IconButton(
              icon: Icon(Icons.more_vert, color: AppColors.white),
              onPressed: widget.onMoreTap,
            ),
          ],
        ),
      ),
    );
  }
}
