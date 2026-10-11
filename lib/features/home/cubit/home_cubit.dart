import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/audio/helpers/audio_persistence_helper.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/core/services/hidden_songs_service.dart';
import 'package:music/core/services/playlist/playlist_service.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioService _audioService = AudioService();
  final FavoritesService _favoritesService = FavoritesService();

  HomeCubit() : super(const HomeState());

  List<SongModel> _restoreDisplayOrder(List<SongModel> songs, List<int> savedIds) {
    if (savedIds.isEmpty) return List<SongModel>.from(songs);
    final map = <int, SongModel>{for (final song in songs) song.id: song};
    final ordered = <SongModel>[];
    for (final id in savedIds) {
      final song = map.remove(id);
      if (song != null) ordered.add(song);
    }
    ordered.addAll(map.values);
    return ordered;
  }

  Future<List<SongModel>> _queryFilteredSongs() async {
    final queried = await _audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
    );
    final songs = HiddenSongsService().filterHidden(queried, (s) => s.id);
    return songs.where((s) => (s.duration ?? 0) >= 60000).toList();
  }

  Future<List<SongModel>> _querySounds() async {
    final queried = await _audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
    );
    final songs = HiddenSongsService().filterHidden(queried, (s) => s.id);
    return songs.where((s) => (s.duration ?? 0) < 60000).toList();
  }

  Future<void> initData() async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      await [Permission.storage, Permission.audio, Permission.notification].request();
      await HiddenSongsService().init();
      final filtered = await _queryFilteredSongs();
      final sounds = await _querySounds();
      final savedOrder = await AudioPersistenceHelper.getDisplayOrder();
      final display = _restoreDisplayOrder(filtered, savedOrder);
      emit(state.copyWith(
        status: HomeStatus.success,
        originalSongs: List<SongModel>.from(filtered),
        songs: List<SongModel>.from(filtered),
        displaySongs: display,
        sounds: List<SongModel>.from(sounds),
      ));
      if (!await AudioPersistenceHelper.isPlaylistQueueActive()) {
        _audioService.originalQueue = List<SongModel>.from(filtered);
        _audioService.currentQueue = List<SongModel>.from(display);
      }
    } catch (_) {
      emit(state.copyWith(status: HomeStatus.failure));
    }
  }

  Future<void> silentRefresh() async {
    try {
      final filtered = await _queryFilteredSongs();
      final sounds = await _querySounds();
      final currentIds = state.songs.map((s) => s.id).toSet();
      final newIds = filtered.map((s) => s.id).toSet();
      final soundIds = state.sounds.map((s) => s.id).toSet();
      final newSoundIds = sounds.map((s) => s.id).toSet();
      if (currentIds.length == newIds.length && currentIds.containsAll(newIds) && soundIds.length == newSoundIds.length && soundIds.containsAll(newSoundIds)) return;

      final map = <int, SongModel>{for (final song in filtered) song.id: song};
      final display = <SongModel>[];
      for (final song in state.displaySongs) {
        final updated = map.remove(song.id);
        if (updated != null) display.add(updated);
      }
      display.addAll(map.values);
      emit(state.copyWith(originalSongs: List<SongModel>.from(filtered), songs: List<SongModel>.from(filtered), displaySongs: display, sounds: List<SongModel>.from(sounds)));
      await AudioPersistenceHelper.saveDisplayOrder(display);

      if (!await AudioPersistenceHelper.isPlaylistQueueActive()) {
        _audioService.originalQueue = List<SongModel>.from(filtered);
      }
      final currentQueue = _audioService.currentQueue;
      if (currentQueue.isNotEmpty) {
        final updatedQueue = currentQueue.where((s) => newIds.contains(s.id)).toList();
        if (updatedQueue.length != currentQueue.length) {
          final currentSongId = _audioService.currentSongIdNotifier.value;
          final newIndex = updatedQueue.indexWhere((s) => s.id == currentSongId);
          if (newIndex != -1) {
            await _audioService.updateQueueAndKeepPlaying(updatedQueue, newIndex);
          } else {
            await _audioService.setQueue(updatedQueue);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> handleSort(SongSortOption option) async {
    var newList = List<SongModel>.from(state.displaySongs.isNotEmpty ? state.displaySongs : state.songs);
    if (option == SongSortOption.newestFirst) {
      newList = List<SongModel>.from(state.originalSongs);
    } else if (option == SongSortOption.oldestFirst) {
      newList = List<SongModel>.from(state.originalSongs.reversed);
    } else if (option == SongSortOption.shufflePlay) {
      final currentId = _audioService.currentSongIdNotifier.value;
      SongModel? current;
      if (currentId != null) {
        for (final song in newList) { if (song.id == currentId) { current = song; break; } }
      }
      if (current != null) newList.removeWhere((s) => s.id == currentId);
      newList.shuffle();
      if (current != null) newList.insert(0, current);
      _audioService.originalQueue = List<SongModel>.from(state.originalSongs);
      _audioService.currentQueue = List<SongModel>.from(newList);
    } else if (option == SongSortOption.orderedPlay) {
      newList = List<SongModel>.from(state.originalSongs);
      _audioService.originalQueue = List<SongModel>.from(newList);
      _audioService.currentQueue = List<SongModel>.from(newList);
    }
    emit(state.copyWith(displaySongs: List<SongModel>.from(newList)));
    await AudioPersistenceHelper.saveDisplayOrder(newList);
    if ((option == SongSortOption.orderedPlay || option == SongSortOption.shufflePlay) && newList.isNotEmpty) await playAtIndex(0);
  }

  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= state.displaySongs.length) return;
    final song = state.displaySongs[index];
    await _audioService.playSong(song.data, title: song.title, artist: song.artist, index: index, songId: song.id, queue: state.displaySongs);
  }

  Future<void> onDeleteSongs(List<SongModel> deletedSongs) async {
    final deletedIds = deletedSongs.map((s) => s.id).toSet();
    final playlistService = PlaylistService();
    final currentSongId = _audioService.currentSongIdNotifier.value;
    final isPlayingDeleted = currentSongId != null && deletedIds.contains(currentSongId);
    for (final song in deletedSongs) {
      if (_favoritesService.isFavorite(song.id)) await _favoritesService.toggleFavorite(song.id);
      await playlistService.removeSongFromAllPlaylists(song.id);
    }
    await HiddenSongsService().hideSongs(deletedIds);
    final newOriginal = state.originalSongs.where((s) => !deletedIds.contains(s.id)).toList();
    final newSongs = state.songs.where((s) => !deletedIds.contains(s.id)).toList();
    final newDisplay = state.displaySongs.where((s) => !deletedIds.contains(s.id)).toList();
    final newSounds = state.sounds.where((s) => !deletedIds.contains(s.id)).toList();
    emit(state.copyWith(originalSongs: newOriginal, songs: newSongs, displaySongs: newDisplay, sounds: newSounds));
    await AudioPersistenceHelper.saveDisplayOrder(newDisplay);
    _audioService.originalQueue = List<SongModel>.from(newOriginal);
    if (isPlayingDeleted) {
      if (newDisplay.isEmpty) { await _audioService.stop(); await _audioService.setQueue([]); }
      else _audioService.currentQueue = List<SongModel>.from(newDisplay);
    } else if (currentSongId != null) {
      final index = newDisplay.indexWhere((s) => s.id == currentSongId);
      if (index != -1) await _audioService.updateQueueAndKeepPlaying(newDisplay, index);
      else await _audioService.setQueue(newDisplay);
    } else {
      await _audioService.setQueue(newDisplay);
    }
  }

  void updateCurrentIndex(int index) => emit(state.copyWith(currentIndex: index));

  void updateDisplaySongs(List<SongModel> sorted) {
    emit(state.copyWith(displaySongs: List<SongModel>.from(sorted)));
    AudioPersistenceHelper.saveDisplayOrder(sorted);
  }
}
