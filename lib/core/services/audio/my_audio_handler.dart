import 'dart:async';
import 'dart:developer';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music/core/services/audio/helpers/sleep_timer_handler.dart';
import 'package:music/core/services/audio/helpers/audio_persistence_helper.dart';
import 'package:music/core/services/audio/audio_service.dart' as app_service;
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/core/services/listening_stats_service.dart';
import 'package:music/core/services/song_edit/song_edit_service.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  late final SleepTimerHandler _sleepHandler;

  List<SongModel> _queue = [];
  app_service.PlaybackMode _playbackMode = app_service.PlaybackMode.sequential;
  Duration? _lastSavedPosition;

  MyAudioHandler() {
    _sleepHandler = SleepTimerHandler(onTimerElapsed: () => stop());
    _initInitialState();
    _init();
  }

  AudioPlayer get rawPlayer => _player;

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
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
      ),
    );
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    session.interruptionEventStream.listen((event) {
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
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });

    session.becomingNoisyEventStream.listen((_) {
      pause();
    });

    _sleepHandler.loadPersistentSleepTimer();
    await _restorePlaybackState();

    _player.playingStream.listen(_broadcastState);
    _player.processingStateStream.listen(
      (_) => _broadcastState(_player.playing),
    );
    _player.positionStream.listen(_maybeSavePosition);
    _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) skipToNext();
    });
    _player.durationStream.listen((d) {
      if (mediaItem.value != null && d != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: d));
      }
    });
    FavoritesService().favoriteIdsNotifier.addListener(
      () => _broadcastState(_player.playing),
    );
    _broadcastState(false);
  }

  void setQueue(List<SongModel> songs) {
    _queue = songs;
    queue.add(
      songs
          .map((s) => MediaItem(id: s.data, title: s.title, artist: s.artist))
          .toList(),
    );
    AudioPersistenceHelper.saveQueue(
      songs
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

  void updateQueueAndIndex(List<SongModel> newQueue, int newIndex) {
    _queue = newQueue;
    queue.add(
      newQueue
          .map((s) => MediaItem(id: s.data, title: s.title, artist: s.artist))
          .toList(),
    );

    if (mediaItem.value != null) {
      final item = mediaItem.value!;
      final newExtras = Map<String, dynamic>.from(item.extras ?? {});
      newExtras['index'] = newIndex;
      mediaItem.add(item.copyWith(extras: newExtras));
    }
  }

  void setPlaybackMode(app_service.PlaybackMode mode) {
    _playbackMode = mode;

    // ✅ بيغير القائمة بس من غير ما يبدأ أغنية جديدة
    if (mode == app_service.PlaybackMode.sequential) {
      final audioService = app_service.AudioService();
      if (audioService.originalQueue.isNotEmpty) {
        setQueue(audioService.originalQueue);
        audioService.currentQueue = audioService.originalQueue;
      }
    }

    _player.setLoopMode(
      mode == app_service.PlaybackMode.repeatOne ? LoopMode.one : LoopMode.off,
    );
    app_service.AudioService().playbackModeNotifier.value = mode;
  }

  Future<void> playSongFromQueue({
    required String path,
    required int index,
    required String title,
    String? artist,
    int? songId,
    Duration? duration,
  }) async {
    String finalTitle = title;
    String? finalArtist = artist;

    if (songId != null) {
      final edit = await SongEditService().getEdit(songId);
      if (edit != null) {
        finalTitle = edit['title'] ?? title;
        finalArtist = edit['artist'] ?? artist;
      }
    }

    final item = MediaItem(
      id: path,
      title: finalTitle,
      artist: finalArtist ?? 'Unknown',
      duration: duration,
      artUri: songId != null
          ? Uri.parse('content://media/external/audio/media/$songId/albumart')
          : null,
      extras: {'index': index, 'songId': songId},
    );

    mediaItem.add(item);

    await AudioPersistenceHelper.saveSongMetadata(
      path: path,
      title: finalTitle,
      artist: finalArtist,
      songId: songId,
      index: index,
      duration: duration,
    );

    try {
      await _player.setFilePath(path);
      await _player.play();

      if (songId != null) {
        await ListeningStatsService().recordPlay(
          songId: songId,
          title: finalTitle,
          artist: finalArtist ?? 'Unknown',
        );
      }
    } catch (e) {
      log('❌ Error playing song: $e');
      _broadcastState(false);
    }
  }

  @override
  Future<void> play() async => _player.play();

  @override
  Future<void> pause() async => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async => _player.seek(position);

  @override
  Future<void> skipToNext() => _handleSkip(1);

  @override
  Future<void> skipToPrevious() => _handleSkip(-1);

  Future<void> _handleSkip(int offset) async {
    if (_queue.isEmpty) return;

    final currentIndex = mediaItem.value?.extras?['index'] as int? ?? 0;
    int nextIndex = (currentIndex + offset + _queue.length) % _queue.length;

    final s = _queue[nextIndex];
    playSongFromQueue(
      path: s.data,
      index: nextIndex,
      title: s.title,
      artist: s.artist,
      songId: s.id,
      duration: s.duration != null ? Duration(milliseconds: s.duration!) : null,
    );
  }

  // ✅ 3 controls بس - بيشتغل على كل الأجهزة حتى القديمة
  void _broadcastState(bool playing) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious, // 0
          playing ? MediaControl.pause : MediaControl.play, // 1
          MediaControl.skipToNext, // 2
        ],
        androidCompactActionIndices: const [0, 1, 2],
        processingState:
            const {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[_player.processingState] ??
            AudioProcessingState.idle,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: mediaItem.value?.extras?['index'] as int?,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
      ),
    );
  }

  static const _kActionMode = 'toggle_mode';
  static const _kActionFavorite = 'toggle_favorite';

  MediaControl getModeControl() {
    String icon;
    String label;
    switch (_playbackMode) {
      case app_service.PlaybackMode.repeatOne:
        icon = 'drawable/ic_repeat_one';
        label = 'Repeat One';
        break;
      case app_service.PlaybackMode.shuffle:
        icon = 'drawable/ic_shuffle';
        label = 'Shuffle';
        break;
      default:
        icon = 'drawable/ic_repeat';
        label = 'Sequential';
    }
    return MediaControl.custom(
      androidIcon: icon,
      label: label,
      name: _kActionMode,
    );
  }

  MediaControl get favoriteControl {
    final songId = mediaItem.value?.extras?['songId'] as int?;
    final isFav = songId != null && FavoritesService().isFavorite(songId);
    return MediaControl.custom(
      androidIcon: isFav
          ? 'drawable/ic_favorite'
          : 'drawable/ic_favorite_border',
      label: isFav ? 'Remove from Favorites' : 'Add to Favorites',
      name: _kActionFavorite,
    );
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == _kActionMode) {
      _toggleMode();
    } else if (name == _kActionFavorite) {
      _toggleFavorite();
    }
    return super.customAction(name, extras);
  }

  void _toggleMode() {
    final nextMode = {
      app_service.PlaybackMode.sequential: app_service.PlaybackMode.repeatOne,
      app_service.PlaybackMode.repeatOne: app_service.PlaybackMode.shuffle,
      app_service.PlaybackMode.shuffle: app_service.PlaybackMode.sequential,
    }[_playbackMode]!;
    setPlaybackMode(nextMode);
    _broadcastState(_player.playing);
  }

  void _toggleFavorite() {
    final songId = mediaItem.value?.extras?['songId'] as int?;
    if (songId != null) {
      FavoritesService().toggleFavorite(songId);
    }
  }

  Future<void> _maybeSavePosition(Duration pos) async {
    if (_lastSavedPosition == null ||
        (pos - _lastSavedPosition!).abs() >= const Duration(seconds: 5)) {
      _lastSavedPosition = pos;
      await AudioPersistenceHelper.savePosition(pos);
    }
  }

  Future<void> _restorePlaybackState() async {
    final state = await AudioPersistenceHelper.restorePlaybackState();
    if (state != null) {
      final path = state['path'] as String;
      final songId = state['songId'] as int?;

      final savedQueueRaw = await AudioPersistenceHelper.getQueue();
      if (savedQueueRaw.isNotEmpty) {
        _queue = savedQueueRaw.map((m) => SongModel(m)).toList();
        queue.add(
          _queue
              .map(
                (s) => MediaItem(id: s.data, title: s.title, artist: s.artist),
              )
              .toList(),
        );
      }

      mediaItem.add(
        MediaItem(
          id: path,
          title: state['title'] as String,
          artist: state['artist'] as String,
          duration: state['duration'] as Duration?,
          artUri: songId != null
              ? Uri.parse(
                  'content://media/external/audio/media/$songId/albumart',
                )
              : null,
          extras: {'index': state['index'], 'songId': songId},
        ),
      );

      try {
        await _player.setFilePath(path);
        if (state['position'] != null) {
          await _player.seek(state['position'] as Duration);
        }
      } catch (e) {
        log('Error restoring playback: $e');
      }
    }
  }

  Future<void> setSleepTimer(Duration d) => _sleepHandler.setSleepTimer(d);
  Future<void> stopSleepTimer() => _sleepHandler.stopSleepTimer();
}
