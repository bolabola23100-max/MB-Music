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

  void _init() {
    _audioService.currentIndexNotifier.addListener(_onIndexChanged);
    _playingSubscription = _audioService.player.playingStream.listen((playing) {
      emit(state.copyWith(isPlaying: playing));
    });
    SongEditService().editNotifier.addListener(_onEditChanged);
    loadEdit();
  }

  @override
  Future<void> close() {
    _audioService.currentIndexNotifier.removeListener(_onIndexChanged);
    SongEditService().editNotifier.removeListener(_onEditChanged);
    _playingSubscription?.cancel();
    return super.close();
  }

  void _onEditChanged() => loadEdit();

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
    emit(state.copyWith(
      customTitle: edit?['title'],
      customArtist: edit?['artist'],
      customArtPath: edit?['artPath'],
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
