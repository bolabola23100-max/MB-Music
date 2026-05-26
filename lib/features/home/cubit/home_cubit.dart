import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/core/services/hidden_songs_service.dart';
import 'package:music/core/services/playlist/playlist_service.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_state.dart';

import 'dart:async';

class HomeCubit extends Cubit<HomeState> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioService _audioService = AudioService();
  final FavoritesService _favoritesService = FavoritesService();
  Timer? _refreshTimer;

  HomeCubit() : super(const HomeState()) {
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => silentRefresh(),
    );
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }

  Future<void> initData() async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      await [
        Permission.storage,
        Permission.audio,
        Permission.notification,
      ].request();

      await HiddenSongsService().init();

      final queried = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
      );

      final songsList = HiddenSongsService().filterHidden(queried, (s) => s.id);

      final filtered = songsList
          .where((s) => (s.duration ?? 0) >= 60000)
          .toList();
      final filteredSounds = songsList
          .where((s) => (s.duration ?? 0) < 60000)
          .toList();

      emit(
        state.copyWith(
          status: HomeStatus.success,
          originalSongs: List.from(filtered),
          songs: List.from(filtered),
          displaySongs: List.from(filtered),
          sounds: List.from(filteredSounds),
        ),
      );
      _audioService.originalQueue = List.from(filtered);
      _audioService.currentQueue = List.from(filtered);
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.failure));
    }
  }

  Future<void> silentRefresh() async {
    try {
      final queried = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
      );

      final songsList = HiddenSongsService().filterHidden(queried, (s) => s.id);

      final filtered = songsList
          .where((s) => (s.duration ?? 0) >= 60000)
          .toList();
      final filteredSounds = songsList
          .where((s) => (s.duration ?? 0) < 60000)
          .toList();

      // Check if IDs have changed, not just count
      final currentIds = state.songs.map((s) => s.id).toSet();
      final newIds = filtered.map((s) => s.id).toSet();
      final soundCurrentIds = state.sounds.map((s) => s.id).toSet();
      final soundNewIds = filteredSounds.map((s) => s.id).toSet();

      if (!currentIds.containsAll(newIds) ||
          !newIds.containsAll(currentIds) ||
          !soundCurrentIds.containsAll(soundNewIds) ||
          !soundNewIds.containsAll(soundCurrentIds)) {
        final newFiltered = List<SongModel>.from(filtered);
        final newSounds = List<SongModel>.from(filteredSounds);

        emit(
          state.copyWith(
            originalSongs: newFiltered,
            songs: newFiltered,
            displaySongs: newFiltered,
            sounds: newSounds,
          ),
        );

        _audioService.originalQueue = newFiltered;

        // Sync currentQueue: keep playing songs that still exist, remove deleted
        final existingIds = newIds;
        final currentQueue = _audioService.currentQueue;
        if (currentQueue.isNotEmpty) {
          final updatedQueue = currentQueue
              .where((s) => existingIds.contains(s.id))
              .toList();
          if (updatedQueue.length != currentQueue.length) {
            final currentSongId = _audioService.currentSongIdNotifier.value;
            final newIdx = updatedQueue.indexWhere((s) => s.id == currentSongId);
            if (newIdx != -1) {
              _audioService.updateQueueAndKeepPlaying(updatedQueue, newIdx);
            } else {
              _audioService.setQueue(updatedQueue);
            }
          }
        }
      }
    } catch (_) {
      // Fail silently for background refresh
    }
  }

  void handleSort(SongSortOption option) async {
    List<SongModel> newList = List.from(
      state.displaySongs.isNotEmpty ? state.displaySongs : state.songs,
    );

    if (option == SongSortOption.newestFirst) {
      newList = List.from(state.originalSongs);
    } else if (option == SongSortOption.oldestFirst) {
      newList = List.from(state.originalSongs.reversed);
    } else if (option == SongSortOption.shufflePlay) {
      final currentSongId = _audioService.currentSongIdNotifier.value;
      newList = List.from(
        state.displaySongs.isNotEmpty ? state.displaySongs : state.songs,
      );

      SongModel? currentSong;
      if (currentSongId != null) {
        try {
          currentSong = newList.firstWhere((s) => s.id == currentSongId);
        } catch (_) {}
      }

      if (currentSong != null) {
        newList.removeWhere((s) => s.id == currentSongId);
        newList.shuffle();
        newList.insert(0, currentSong);

        _audioService.originalQueue = List.from(state.originalSongs);
        _audioService.updateQueueAndKeepPlaying(newList, 0);

        emit(state.copyWith(displaySongs: newList));
        return; // Skip the playAtIndex call at the end
      } else {
        newList.shuffle();
      }

      _audioService.originalQueue = List.from(state.originalSongs);
      _audioService.currentQueue = newList;
    } else if (option == SongSortOption.orderedPlay) {
      newList = List.from(state.originalSongs);
      _audioService.originalQueue = newList;
      _audioService.currentQueue = newList;
    }

    emit(state.copyWith(displaySongs: newList));

    if (option == SongSortOption.orderedPlay ||
        option == SongSortOption.shufflePlay) {
      if (newList.isNotEmpty) await playAtIndex(0);
    }
  }

  Future<void> playAtIndex(int index) async {
    final s = state.displaySongs[index];
    await _audioService.playSong(
      s.data,
      title: s.title,
      artist: s.artist,
      index: index,
      songId: s.id,
      queue: state.displaySongs,
    );
  }

  Future<void> onDeleteSongs(List<SongModel> deletedSongs) async {
    final deletedIds = deletedSongs.map((s) => s.id).toSet();
    final playlistService = PlaylistService();

    final currentSongId = _audioService.currentSongIdNotifier.value;
    final isPlayingDeleted =
        currentSongId != null && deletedIds.contains(currentSongId);

    for (final song in deletedSongs) {
      if (_favoritesService.isFavorite(song.id)) {
        await _favoritesService.toggleFavorite(song.id);
      }
      await playlistService.removeSongFromAllPlaylists(song.id);
    }

    await HiddenSongsService().hideSongs(deletedIds);

    final newOriginal = state.originalSongs
        .where((s) => !deletedIds.contains(s.id))
        .toList();
    final newSongs = state.songs
        .where((s) => !deletedIds.contains(s.id))
        .toList();
    final newDisplay = state.displaySongs
        .where((s) => !deletedIds.contains(s.id))
        .toList();
    final newSounds = state.sounds
        .where((s) => !deletedIds.contains(s.id))
        .toList();

    emit(
      state.copyWith(
        originalSongs: newOriginal,
        songs: newSongs,
        displaySongs: newDisplay,
        sounds: newSounds,
      ),
    );

    _audioService.originalQueue = newOriginal;

    if (isPlayingDeleted) {
      if (newDisplay.isEmpty) {
        // Nothing left to play
        await _audioService.stop();
        _audioService.setQueue([]);
      } else {
        // Let PlayerCubit auto-skip; just update the queue
        _audioService.currentQueue = newDisplay;
      }
    } else if (currentSongId != null) {
      final newIndex = newDisplay.indexWhere((s) => s.id == currentSongId);
      if (newIndex != -1) {
        _audioService.updateQueueAndKeepPlaying(newDisplay, newIndex);
      } else {
        _audioService.setQueue(newDisplay);
      }
    } else {
      _audioService.setQueue(newDisplay);
    }
  }

  void updateCurrentIndex(int index) {
    emit(state.copyWith(currentIndex: index));
  }

  void updateDisplaySongs(List<SongModel> sorted) {
    emit(state.copyWith(displaySongs: sorted));
  }
}
