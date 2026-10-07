import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/song_edit/song_edit_service.dart';
import 'package:music/features/home/cubit/home_cubit.dart';
import 'package:music/features/player/screens/player_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MiniPlayerWidget extends StatefulWidget {
  final List<SongModel> songs;
  final AudioService audioService;

  const MiniPlayerWidget({
    super.key,
    required this.songs,
    required this.audioService,
  });

  @override
  State<MiniPlayerWidget> createState() => _MiniPlayerWidgetState();
}

class _MiniPlayerWidgetState extends State<MiniPlayerWidget> {
  String? _customTitle;
  String? _customArtist;
  String? _customArtPath;
  int? _lastSongId;

  @override
  void initState() {
    super.initState();

    SongEditService().editNotifier.addListener(_onEditChanged);

    widget.audioService.currentSongIdNotifier.addListener(_onSongChanged);
  }

  @override
  void dispose() {
    SongEditService().editNotifier.removeListener(_onEditChanged);

    widget.audioService.currentSongIdNotifier.removeListener(_onSongChanged);

    super.dispose();
  }

  void _onEditChanged() => _loadEdit(_lastSongId);

  void _onSongChanged() {
    _loadEdit(widget.audioService.currentSongIdNotifier.value);
  }

  Future<void> _loadEdit(int? songId) async {
    if (songId == null) {
      if (mounted) {
        setState(() {
          _customTitle = null;
          _customArtist = null;
          _customArtPath = null;
          _lastSongId = null;
        });
      }

      return;
    }

    _lastSongId = songId;

    final edit = await SongEditService().getEdit(songId);

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
    if (widget.songs.isEmpty) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<int?>(
      valueListenable: widget.audioService.currentSongIdNotifier,
      builder: (context, currentSongId, _) {
        if (currentSongId == null) {
          return const SizedBox.shrink();
        }

        if (currentSongId != _lastSongId) {
          Future.microtask(() => _loadEdit(currentSongId));
        }

        return MiniPlayerContent(
          audioService: widget.audioService,
          currentSongId: currentSongId,
          customTitle: _customTitle,
          customArtist: _customArtist,
          customArtPath: _customArtPath,
          onTap: () {
            final index =
                widget.audioService.currentIndexNotifier.value ?? 0;

            Future<void> Function(List<SongModel>)? onDelete;

            try {
              onDelete = context.read<HomeCubit>().onDeleteSongs;
            } catch (_) {}

            AppNavigator.push(
              context,
              PlayerScreen(
                songs: widget.songs,
                index: index,
                onDeleteSongs: onDelete,
              ),
            );
          },
        )
      },
    );
  }
}
