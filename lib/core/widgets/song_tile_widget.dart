import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/song_edit/song_edit_service.dart';
import 'package:music/core/widgets/app_artwork.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// ✅ SongTileWidget محسَّن:
/// - يستمع لـ currentSongId وisPlaying داخلياً عبر ValueListenableBuilder
///   بدلاً من استقبالهما كـ parameters → لا إعادة بناء للقائمة كلها
/// - RepaintBoundary يعزل كل tile ويمنع رسمه عند تغيير الـ tiles المجاورة
class SongTileWidget extends StatefulWidget {
  final SongModel song;
  final AudioService audioService;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;
  final VoidCallback? onLongPress;

  const SongTileWidget({
    super.key,
    required this.song,
    required this.audioService,
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

    // ✅ RepaintBoundary: يعزل هذا الـ tile — لا يُعاد رسمه إلا لو هو نفسه تغيّر
    return RepaintBoundary(
      child: ValueListenableBuilder<int?>(
        // ✅ كل tile يستمع بنفسه بدلاً من إعادة بناء القائمة كلها
        valueListenable: widget.audioService.currentSongIdNotifier,
        builder: (context, currentSongId, _) {
          final isCurrent = currentSongId == widget.song.id;

          return ValueListenableBuilder<bool>(
            valueListenable: widget.audioService.isPlayingNotifier,
            builder: (context, isPlaying, _) {
              return GestureDetector(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.blue.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isCurrent ? AppColors.blue : Colors.transparent,
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      AppArtwork(
                        id: widget.song.id,
                        isCurrent: isCurrent,
                        borderRadius: 100,
                        customArtPath: _customArtPath,
                        // ✅ القائمة تستخدم جودة منخفضة (default: highQuality=false)
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
                                color: isCurrent
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
                                color: isCurrent
                                    ? AppColors.blue.withOpacity(0.8)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.only(end: 4),
                          child: Icon(
                            isPlaying
                                ? Icons.graphic_eq
                                : Icons.pause_circle_outline,
                            color: AppColors.blue.withOpacity(0.8),
                          ),
                        ),
                      IconButton(
                        icon:
                            Icon(Icons.more_vert, color: AppColors.white),
                        onPressed: widget.onMoreTap,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
