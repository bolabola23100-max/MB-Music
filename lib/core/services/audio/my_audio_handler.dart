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
import 'package:music/core/services/cache_helper.dart';
import 'package:music/core/services/song_edit/song_edit_service.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  late final AndroidEqualizer _equalizer;
  late final AudioPlayer _player;
  late final SleepTimerHandler _sleepHandler;
  late final Future<void> _initFuture;
  List<SongModel> _queue = [];
  app_service.PlaybackMode _playbackMode = app_service.PlaybackMode.sequential;
  Duration? _lastSavedPosition;
  Future<void> _playbackChain = Future.value();
  int _playbackRequestId = 0;
  int? _requestedIndex;

  MyAudioHandler() {
    _equalizer = AndroidEqualizer();
    _player = AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [_equalizer]));
    _sleepHandler = SleepTimerHandler(onTimerElapsed: () => stop());
    _initInitialState();
    _initFuture = _init();
  }

  Future<void> get ready => _initFuture;
  AudioPlayer get rawPlayer => _player;
  AndroidEqualizer get equalizer => _equalizer;

  void _initInitialState() => playbackState.add(PlaybackState(
    controls: const [MediaControl.skipToPrevious, MediaControl.play, MediaControl.skipToNext],
    systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
    androidCompactActionIndices: const [0, 1, 2],
    processingState: AudioProcessingState.idle, playing: false,
    updatePosition: Duration.zero, bufferedPosition: Duration.zero, speed: 1.0,
  ));

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (event.type == AudioInterruptionType.duck) {
          unawaited(_player.setVolume(0.5));
        } else {
          unawaited(pause());
        }
      } else if (event.type == AudioInterruptionType.duck) {
        unawaited(_player.setVolume(1.0));
      }
    });
    session.becomingNoisyEventStream.listen((_) => unawaited(pause()));
    try { await _sleepHandler.loadPersistentSleepTimer(); } catch (e, s) { log('Sleep timer restore failed: $e', stackTrace: s); }
    try { await _restorePlaybackState(); } catch (e, s) { log('Playback state restore failed: $e', stackTrace: s); }
    _player.playingStream.listen(_broadcastState);
    _player.processingStateStream.listen((_) => _broadcastState(_player.playing));
    _player.positionStream.listen(_maybeSavePosition);
    _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) unawaited(skipToNext());
    });
    _player.durationStream.listen((d) {
      final item = mediaItem.value;
      if (item != null && d != null) mediaItem.add(item.copyWith(duration: d));
    });
    FavoritesService().favoriteIdsNotifier.addListener(() => _broadcastState(_player.playing));
    SongEditService().editNotifier.addListener(_onSongEdited);
    try { await _restoreEqualizer(); } catch (e, s) { log('Equalizer restore failed: $e', stackTrace: s); }
    _broadcastState(false);
  }

  Future<void> _restoreEqualizer() async {
    try {
      await _equalizer.setEnabled(CacheHelper.equalizerEnabled);
      final saved = CacheHelper.equalizerGains;
      final parameters = await _equalizer.parameters;
      for (var i = 0; i < parameters.bands.length; i++) {
        try { await parameters.bands[i].setGain(i < saved.length ? saved[i] : 0.0); } catch (e, s) { log('Equalizer band $i restore failed: $e', stackTrace: s); }
      }
    } catch (e, s) { log('Equalizer initialization unavailable: $e', stackTrace: s); }
  }

  Future<void> _onSongEdited() async {
    final item = mediaItem.value;
    final songId = item?.extras?['songId'] as int?;
    if (item == null || songId == null) return;
    final edit = await SongEditService().getEdit(songId);
    if (edit == null || mediaItem.value?.id != item.id) return;
    final art = edit['artPath'] as String?;
    final updated = item.copyWith(
      title: edit['title'] ?? item.title,
      artist: edit['artist'] ?? item.artist,
      artUri: art != null ? Uri.file(art) : Uri.parse('content://media/external/audio/media/$songId/albumart'),
    );
    mediaItem.add(updated);
    unawaited(AudioPersistenceHelper.saveSongMetadata(path: item.id, title: updated.title, artist: updated.artist, songId: songId, index: item.extras?['index'] as int? ?? 0, duration: item.duration));
  }

  void _setQueue(List<SongModel> songs) {
    _queue = List<SongModel>.from(songs);
    app_service.AudioService().currentQueue = _queue;
    queue.add(
      _queue
          .map((s) => MediaItem(id: s.data, title: s.title, artist: s.artist))
          .toList(),
    );
    unawaited(
      AudioPersistenceHelper.saveQueue(
        _queue
            .map((s) => {
                  '_id': s.id,
                  '_data': s.data,
                  'title': s.title,
                  'artist': s.artist,
                  'duration': s.duration,
                })
            .toList(),
      ),
    );
  }

  void setQueue(List<SongModel> songs) => _setQueue(songs);

  void addToPlayNext(SongModel song) {
    if (_queue.isEmpty) {
      setQueue([song]);
      unawaited(playSongFromQueue(path: song.data, index: 0, title: song.title, artist: song.artist, songId: song.id, duration: song.duration == null ? null : Duration(milliseconds: song.duration!)));
      return;
    }
    final current = _requestedIndex ?? mediaItem.value?.extras?['index'] as int? ?? 0;
    final insert = (current + 1).clamp(0, _queue.length);
    _queue.insert(insert, song);
    app_service.AudioService().currentQueue = _queue;
    queue.add(
      _queue
          .map((s) => MediaItem(id: s.data, title: s.title, artist: s.artist))
          .toList(),
    );
    unawaited(
      AudioPersistenceHelper.saveQueue(
        _queue
            .map((s) => {
                  '_id': s.id,
                  '_data': s.data,
                  'title': s.title,
                  'artist': s.artist,
                  'duration': s.duration,
                })
            .toList(),
      ),
    );
  }

  void updateQueueAndIndex(List<SongModel> newQueue, int newIndex) {
    _setQueue(newQueue);
    final item = mediaItem.value;
    if (item != null) mediaItem.add(item.copyWith(extras: {...item.extras ?? {}, 'index': newIndex}));
    _requestedIndex = newIndex;
  }

  void setPlaybackMode(app_service.PlaybackMode mode) {
    _playbackMode = mode;
    final service = app_service.AudioService();

    if (mode == app_service.PlaybackMode.sequential) {
      if (service.originalQueue.isNotEmpty) {
        _setQueue(service.originalQueue);
        service.shuffledQueue = [];
      }
    } else if (mode == app_service.PlaybackMode.shuffle) {
      final source = service.currentQueue.isNotEmpty
          ? service.currentQueue
          : _queue;
      if (source.isNotEmpty) {
        final shuffled = List<SongModel>.from(source);
        final currentSongId = mediaItem.value?.extras?['songId'] as int?;
        SongModel? currentSong;
        if (currentSongId != null) {
          final currentIndex =
              shuffled.indexWhere((song) => song.id == currentSongId);
          if (currentIndex >= 0) {
            currentSong = shuffled.removeAt(currentIndex);
          }
        }
        shuffled.shuffle();
        if (currentSong != null) {
          shuffled.insert(0, currentSong);
          _requestedIndex = 0;
          final item = mediaItem.value;
          if (item != null) {
            mediaItem.add(item.copyWith(extras: {
              ...item.extras ?? <String, dynamic>{},
              'index': 0,
            }));
          }
        }
        service.shuffledQueue = shuffled;
        _setQueue(shuffled);
      }
    }

    unawaited(
      _player.setLoopMode(
        mode == app_service.PlaybackMode.repeatOne
            ? LoopMode.one
            : LoopMode.off,
      ),
    );
    service.playbackModeNotifier.value = mode;
    unawaited(AudioPersistenceHelper.savePlaybackMode(mode.index));
  }

  Future<void> playSongFromQueue({required String path, required int index, required String title, String? artist, int? songId, Duration? duration}) async {
    final request = ++_playbackRequestId;
    _requestedIndex = index;
    var finalTitle = title;
    var finalArtist = artist;
    final item = MediaItem(id: path, title: finalTitle, artist: finalArtist ?? 'Unknown', duration: duration,
      artUri: songId == null ? null : Uri.parse('content://media/external/audio/media/$songId/albumart'),
      extras: {'index': index, 'songId': songId});
    mediaItem.add(item);
    if (songId != null) {
      unawaited(_loadEditedMetadata(request, songId, item));
    }
    unawaited(AudioPersistenceHelper.saveSongMetadata(path: path, title: finalTitle, artist: finalArtist, songId: songId, index: index, duration: duration));
    await _enqueuePlayback(request, () async {
      await _player.stop();
      log('Loading audio source: $path (songId: $songId)');
      await _setAudioSource(path, songId: songId);
      if (request != _playbackRequestId) {
        await _player.stop();
        return;
      }

      // just_audio's play() future stays pending until playback ends or is
      // interrupted. Do not hold the serialized source-loading queue open for
      // the whole song, otherwise a later tap cannot replace the current track.
      unawaited(_player.play().catchError((Object error, StackTrace stackTrace) {
        log('Audio playback failed for "$path": $error', stackTrace: stackTrace);
        _broadcastState(false);
      }));
    });
  }

  Future<void> _setAudioSource(String path, {int? songId}) async {
    final uri = Uri.tryParse(path);
    final isUriPath = uri != null &&
        (uri.scheme == 'content' ||
            uri.scheme == 'file' ||
            uri.scheme == 'http' ||
            uri.scheme == 'https');

    // Use the exact path returned by the media library first for normal file
    // paths. Some devices expose MediaStore IDs that do not resolve correctly
    // through a reconstructed content URI, which can leave duration at 00:00.
    if (!isUriPath && path.trim().isNotEmpty) {
      try {
        await _player.setFilePath(path);
        return;
      } catch (error, stackTrace) {
        log('File path source failed for "$path"; trying URI fallbacks: $error',
            stackTrace: stackTrace);
        await _player.stop();
      }
    }

    if (isUriPath) {
      try {
        await _player.setAudioSource(AudioSource.uri(uri));
        return;
      } catch (error, stackTrace) {
        log('URI source failed for "$path": $error', stackTrace: stackTrace);
        await _player.stop();
      }
    }

    if (songId != null) {
      final mediaStoreUri =
          Uri.parse('content://media/external/audio/media/$songId');
      try {
        await _player.setAudioSource(AudioSource.uri(mediaStoreUri));
        return;
      } catch (error, stackTrace) {
        log('MediaStore URI fallback failed for song $songId: $error',
            stackTrace: stackTrace);
        await _player.stop();
      }
    }

    // Let the player surface the final error instead of silently keeping an
    // empty source with no duration.
    if (path.trim().isEmpty) {
      throw ArgumentError.value(path, 'path', 'Audio path is empty');
    }
    await _player.setFilePath(path);
  }

  Future<void> _loadEditedMetadata(int request, int songId, MediaItem base) async {
    try {
      final edit = await SongEditService().getEdit(songId);
      if (edit == null || request != _playbackRequestId || mediaItem.value?.id != base.id) return;
      final updated = base.copyWith(title: edit['title'] ?? base.title, artist: edit['artist'] ?? base.artist);
      mediaItem.add(updated);
      unawaited(AudioPersistenceHelper.saveSongMetadata(path: base.id, title: updated.title, artist: updated.artist, songId: songId, index: base.extras?['index'] as int? ?? 0, duration: base.duration));
    } catch (e, s) { log('Edited metadata load failed: $e', stackTrace: s); }
  }

  Future<void> _enqueuePlayback(int request, Future<void> Function() action) {
    final previous = _playbackChain;
    final done = Completer<void>();
    _playbackChain = previous.catchError((_) {}).then((_) async {
      if (request != _playbackRequestId) { if (!done.isCompleted) done.complete(); return; }
      try {
        await action();
      } catch (e, s) {
        log('Playback operation failed for request $request: $e', stackTrace: s);
        _broadcastState(false);
      }
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  @override
  Future<void> play() async {
    // just_audio's play future may remain pending for the entire track.
    // Start playback without blocking the media-session command response.
    unawaited(
      _player.play().catchError((Object error, StackTrace stackTrace) {
        log('Audio playback command failed: $error', stackTrace: stackTrace);
        _broadcastState(false);
      }),
    );
  }

  @override
  Future<void> pause() async {
    ++_playbackRequestId;
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    ++_playbackRequestId;
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(processingState: AudioProcessingState.idle, playing: false));
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async { await _player.seek(position); }

  @override
  Future<void> skipToNext() => _handleSkip(1);

  @override
  Future<void> skipToPrevious() => _handleSkip(-1);

  Future<void> _handleSkip(int offset) async {
    if (_queue.isEmpty) return;

    final current =
        _requestedIndex ?? mediaItem.value?.extras?['index'] as int? ?? 0;

    if (_playbackMode == app_service.PlaybackMode.sequential &&
        offset > 0 &&
        current >= _queue.length - 1) {
      await stop();
      return;
    }

    final next = (current + offset + _queue.length) % _queue.length;
    final song = _queue[next];
    await playSongFromQueue(
      path: song.data,
      index: next,
      title: song.title,
      artist: song.artist,
      songId: song.id,
      duration: song.duration == null
          ? null
          : Duration(milliseconds: song.duration!),
    );
  }

  void _broadcastState(bool playing) => playbackState.add(playbackState.value.copyWith(
    controls: [MediaControl.skipToPrevious, playing ? MediaControl.pause : MediaControl.play, MediaControl.skipToNext, getModeControl(), favoriteControl],
    androidCompactActionIndices: const [0, 1, 2],
    processingState: const {ProcessingState.idle: AudioProcessingState.idle, ProcessingState.loading: AudioProcessingState.loading, ProcessingState.buffering: AudioProcessingState.buffering, ProcessingState.ready: AudioProcessingState.ready, ProcessingState.completed: AudioProcessingState.completed}[_player.processingState] ?? AudioProcessingState.idle,
    playing: playing, updatePosition: _player.position, bufferedPosition: _player.bufferedPosition, speed: _player.speed,
    queueIndex: mediaItem.value?.extras?['index'] as int?, systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
  ));

  static const _kActionMode = 'toggle_mode';
  static const _kActionFavorite = 'toggle_favorite';

  MediaControl getModeControl() {
    final repeat = _playbackMode == app_service.PlaybackMode.repeatOne;
    final shuffle = _playbackMode == app_service.PlaybackMode.shuffle;
    return MediaControl.custom(androidIcon: repeat ? 'drawable/ic_repeat_one' : shuffle ? 'drawable/ic_shuffle' : 'drawable/ic_repeat', label: repeat ? 'Repeat One' : shuffle ? 'Shuffle' : 'Sequential', name: _kActionMode);
  }

  MediaControl get favoriteControl {
    final id = mediaItem.value?.extras?['songId'] as int?;
    final fav = id != null && FavoritesService().isFavorite(id);
    return MediaControl.custom(androidIcon: fav ? 'drawable/ic_favorite' : 'drawable/ic_favorite_border', label: fav ? 'Remove from Favorites' : 'Add to Favorites', name: _kActionFavorite);
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == _kActionMode) _toggleMode();
    if (name == _kActionFavorite) await _toggleFavorite();
    return super.customAction(name, extras);
  }

  void _toggleMode() {
    final next = {app_service.PlaybackMode.sequential: app_service.PlaybackMode.repeatOne, app_service.PlaybackMode.repeatOne: app_service.PlaybackMode.shuffle, app_service.PlaybackMode.shuffle: app_service.PlaybackMode.sequential}[_playbackMode]!;
    setPlaybackMode(next);
    _broadcastState(_player.playing);
  }

  Future<void> _toggleFavorite() async {
    final id = mediaItem.value?.extras?['songId'] as int?;
    if (id != null) { await FavoritesService().toggleFavorite(id); _broadcastState(_player.playing); }
  }

  Future<void> _maybeSavePosition(Duration pos) async {
    if (_lastSavedPosition == null || (pos - _lastSavedPosition!).abs() >= const Duration(seconds: 5)) {
      _lastSavedPosition = pos;
      unawaited(AudioPersistenceHelper.savePosition(pos));
    }
  }

  Future<void> _restorePlaybackState() async {
    final savedMode = await AudioPersistenceHelper.getPlaybackMode();
    if (savedMode >= 0 && savedMode < app_service.PlaybackMode.values.length) {
      _playbackMode = app_service.PlaybackMode.values[savedMode];
      app_service.AudioService().playbackModeNotifier.value = _playbackMode;
      await _player.setLoopMode(_playbackMode == app_service.PlaybackMode.repeatOne ? LoopMode.one : LoopMode.off);
    }
    final state = await AudioPersistenceHelper.restorePlaybackState();
    if (state == null) return;
    final path = state['path'] as String?;
    if (path == null || path.isEmpty) return;
    final songId = state['songId'] as int?;
    final title = state['title'] as String? ?? 'Unknown';
    final artist = state['artist'] as String? ?? 'Unknown';
    final index = state['index'] as int?;
    final position = state['position'] as Duration?;
    final duration = state['duration'] as Duration?;
    final savedQueue = await AudioPersistenceHelper.getQueue();
    if (savedQueue.isNotEmpty) {
      _queue = savedQueue.map(SongModel.new).toList();
      final service = app_service.AudioService();
      service.currentQueue = _queue;
      service.originalQueue = List<SongModel>.from(_queue);
      queue.add(_queue.map((s) => MediaItem(id: s.data, title: s.title, artist: s.artist)).toList());
    }
    await _setAudioSource(path, songId: songId);
    if (position != null) await _player.seek(position);
    _requestedIndex = index;
    mediaItem.add(MediaItem(id: path, title: title, artist: artist, duration: duration, artUri: songId == null ? null : Uri.parse('content://media/external/audio/media/$songId/albumart'), extras: {'index': index, 'songId': songId}));
  }

  Future<void> setSleepTimer(Duration d) => _sleepHandler.setSleepTimer(d);
  Future<void> stopSleepTimer() => _sleepHandler.stopSleepTimer();
}
