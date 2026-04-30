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
      const Duration(seconds: 10),
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

      // Only update if there's a change in the number of songs
      if (filtered.length != state.songs.length ||
          filteredSounds.length != state.sounds.length) {
        emit(
          state.copyWith(
            originalSongs: List.from(filtered),
            songs: List.from(filtered),
            displaySongs: List.from(filtered),
            sounds: List.from(filteredSounds),
          ),
        );

        // Update the audio service queues too
        _audioService.originalQueue = List.from(filtered);
        // We don't overwrite currentQueue automatically to avoid interrupting playback flow,
        // but the UI will now show the new songs.
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

    for (final song in deletedSongs) {
      if (_favoritesService.isFavorite(song.id)) {
        await _favoritesService.toggleFavorite(song.id);
      }
      await playlistService.removeSongFromAllPlaylists(song.id);
    }

    await HiddenSongsService().hideSongs(deletedIds);

    emit(
      state.copyWith(
        originalSongs: state.originalSongs
            .where((s) => !deletedIds.contains(s.id))
            .toList(),
        songs: state.songs.where((s) => !deletedIds.contains(s.id)).toList(),
        displaySongs: state.displaySongs
            .where((s) => !deletedIds.contains(s.id))
            .toList(),
        sounds: state.sounds.where((s) => !deletedIds.contains(s.id)).toList(),
      ),
    );
  }

  void updateCurrentIndex(int index) {
    emit(state.copyWith(currentIndex: index));
  }

  void updateDisplaySongs(List<SongModel> sorted) {
    emit(state.copyWith(displaySongs: sorted));
  }
}
