import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/core/services/audio/helpers/sleep_timer_handler.dart';
import 'package:music/core/services/audio/helpers/audio_persistence_helper.dart';
import 'package:music/core/services/audio/audio_service.dart'
    as app_service;
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/core/services/listening_stats_service.dart';
import 'package:music/core/services/song_edit/song_edit_service.dart';

class MyAudioHandler extends BaseAudioHandler
    with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  final AudioPlayer _preloadPlayer =
      AudioPlayer();

  late final SleepTimerHandler _sleepHandler;
  late final Future<void> _initFuture;

  List<SongModel> _queue = [];

  app_service.PlaybackMode _playbackMode =
      app_service.PlaybackMode.sequential;

  Duration? _lastSavedPosition;

  MyAudioHandler() {
    _sleepHandler =
        SleepTimerHandler(
      onTimerElapsed: () => stop(),
    );

    _initInitialState();
    _initFuture = _init();
  }

  Future<void> get ready => _initFuture;

  AudioPlayer get rawPlayer => _player;

  // ============================================================
  // INITIAL STATE
  // ============================================================

  void _initInitialState() {
    playbackState.add(
      PlaybackState(
        controls: const [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [
          0,
          1,
          2,
        ],
        processingState:
            AudioProcessingState.idle,
        playing: false,
        updatePosition:
            Duration.zero,
        bufferedPosition:
            Duration.zero,
        speed: 1.0,
      ),
    );
  }

  // ============================================================
  // INIT
  // ============================================================

  Future<void> _init() async {
    final session =
        await AudioSession.instance;

    await session.configure(
      const AudioSessionConfiguration.music(),
    );

    session.interruptionEventStream.listen(
      (event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(0.5);
              break;

            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(1.0);
              break;

            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              break;
          }
        }
      },
    );

    session.becomingNoisyEventStream.listen(
      (_) => pause(),
    );

    await _sleepHandler
        .loadPersistentSleepTimer();

    await _restorePlaybackState();

    _player.playingStream.listen(
      _broadcastState,
    );

    _player.processingStateStream.listen(
      (_) => _broadcastState(
        _player.playing,
      ),
    );

    _player.positionStream.listen(
      _maybeSavePosition,
    );

    _player.playerStateStream.listen(
      (s) {
        if (s.processingState ==
            ProcessingState.completed) {
          skipToNext();
        }
      },
    );

    _player.durationStream.listen(
      (d) {
        if (mediaItem.value != null &&
            d != null) {
          mediaItem.add(
            mediaItem.value!.copyWith(
              duration: d,
            ),
          );
        }
      },
    );

    FavoritesService()
        .favoriteIdsNotifier
        .addListener(
          () => _broadcastState(
            _player.playing,
          ),
        );

    SongEditService()
        .editNotifier
        .addListener(
          _onSongEdited,
        );

    _broadcastState(false);
  }

  // ============================================================
  // EDITED SONG
  // ============================================================

  Future<void> _onSongEdited() async {
    final currentItem =
        mediaItem.value;

    if (currentItem == null) return;

    final songId =
        currentItem.extras?['songId']
            as int?;

    if (songId == null) return;

    final edit =
        await SongEditService()
            .getEdit(songId);

    if (edit == null) return;

    final newTitle =
        edit['title'] ??
        currentItem.title;

    final newArtist =
        edit['artist'] ??
        currentItem.artist;

    final newArtPath =
        edit['artPath'] as String?;

    final updatedItem =
        currentItem.copyWith(
      title: newTitle,
      artist: newArtist,
      artUri: newArtPath != null
          ? Uri.file(newArtPath)
          : Uri.parse(
              'content://media/external/audio/media/$songId/albumart',
            ),
    );

    mediaItem.add(
      updatedItem,
    );

    await AudioPersistenceHelper
        .saveSongMetadata(
      path: currentItem.id,
      title: newTitle,
      artist: newArtist,
      songId: songId,
      index:
          currentItem.extras?['index']
                  as int? ??
              0,
      duration:
          currentItem.duration,
    );
  }

  // ============================================================
  // SET QUEUE
  // ============================================================

  void setQueue(
    List<SongModel> songs,
  ) {
    _queue =
        List<SongModel>.from(songs);

    queue.add(
      _queue
          .map(
            (s) => MediaItem(
              id: s.data,
              title: s.title,
              artist: s.artist,
            ),
          )
          .toList(),
    );

    AudioPersistenceHelper.saveQueue(
      _queue
          .map(
            (s) => {
              '_id': s.id,
              '_data': s.data,
              'title': s.title,
              'artist': s.artist,
              'duration': s.duration,
            },
          )
          .toList(),
    );
  }

  // ============================================================
  // ADD PLAY NEXT
  // ============================================================

  void addToPlayNext(
    SongModel song,
  ) {
    if (_queue.isEmpty) {
      setQueue([song]);

      playSongFromQueue(
        path: song.data,
        index: 0,
        title: song.title,
        artist: song.artist,
        songId: song.id,
        duration: song.duration != null
            ? Duration(
                milliseconds:
                    song.duration!,
              )
            : null,
      );

      return;
    }

    final currentIndex =
        mediaItem.value
                ?.extras?['index']
            as int? ??
        0;

    final insertIndex =
        (currentIndex + 1)
            .clamp(0, _queue.length);

    _queue.insert(
      insertIndex,
      song,
    );

    queue.add(
      _queue
          .map(
            (s) => MediaItem(
              id: s.data,
              title: s.title,
              artist: s.artist,
            ),
          )
          .toList(),
    );

    AudioPersistenceHelper.saveQueue(
      _queue
          .map(
            (s) => {
              '_id': s.id,
              '_data': s.data,
              'title': s.title,
              'artist': s.artist,
              'duration': s.duration,
            },
          )
          .toList(),
    );
  }

  // ============================================================
  // UPDATE QUEUE
  // ============================================================

  void updateQueueAndIndex(
    List<SongModel> newQueue,
    int newIndex,
  ) {
    _queue =
        List<SongModel>.from(newQueue);

    queue.add(
      _queue
          .map(
            (s) => MediaItem(
              id: s.data,
              title: s.title,
              artist: s.artist,
            ),
          )
          .toList(),
    );

    if (mediaItem.value != null) {
      final item =
          mediaItem.value!;

      final extras =
          Map<String, dynamic>.from(
        item.extras ?? {},
      );

      extras['index'] =
          newIndex;

      mediaItem.add(
        item.copyWith(
          extras: extras,
        ),
      );
    }

    AudioPersistenceHelper.saveQueue(
      _queue
          .map(
            (s) => {
              '_id': s.id,
              '_data': s.data,
              'title': s.title,
              'artist': s.artist,
              'duration': s.duration,
            },
          )
          .toList(),
    );
  }

  // ============================================================
  // PLAYBACK MODE
  // ============================================================

  void setPlaybackMode(
    app_service.PlaybackMode mode,
  ) {
    _playbackMode = mode;

    if (mode ==
        app_service.PlaybackMode.sequential) {
      final audioService =
          app_service.AudioService();

      if (audioService
          .originalQueue
          .isNotEmpty) {
        setQueue(
          audioService.originalQueue,
        );

        audioService.currentQueue =
            audioService.originalQueue;
      }
    }

    _player.setLoopMode(
      mode ==
              app_service.PlaybackMode
                  .repeatOne
          ? LoopMode.one
          : LoopMode.off,
    );

    app_service
        .AudioService()
        .playbackModeNotifier
        .value = mode;

    AudioPersistenceHelper
        .savePlaybackMode(
      mode.index,
    );
  }

  // ============================================================
  // PLAY SONG
  // ============================================================

  Future<void> playSongFromQueue({
    required String path,
    required int index,
    required String title,
    String? artist,
    int? songId,
    Duration? duration,
  }) async {
    String finalTitle =
        title;

    String? finalArtist =
        artist;

    if (songId != null) {
      final edit =
          await SongEditService()
              .getEdit(songId);

      if (edit != null) {
        finalTitle =
            edit['title'] ?? title;

        finalArtist =
            edit['artist'] ?? artist;
      }
    }

    final item =
        MediaItem(
      id: path,
      title: finalTitle,
      artist:
          finalArtist ?? 'Unknown',
      duration: duration,
      artUri: songId != null
          ? Uri.parse(
              'content://media/external/audio/media/$songId/albumart',
            )
          : null,
      extras: {
        'index': index,
        'songId': songId,
      },
    );

    mediaItem.add(item);

    await AudioPersistenceHelper
        .saveSongMetadata(
      path: path,
      title: finalTitle,
      artist: finalArtist,
      songId: songId,
      index: index,
      duration: duration,
    );

    try {
      await _player.setFilePath(
        path,
      );

      await _player.play();

      _preloadNext(index);

      if (songId != null) {
        await ListeningStatsService()
            .recordPlay(
          songId: songId,
          title: finalTitle,
          artist:
              finalArtist ?? 'Unknown',
        );
      }
    } catch (e) {
      log(
        '❌ Error playing song: $e',
      );

      _broadcastState(false);
    }
  }

  // ============================================================
  // PLAYER CONTROLS
  // ============================================================

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();

    try {
      await _preloadPlayer.stop();
    } catch (e) {
      log(
        'Error stopping preload player: $e',
      );
    }

    playbackState.add(
      playbackState.value.copyWith(
        processingState:
            AudioProcessingState.idle,
        playing: false,
      ),
    );

    await super.stop();
  }

  @override
  Future<void> seek(
    Duration position,
  ) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() =>
      _handleSkip(1);

  @override
  Future<void> skipToPrevious() =>
      _handleSkip(-1);

  // ============================================================
  // HANDLE SKIP
  // ============================================================

  Future<void> _handleSkip(
    int offset,
  ) async {
    if (_queue.isEmpty) {
      return;
    }

    final currentIndex =
        mediaItem.value
                ?.extras?['index']
            as int? ??
        0;

    final nextIndex =
        (currentIndex +
                offset +
                _queue.length) %
            _queue.length;

    final song =
        _queue[nextIndex];

    await playSongFromQueue(
      path: song.data,
      index: nextIndex,
      title: song.title,
      artist: song.artist,
      songId: song.id,
      duration: song.duration != null
          ? Duration(
              milliseconds:
                  song.duration!,
            )
          : null,
    );
  }

  // ============================================================
  // BROADCAST STATE
  // ============================================================

  void _broadcastState(
    bool playing,
  ) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing
              ? MediaControl.pause
              : MediaControl.play,
          MediaControl.skipToNext,
          getModeControl(),
          favoriteControl,
        ],
        androidCompactActionIndices:
            const [0, 1, 2],
        processingState:
            const {
              ProcessingState.idle:
                  AudioProcessingState.idle,
              ProcessingState.loading:
                  AudioProcessingState.loading,
              ProcessingState.buffering:
                  AudioProcessingState.buffering,
              ProcessingState.ready:
                  AudioProcessingState.ready,
              ProcessingState.completed:
                  AudioProcessingState.completed,
            }[_player.processingState] ??
            AudioProcessingState.idle,
        playing: playing,
        updatePosition:
            _player.position,
        bufferedPosition:
            _player.bufferedPosition,
        speed: _player.speed,
        queueIndex:
            mediaItem.value
                ?.extras?['index']
            as int?,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
      ),
    );
  }

  // ============================================================
  // NOTIFICATION ACTIONS
  // ============================================================

  static const _kActionMode =
      'toggle_mode';

  static const _kActionFavorite =
      'toggle_favorite';

  MediaControl getModeControl() {
    String icon;
    String label;

    switch (_playbackMode) {
      case app_service.PlaybackMode
          .repeatOne:
        icon =
            'drawable/ic_repeat_one';
        label = 'Repeat One';
        break;

      case app_service.PlaybackMode
          .shuffle:
        icon =
            'drawable/ic_shuffle';
        label = 'Shuffle';
        break;

      default:
        icon =
            'drawable/ic_repeat';
        label = 'Sequential';
    }

    return MediaControl.custom(
      androidIcon: icon,
      label: label,
      name: _kActionMode,
    );
  }

  MediaControl get favoriteControl {
    final songId =
        mediaItem.value
                ?.extras?['songId']
            as int?;

    final isFav =
        songId != null &&
        FavoritesService()
            .isFavorite(songId);

    return MediaControl.custom(
      androidIcon: isFav
          ? 'drawable/ic_favorite'
          : 'drawable/ic_favorite_border',
      label: isFav
          ? 'Remove from Favorites'
          : 'Add to Favorites',
      name: _kActionFavorite,
    );
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name ==
        _kActionMode) {
      _toggleMode();
    } else if (name ==
        _kActionFavorite) {
      await _toggleFavorite();
    }

    return super.customAction(
      name,
      extras,
    );
  }

  void _toggleMode() {
    final nextMode = {
      app_service.PlaybackMode
              .sequential:
          app_service.PlaybackMode
              .repeatOne,

      app_service.PlaybackMode
              .repeatOne:
          app_service.PlaybackMode
              .shuffle,

      app_service.PlaybackMode
              .shuffle:
          app_service.PlaybackMode
              .sequential,
    }[_playbackMode]!;

    setPlaybackMode(
      nextMode,
    );

    _broadcastState(
      _player.playing,
    );
  }

  Future<void> _toggleFavorite() async {
    final songId =
        mediaItem.value
                ?.extras?['songId']
            as int?;

    if (songId != null) {
      await FavoritesService().toggleFavorite(songId);
      _broadcastState(_player.playing);
    }
  }

  // ============================================================
  // POSITION
  // ============================================================

  Future<void> _maybeSavePosition(
    Duration pos,
  ) async {
    if (_lastSavedPosition == null ||
        (pos -
                    _lastSavedPosition!)
                .abs() >=
            const Duration(
              seconds: 5,
            )) {
      _lastSavedPosition =
          pos;

      await AudioPersistenceHelper
          .savePosition(pos);
    }
  }

  // ============================================================
  // RESTORE
  // ============================================================

  Future<void> _restorePlaybackState() async {
    final savedModeIndex =
        await AudioPersistenceHelper
            .getPlaybackMode();

    if (savedModeIndex >= 0 &&
        savedModeIndex <
            app_service
                .PlaybackMode
                .values
                .length) {
      final mode =
          app_service
              .PlaybackMode
              .values[savedModeIndex];

      _playbackMode =
          mode;

      app_service
          .AudioService()
          .playbackModeNotifier
          .value = mode;

      await _player.setLoopMode(
        mode ==
                app_service
                    .PlaybackMode
                    .repeatOne
            ? LoopMode.one
            : LoopMode.off,
      );
    }

    final state =
        await AudioPersistenceHelper
            .restorePlaybackState();

    if (state == null) {
      return;
    }

    final path = state['path'] as String?;
    if (path == null || path.isEmpty) {
      return;
    }

    final songId = state['songId'] as int?;
    final title = state['title'] as String? ?? 'Unknown';
    final artist = state['artist'] as String? ?? 'Unknown';
    final index = state['index'] as int?;
    final position = state['position'] as Duration?;
    final duration = state['duration'] as Duration?;

    final savedQueueRaw =
        await AudioPersistenceHelper
            .getQueue();

    if (savedQueueRaw.isNotEmpty) {
      _queue = savedQueueRaw
          .map(
            (m) => SongModel(m),
          )
          .toList();

      app_service
          .AudioService()
          .currentQueue = _queue;
      app_service
          .AudioService()
          .originalQueue = List<SongModel>.from(_queue);

      queue.add(
        _queue
            .map(
              (s) => MediaItem(
                id: s.data,
                title: s.title,
                artist: s.artist,
              ),
            )
            .toList(),
      );
    }

    try {
      await _player.setFilePath(
        path,
      );

      if (position != null) {
        await _player.seek(position);
      }

      mediaItem.add(
        MediaItem(
          id: path,
          title: title,
          artist: artist,
          duration: duration,
          artUri: songId != null
              ? Uri.parse(
                  'content://media/external/audio/media/$songId/albumart',
                )
              : null,
          extras: {
            'index': index,
            'songId': songId,
          },
        ),
      );
    } catch (e) {
      log(
        'Error restoring playback: $e',
      );
    }
  }

  // ============================================================
  // PRELOAD
  // ============================================================

  void _preloadNext(
    int currentIndex,
  ) {
    if (_queue.isEmpty) {
      return;
    }

    final nextIndex = currentIndex + 1;

    if (nextIndex >= _queue.length) {
      return;
    }

    final nextSong =
        _queue[nextIndex];

    log(
      '🔄 Preloading next song: ${nextSong.title}',
    );

    _preloadPlayer
        .setFilePath(nextSong.data)
        .catchError(
          (e) {
            log(
              '⚠️ Error preloading next song: $e',
            );
            return null;
          },
        );
  }

  // ============================================================
  // SLEEP TIMER
  // ============================================================

  Future<void> setSleepTimer(
    Duration d,
  ) =>
      _sleepHandler
          .setSleepTimer(d);

  Future<void> stopSleepTimer() =>
      _sleepHandler
          .stopSleepTimer();
}