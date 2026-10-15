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

  List<SongModel> _restoreDisplayOrder(List<SongModel> songs, List<int> ids) {
    if (ids.isEmpty) return List<SongModel>.from(songs);
    final map = <int, SongModel>{for (final s in songs) s.id: s};
    final result = <SongModel>[];
    for (final id in ids) {
      final song = map.remove(id);
      if (song != null) {
        result.add(song);
      }
    }
    result.addAll(map.values);
    return result;
  }

  Future<List<SongModel>> _querySongs() async {
    final queried = await _audioQuery.querySongs(sortType: SongSortType.DATE_ADDED, orderType: OrderType.DESC_OR_GREATER, uriType: UriType.EXTERNAL);
    return HiddenSongsService().filterHidden(queried, (s) => s.id);
  }

  Future<void> initData() async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      await [Permission.storage, Permission.audio, Permission.notification].request();
      await HiddenSongsService().init();
      final all = await _querySongs();
      final filtered = all.where((s) => (s.duration ?? 0) >= 60000).toList();
      final sounds = all.where((s) => (s.duration ?? 0) < 60000).toList();
      final display = _restoreDisplayOrder(filtered, await AudioPersistenceHelper.getDisplayOrder());
      emit(state.copyWith(status: HomeStatus.success, originalSongs: List<SongModel>.from(filtered), songs: List<SongModel>.from(filtered), displaySongs: display, sounds: List<SongModel>.from(sounds)));
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
      final all = await _querySongs();
      final filtered = all.where((s) => (s.duration ?? 0) >= 60000).toList();
      final sounds = all.where((s) => (s.duration ?? 0) < 60000).toList();
      final ids = filtered.map((s) => s.id).toSet();
      final soundIds = sounds.map((s) => s.id).toSet();
      final oldIds = state.songs.map((s) => s.id).toSet();
      final oldSoundIds = state.sounds.map((s) => s.id).toSet();
      if (ids.length == oldIds.length && ids.containsAll(oldIds) && soundIds.length == oldSoundIds.length && soundIds.containsAll(oldSoundIds)) {
        return;
      }

      final map = <int, SongModel>{for (final s in filtered) s.id: s};
      final display = <SongModel>[];
      for (final s in state.displaySongs) {
        final updated = map.remove(s.id);
        if (updated != null) display.add(updated);
      }
      display.addAll(map.values);
      emit(state.copyWith(originalSongs: List<SongModel>.from(filtered), songs: List<SongModel>.from(filtered), displaySongs: display, sounds: List<SongModel>.from(sounds)));
      await AudioPersistenceHelper.saveDisplayOrder(display);
      if (!await AudioPersistenceHelper.isPlaylistQueueActive()) _audioService.originalQueue = List<SongModel>.from(filtered);

      final currentQueue = _audioService.currentQueue;
      if (currentQueue.isNotEmpty) {
        final updatedQueue = currentQueue.where((s) => ids.contains(s.id)).toList();
        if (updatedQueue.length != currentQueue.length) {
          final currentId = _audioService.currentSongIdNotifier.value;
          final index = updatedQueue.indexWhere((s) => s.id == currentId);
          if (index >= 0) {
            await _audioService.updateQueueAndKeepPlaying(updatedQueue, index);
          } else {
            await _audioService.setQueue(updatedQueue);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> handleSort(SongSortOption option) async {
    var list = List<SongModel>.from(state.displaySongs.isNotEmpty ? state.displaySongs : state.songs);
    if (option == SongSortOption.newestFirst) {
      list = List<SongModel>.from(state.originalSongs);
    } else if (option == SongSortOption.oldestFirst) {
      list = List<SongModel>.from(state.originalSongs.reversed);
    }
    else if (option == SongSortOption.shufflePlay) {
      final id = _audioService.currentSongIdNotifier.value;
      SongModel? current;
      for (final s in list) {
        if (s.id == id) {
          current = s;
          break;
        }
      }
      if (current != null) list.removeWhere((s) => s.id == id);
      list.shuffle();
      if (current != null) {
        list.insert(0, current);
      }
      _audioService.originalQueue = List<SongModel>.from(state.originalSongs);
      _audioService.currentQueue = List<SongModel>.from(list);
    } else if (option == SongSortOption.orderedPlay) {
      list = List<SongModel>.from(state.originalSongs);
      _audioService.originalQueue = List<SongModel>.from(list);
      _audioService.currentQueue = List<SongModel>.from(list);
    }
    emit(state.copyWith(displaySongs: List<SongModel>.from(list)));
    await AudioPersistenceHelper.saveDisplayOrder(list);
    if ((option == SongSortOption.orderedPlay || option == SongSortOption.shufflePlay) && list.isNotEmpty) await playAtIndex(0);
  }

  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= state.displaySongs.length) return;
    final s = state.displaySongs[index];
    await _audioService.playSong(s.data, title: s.title, artist: s.artist, index: index, songId: s.id, queue: state.displaySongs);
  }

  Future<void> onDeleteSongs(List<SongModel> deletedSongs) async {
    final deleted = deletedSongs.map((s) => s.id).toSet();
    final playlists = PlaylistService();
    final currentId = _audioService.currentSongIdNotifier.value;
    final deletingCurrent = currentId != null && deleted.contains(currentId);
    for (final s in deletedSongs) {
      if (_favoritesService.isFavorite(s.id)) await _favoritesService.toggleFavorite(s.id);
      await playlists.removeSongFromAllPlaylists(s.id);
    }
    await HiddenSongsService().hideSongs(deleted);
    final original = state.originalSongs.where((s) => !deleted.contains(s.id)).toList();
    final songs = state.songs.where((s) => !deleted.contains(s.id)).toList();
    final display = state.displaySongs.where((s) => !deleted.contains(s.id)).toList();
    final sounds = state.sounds.where((s) => !deleted.contains(s.id)).toList();
    emit(state.copyWith(originalSongs: original, songs: songs, displaySongs: display, sounds: sounds));
    await AudioPersistenceHelper.saveDisplayOrder(display);
    _audioService.originalQueue = List<SongModel>.from(original);
    if (deletingCurrent) {
      if (display.isEmpty) { await _audioService.stop(); await _audioService.setQueue([]); }
      else _audioService.currentQueue = List<SongModel>.from(display);
    } else if (currentId != null) {
      final index = display.indexWhere((s) => s.id == currentId);
      if (index >= 0) await _audioService.updateQueueAndKeepPlaying(display, index);
      else await _audioService.setQueue(display);
    } else await _audioService.setQueue(display);
  }

  void updateCurrentIndex(int index) => emit(state.copyWith(currentIndex: index));
  void updateDisplaySongs(List<SongModel> sorted) {
    emit(state.copyWith(displaySongs: List<SongModel>.from(sorted)));
    AudioPersistenceHelper.saveDisplayOrder(sorted);
  }
}
