import 'dart:async';

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

  Timer? _refreshTimer;

  HomeCubit() : super(const HomeState()) {
    _startAutoRefresh();
  }

  // ============================================================
  // AUTO REFRESH
  // ============================================================

  void _startAutoRefresh() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => silentRefresh(),
    );
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();

    return super.close();
  }

  // ============================================================
  // RESTORE DISPLAY ORDER
  // ============================================================

  List<SongModel> _restoreDisplayOrder(
    List<SongModel> songs,
    List<int> savedIds,
  ) {
    if (savedIds.isEmpty) {
      return List<SongModel>.from(songs);
    }

    final songsMap = <int, SongModel>{for (final song in songs) song.id: song};

    final orderedSongs = <SongModel>[];

    // الأغاني المحفوظة بنفس الترتيب
    for (final id in savedIds) {
      final song = songsMap[id];

      if (song != null) {
        orderedSongs.add(song);

        songsMap.remove(id);
      }
    }

    // أي أغاني جديدة نضيفها في الآخر
    orderedSongs.addAll(songsMap.values);

    return orderedSongs;
  }

  // ============================================================
  // INIT DATA
  // ============================================================

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

      // ⭐ استرجاع آخر ترتيب محفوظ
      final savedOrder = await AudioPersistenceHelper.getDisplayOrder();

      final restoredDisplaySongs = _restoreDisplayOrder(filtered, savedOrder);

      emit(
        state.copyWith(
          status: HomeStatus.success,
          originalSongs: List<SongModel>.from(filtered),
          songs: List<SongModel>.from(filtered),
          displaySongs: restoredDisplaySongs,
          sounds: List<SongModel>.from(filteredSounds),
        ),
      );

      // الـ original يفضل الترتيب الأصلي
      final playlistQueueActive = await AudioPersistenceHelper.isPlaylistQueueActive();

      if (!playlistQueueActive) {
        _audioService.originalQueue = List<SongModel>.from(filtered);
        _audioService.currentQueue = List<SongModel>.from(restoredDisplaySongs);
      }
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.failure));
    }
  }

  // ============================================================
  // SILENT REFRESH
  // ============================================================

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

      final currentIds = state.songs.map((s) => s.id).toSet();

      final newIds = filtered.map((s) => s.id).toSet();

      final soundCurrentIds = state.sounds.map((s) => s.id).toSet();

      final soundNewIds = filteredSounds.map((s) => s.id).toSet();

      final songsChanged =
          !currentIds.containsAll(newIds) || !newIds.containsAll(currentIds);

      final soundsChanged =
          !soundCurrentIds.containsAll(soundNewIds) ||
          !soundNewIds.containsAll(soundCurrentIds);

      if (!songsChanged && !soundsChanged) {
        return;
      }

      // ⭐ مهم:
      // ما نعملش displaySongs = filtered
      // لأن ده كان بيمسح الـ shuffle.

      final currentDisplay = state.displaySongs;

      final filteredMap = <int, SongModel>{
        for (final song in filtered) song.id: song,
      };

      final newDisplay = <SongModel>[];

      // نحافظ على الترتيب الحالي
      for (final song in currentDisplay) {
        final updatedSong = filteredMap[song.id];

        if (updatedSong != null) {
          newDisplay.add(updatedSong);

          filteredMap.remove(song.id);
        }
      }

      // الأغاني الجديدة تتحط في الآخر
      newDisplay.addAll(filteredMap.values);

      emit(
        state.copyWith(
          originalSongs: List<SongModel>.from(filtered),
          songs: List<SongModel>.from(filtered),
          displaySongs: newDisplay,
          sounds: List<SongModel>.from(filteredSounds),
        ),
      );

      // نحفظ الترتيب الجديد
      await AudioPersistenceHelper.saveDisplayOrder(newDisplay);

      _audioService.originalQueue = List<SongModel>.from(filtered);

      // Sync current queue
      final existingIds = newIds;

      final currentQueue = _audioService.currentQueue;

      if (currentQueue.isNotEmpty) {
        final updatedQueue = currentQueue
            .where((s) => existingIds.contains(s.id))
            .toList();

        // لو أغاني اتحذفت
        if (updatedQueue.length != currentQueue.length) {
          final currentSongId = _audioService.currentSongIdNotifier.value;

          final newIdx = updatedQueue.indexWhere((s) => s.id == currentSongId);

          if (newIdx != -1) {
            _audioService.updateQueueAndKeepPlaying(updatedQueue, newIdx);
          } else {
            _audioService.setQueue(updatedQueue);
          }
        }
      } else {
        _audioService.currentQueue = List<SongModel>.from(newDisplay);
      }
    } catch (_) {
      // Background refresh
      // لا نطلع Error للمستخدم
    }
  }

  // ============================================================
  // SORT
  // ============================================================

  Future<void> handleSort(SongSortOption option) async {
    List<SongModel> newList = List<SongModel>.from(
      state.displaySongs.isNotEmpty ? state.displaySongs : state.songs,
    );

    // ----------------------------------------------------------
    // NEWEST
    // ----------------------------------------------------------

    if (option == SongSortOption.newestFirst) {
      newList = List<SongModel>.from(state.originalSongs);
    }
    // ----------------------------------------------------------
    // OLDEST
    // ----------------------------------------------------------
    else if (option == SongSortOption.oldestFirst) {
      newList = List<SongModel>.from(state.originalSongs.reversed);
    }
    // ----------------------------------------------------------
    // SHUFFLE
    // ----------------------------------------------------------
    else if (option == SongSortOption.shufflePlay) {
      final currentSongId = _audioService.currentSongIdNotifier.value;

      newList = List<SongModel>.from(
        state.displaySongs.isNotEmpty ? state.displaySongs : state.songs,
      );

      SongModel? currentSong;

      if (currentSongId != null) {
        try {
          currentSong = newList.firstWhere((s) => s.id == currentSongId);
        } catch (_) {
          currentSong = null;
        }
      }

      if (currentSong != null) {
        newList.removeWhere((s) => s.id == currentSongId);

        newList.shuffle();

        newList.insert(0, currentSong);
      } else {
        newList.shuffle();
      }

      _audioService.originalQueue = List<SongModel>.from(state.originalSongs);

      _audioService.currentQueue = List<SongModel>.from(newList);
    }
    // ----------------------------------------------------------
    // ORDERED
    // ----------------------------------------------------------
    else if (option == SongSortOption.orderedPlay) {
      newList = List<SongModel>.from(state.originalSongs);

      _audioService.originalQueue = List<SongModel>.from(newList);

      _audioService.currentQueue = List<SongModel>.from(newList);
    }

    // ----------------------------------------------------------
    // UPDATE UI
    // ----------------------------------------------------------

    emit(state.copyWith(displaySongs: List<SongModel>.from(newList)));

    // ⭐ أهم سطر:
    // حفظ ترتيب Home على الجهاز
    await AudioPersistenceHelper.saveDisplayOrder(newList);

    // ----------------------------------------------------------
    // PLAY
    // ----------------------------------------------------------

    if (option == SongSortOption.orderedPlay ||
        option == SongSortOption.shufflePlay) {
      if (newList.isNotEmpty) {
        await playAtIndex(0);
      }
    }
  }

  // ============================================================
  // PLAY AT INDEX
  // ============================================================

  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= state.displaySongs.length) {
      return;
    }

    final song = state.displaySongs[index];

    await _audioService.playSong(
      song.data,
      title: song.title,
      artist: song.artist,
      index: index,
      songId: song.id,
      queue: state.displaySongs,
    );
  }

  // ============================================================
  // DELETE SONGS
  // ============================================================

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

    // ⭐ نحفظ الترتيب بعد الحذف
    await AudioPersistenceHelper.saveDisplayOrder(newDisplay);

    _audioService.originalQueue = List<SongModel>.from(newOriginal);

    if (isPlayingDeleted) {
      if (newDisplay.isEmpty) {
        await _audioService.stop();

        _audioService.setQueue([]);
      } else {
        _audioService.currentQueue = List<SongModel>.from(newDisplay);
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

  // ============================================================
  // CURRENT PAGE
  // ============================================================

  void updateCurrentIndex(int index) {
    emit(state.copyWith(currentIndex: index));
  }

  // ============================================================
  // DISPLAY SONGS
  // ============================================================

  void updateDisplaySongs(List<SongModel> sorted) {
    emit(state.copyWith(displaySongs: List<SongModel>.from(sorted)));

    // ⭐ لو الترتيب اتغير من أي مكان
    // نحفظه
    AudioPersistenceHelper.saveDisplayOrder(sorted);
  }
}
