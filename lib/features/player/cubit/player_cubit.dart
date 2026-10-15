import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/song_edit/song_edit_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final AudioService _audioService = AudioService();
  StreamSubscription<bool>? _playingSubscription;

  PlayerCubit({required List<SongModel> songs, required int index})
      : super(PlayerState(songs: songs, currentIndex: index)) {
    _init();
  }

  Future<void> _init() async {
    _audioService.currentIndexNotifier.addListener(_onIndexChanged);
    _audioService.currentQueueNotifier.addListener(_onQueueChanged);
    SongEditService().editNotifier.addListener(_onEditChanged);

    // AudioService._handler is initialized asynchronously. Do not access
    // _audioService.player until initialization has completed.
    try {
      await _audioService.ready;
      if (isClosed) return;

      _playingSubscription = _audioService.player.playingStream.listen((playing) {
        if (!isClosed) {
          emit(state.copyWith(isPlaying: playing));
        }
      });

      if (!isClosed) {
        emit(state.copyWith(isPlaying: _audioService.isPlaying));
        loadEdit();
      }
    } catch (_) {
      if (!isClosed) {
        loadEdit();
      }
    }
  }

  @override
  Future<void> close() {
    _audioService.currentIndexNotifier.removeListener(_onIndexChanged);
    _audioService.currentQueueNotifier.removeListener(_onQueueChanged);
    SongEditService().editNotifier.removeListener(_onEditChanged);
    _playingSubscription?.cancel();
    return super.close();
  }

  void _onEditChanged() => loadEdit();

  void _onQueueChanged() {
    final newQueue = _audioService.currentQueue;
    if (newQueue.isEmpty) {
      emit(const PlayerState(songs: [], currentIndex: 0, isPlaying: false));
      return;
    }

    final currentSongId = _audioService.currentSongIdNotifier.value;

    emit(state.copyWith(songs: newQueue));

    // Queue notifications can fire before the first tapped song has reached
    // the audio handler. A null currentSongId does not mean the song was
    // deleted; trying to autoplay here calls playSong again, updates the queue
    // again, and can create a playback loop that prevents the selected local
    // file from loading reliably.
    if (currentSongId == null) return;

    final stillExists = newQueue.any((song) => song.id == currentSongId);
    if (!stillExists) {
      // The current song was deleted — play the next one in the new queue.
      final newIndex = state.currentIndex.clamp(0, newQueue.length - 1);
      final nextSong = newQueue[newIndex];
      unawaited(_audioService.playSong(
        nextSong.data,
        title: nextSong.title,
        artist: nextSong.artist,
        index: newIndex,
        songId: nextSong.id,
        queue: newQueue,
      ));
    } else {
      _onIndexChanged();
    }
  }

  void _onIndexChanged() {
    final newIndex = _audioService.currentIndexNotifier.value ?? state.currentIndex;
    if (newIndex >= 0 && newIndex < state.songs.length) {
      emit(state.copyWith(currentIndex: newIndex));
      loadEdit();
    }
  }

  Future<void> loadEdit() async {
    if (state.songs.isEmpty) return;
    final safeIndex = state.currentIndex.clamp(0, state.songs.length - 1);
    final songId = state.songs[safeIndex].id;
    final edit = await SongEditService().getEdit(songId);
    if (isClosed) return;
    emit(state.copyWith(
      customTitle: () => edit?['title'],
      customArtist: () => edit?['artist'],
      customArtPath: () => edit?['artPath'],
    ));
  }

  void updateDrag(double deltaDy) {
    if (deltaDy > 0) {
      emit(state.copyWith(offsetY: state.offsetY + deltaDy));
    }
  }

  void setCanDrag(bool canDrag) {
    emit(state.copyWith(canDrag: canDrag));
  }

  void resetDrag() {
    emit(state.copyWith(offsetY: 0));
  }
}
