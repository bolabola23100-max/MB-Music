import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/audio/permission_service.dart';
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
    if (ids.isEmpty) {
      return List<SongModel>.from(songs);
    }
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
      await PermissionService.requestAudioPermissions();
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
      final songMetadataUnchanged =
          state.songs.length == filtered.length &&
          state.songs.every((oldSong) {
            final updatedSong = filtered.where((song) => song.id == oldSong.id);
            if (updatedSong.isEmpty) return false;
            final updated = updatedSong.first;
            return oldSong.data == updated.data &&
                oldSong.title == updated.title &&
                oldSong.artist == updated.artist &&
                oldSong.duration == updated.duration;
          });
      final soundMetadataUnchanged =
          state.sounds.length == sounds.length &&
          state.sounds.every((oldSound) {
            final updatedSound = sounds.where((sound) => sound.id == oldSound.id);
            if (updatedSound.isEmpty) return false;
            final updated = updatedSound.first;
            return oldSound.data == updated.data &&
                oldSound.title == updated.title &&
                oldSound.artist == updated.artist &&
                oldSound.duration == updated.duration;
          });
      if (ids.length == oldIds.length &&
          ids.containsAll(oldIds) &&
          soundIds.length == oldSoundIds.length &&
          soundIds.containsAll(oldSoundIds) &&
          songMetadataUnchanged &&
          soundMetadataUnchanged) {
        return;
      }

      final map = <int, SongModel>{for (final s in filtered) s.id: s};
      final display = <SongModel>[];
      for (final s in state.displaySongs) {
        final updated = map.remove(s.id);
        if (updated != null) {
          display.add(updated);
        }
      }
      display.addAll(map.values);
      emit(state.copyWith(originalSongs: List<SongModel>.from(filtered), songs: List<SongModel>.from(filtered), displaySongs: display, sounds: List<SongModel>.from(sounds)));
      await AudioPersistenceHelper.saveDisplayOrder(display);
      if (!await AudioPersistenceHelper.isPlaylistQueueActive()) {
        _audioService.originalQueue = List<SongModel>.from(filtered);
      }

      // A playlist queue has its own membership and ordering. Only reconcile
      // the home queue here; playlist changes are handled by PlaylistService.
      if (!await AudioPersistenceHelper.isPlaylistQueueActive()) {
        final currentQueue = _audioService.currentQueue;
        if (currentQueue.isNotEmpty) {
          final updatedById = <int, SongModel>{
            for (final song in filtered) song.id: song,
          };
          final updatedQueue = currentQueue
              .where((song) => updatedById.containsKey(song.id))
              .map((song) => updatedById[song.id]!)
              .toList();
          final queueChanged = updatedQueue.length != currentQueue.length ||
              List.generate(updatedQueue.length, (index) {
                final oldSong = index < currentQueue.length
                    ? currentQueue[index]
                    : null;
                final newSong = updatedQueue[index];
                return oldSong == null ||
                    oldSong.id != newSong.id ||
                    oldSong.data != newSong.data ||
                    oldSong.title != newSong.title ||
                    oldSong.artist != newSong.artist ||
                    oldSong.duration != newSong.duration;
              }).any((changed) => changed);

          if (queueChanged) {
            final activeSongId = _audioService.currentSongIdNotifier.value;
            final activeIndex = updatedQueue.indexWhere(
              (song) => song.id == activeSongId,
            );
            if (activeIndex >= 0) {
              await _audioService.updateQueueAndKeepPlaying(
                updatedQueue,
                activeIndex,
              );
            } else if (updatedQueue.isNotEmpty) {
              final nextSong = updatedQueue.first;
              await _audioService.playSong(
                nextSong.data,
                title: nextSong.title,
                artist: nextSong.artist,
                index: 0,
                songId: nextSong.id,
                queue: updatedQueue,
              );
            } else {
              await _audioService.stop();
              await _audioService.setQueue([]);
            }
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
      if (current != null) {
        list.removeWhere((s) => s.id == id);
      }
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
    if ((option == SongSortOption.orderedPlay ||
            option == SongSortOption.shufflePlay) &&
        list.isNotEmpty) {
      await playAtIndex(0);
    }
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
    final playlistQueueActive =
        await AudioPersistenceHelper.isPlaylistQueueActive();
    final queueBeforeDelete = List<SongModel>.from(_audioService.currentQueue);
    final oldQueueIndex = currentId == null
        ? 0
        : queueBeforeDelete.indexWhere((song) => song.id == currentId);
    final deletingCurrent = currentId != null && deleted.contains(currentId);
    for (final s in deletedSongs) {
      if (_favoritesService.isFavorite(s.id)) {
        await _favoritesService.toggleFavorite(s.id);
      }
      await playlists.removeSongFromAllPlaylists(s.id);
    }
    await HiddenSongsService().hideSongs(deleted);
    final original = state.originalSongs.where((s) => !deleted.contains(s.id)).toList();
    final songs = state.songs.where((s) => !deleted.contains(s.id)).toList();
    final display = state.displaySongs.where((s) => !deleted.contains(s.id)).toList();
    final sounds = state.sounds.where((s) => !deleted.contains(s.id)).toList();
    emit(state.copyWith(originalSongs: original, songs: songs, displaySongs: display, sounds: sounds));
    await AudioPersistenceHelper.saveDisplayOrder(display);
    final activeQueue = queueBeforeDelete
        .where((song) => !deleted.contains(song.id))
        .toList();
    _audioService.originalQueue = List<SongModel>.from(
      playlistQueueActive ? activeQueue : original,
    );

    if (deletingCurrent) {
      if (activeQueue.isEmpty) {
        await _audioService.stop();
        await _audioService.setQueue([]);
      } else {
        final nextIndex = oldQueueIndex < 0
            ? 0
            : oldQueueIndex.clamp(0, activeQueue.length - 1).toInt();
        final nextSong = activeQueue[nextIndex];
        await _audioService.playSong(
          nextSong.data,
          title: nextSong.title,
          artist: nextSong.artist,
          index: nextIndex,
          songId: nextSong.id,
          queue: activeQueue,
          queueType: playlistQueueActive ? 'playlist' : 'home',
          playlistId: playlistQueueActive
              ? await AudioPersistenceHelper.getActivePlaylistId()
              : null,
        );
      }
    } else if (currentId != null) {
      final index = activeQueue.indexWhere((song) => song.id == currentId);
      if (index >= 0) {
        await _audioService.updateQueueAndKeepPlaying(activeQueue, index);
      } else if (activeQueue.isNotEmpty) {
        final nextSong = activeQueue.first;
        await _audioService.playSong(
          nextSong.data,
          title: nextSong.title,
          artist: nextSong.artist,
          index: 0,
          songId: nextSong.id,
          queue: activeQueue,
          queueType: playlistQueueActive ? 'playlist' : 'home',
          playlistId: playlistQueueActive
              ? await AudioPersistenceHelper.getActivePlaylistId()
              : null,
        );
      } else {
        await _audioService.stop();
        await _audioService.setQueue([]);
      }
    } else {
      await _audioService.setQueue(activeQueue);
    }
  }

  void updateCurrentIndex(int index) => emit(state.copyWith(currentIndex: index));
  void updateDisplaySongs(List<SongModel> sorted) {
    emit(state.copyWith(displaySongs: List<SongModel>.from(sorted)));
    AudioPersistenceHelper.saveDisplayOrder(sorted);
  }
}
