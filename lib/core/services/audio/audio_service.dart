import 'package:audio_service/audio_service.dart' as as_pkg;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/core/services/audio/my_audio_handler.dart';

enum PlaybackMode { sequential, repeatOne, shuffle }

class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;

  late MyAudioHandler _handler;

  bool _initialized = false;

  AudioService._internal();

  // ============================================================
  // NOTIFIERS
  // ============================================================

  final ValueNotifier<int?> currentIndexNotifier = ValueNotifier<int?>(null);

  final ValueNotifier<int?> currentSongIdNotifier = ValueNotifier<int?>(null);

  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);

  final ValueNotifier<String?> currentTitleNotifier = ValueNotifier<String?>(
    null,
  );

  final ValueNotifier<String?> currentArtistNotifier = ValueNotifier<String?>(
    null,
  );

  final ValueNotifier<String?> currentPathNotifier = ValueNotifier<String?>(
    null,
  );

  final ValueNotifier<Duration?> sleepTimerRemainingNotifier =
      ValueNotifier<Duration?>(null);

  final ValueNotifier<PlaybackMode> playbackModeNotifier =
      ValueNotifier<PlaybackMode>(PlaybackMode.sequential);

  final ValueNotifier<List<SongModel>> currentQueueNotifier =
      ValueNotifier<List<SongModel>>([]);

  final ValueNotifier<List<SongModel>> originalQueueNotifier =
      ValueNotifier<List<SongModel>>([]);

  final ValueNotifier<List<SongModel>> shuffledQueueNotifier =
      ValueNotifier<List<SongModel>>([]);

  // ============================================================
  // QUEUES
  // ============================================================

  List<SongModel> get currentQueue => currentQueueNotifier.value;

  set currentQueue(List<SongModel> value) {
    currentQueueNotifier.value = List<SongModel>.from(value);
  }

  List<SongModel> get originalQueue => originalQueueNotifier.value;

  set originalQueue(List<SongModel> value) {
    originalQueueNotifier.value = List<SongModel>.from(value);
  }

  List<SongModel> get shuffledQueue => shuffledQueueNotifier.value;

  set shuffledQueue(List<SongModel> value) {
    shuffledQueueNotifier.value = List<SongModel>.from(value);
  }

  // ============================================================
  // INIT
  // ============================================================

  Future<void> init() async {
    if (_initialized) return;

    _handler = await as_pkg.AudioService.init(
      builder: () => MyAudioHandler(),
      config: const as_pkg.AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music.audio',
        androidNotificationChannelName: 'MBMusic',
        androidNotificationChannelDescription: 'Music player controls',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: false,
      ),
    );

    _initialized = true;

    _handler.rawPlayer.playingStream.listen((playing) {
      isPlayingNotifier.value = playing;
    });

    _handler.mediaItem.listen((item) {
      if (item == null) return;

      currentTitleNotifier.value = item.title;

      currentArtistNotifier.value = item.artist;

      currentPathNotifier.value = item.id;

      currentIndexNotifier.value = item.extras?['index'] as int?;

      currentSongIdNotifier.value = item.extras?['songId'] as int?;
    });
  }

  // ============================================================
  // PLAY SONG
  // ============================================================

  Future<void> playSong(
    String path, {
    String? title,
    String? artist,
    int? index,
    int? songId,
    List<SongModel>? queue,
  }) async {
    if (queue != null) {
      currentQueue = queue;

      if (originalQueue.isEmpty) {
        originalQueue = List<SongModel>.from(queue);
      }

      _handler.setQueue(queue);
    }

    await _handler.playSongFromQueue(
      path: path,
      index: index ?? 0,
      title: title ?? 'Unknown',
      artist: artist,
      songId: songId,
      duration:
          queue != null &&
              index != null &&
              index >= 0 &&
              index < queue.length &&
              queue[index].duration != null
          ? Duration(milliseconds: queue[index].duration!)
          : null,
    );
  }

  // ============================================================
  // CONTROLS
  // ============================================================

  Future<void> pause() async => _handler.pause();

  Future<void> resume() async => _handler.play();

  Future<void> stop() async => _handler.stop();

  Future<void> seek(Duration position) async => _handler.seek(position);

  Future<void> playNext() async => _handler.skipToNext();

  Future<void> playPrevious() async => _handler.skipToPrevious();

  Future<void> setSleepTimer(Duration duration) async =>
      _handler.setSleepTimer(duration);

  Future<void> stopSleepTimer() async => _handler.stopSleepTimer();

  // ============================================================
  // PLAY NEXT
  // ============================================================

  void addToPlayNext(SongModel song) {
    _handler.addToPlayNext(song);
  }

  // ============================================================
  // PLAYBACK MODE
  // ============================================================

  void setPlaybackMode(PlaybackMode mode) {
    playbackModeNotifier.value = mode;

    _handler.setPlaybackMode(mode);
  }

  void togglePlaybackMode() {
    final current = playbackModeNotifier.value;

    late PlaybackMode next;

    switch (current) {
      case PlaybackMode.sequential:
        next = PlaybackMode.repeatOne;
        break;

      case PlaybackMode.repeatOne:
        next = PlaybackMode.shuffle;
        break;

      case PlaybackMode.shuffle:
        next = PlaybackMode.sequential;
        break;
    }

    setPlaybackMode(next);
  }

  // ============================================================
  // QUEUE
  // ============================================================

  void updateQueueAndKeepPlaying(List<SongModel> newQueue, int newIndex) {
    currentQueue = List<SongModel>.from(newQueue);

    _handler.updateQueueAndIndex(newQueue, newIndex);
  }

  void setQueue(List<SongModel> queue) {
    currentQueue = List<SongModel>.from(queue);

    _handler.setQueue(queue);
  }

  // ============================================================
  // PLAYER INFO
  // ============================================================

  bool get isPlaying => _handler.rawPlayer.playing;

  Duration? get duration => _handler.rawPlayer.duration;

  Duration get position => _handler.rawPlayer.position;

  Stream<Duration> get positionStream => _handler.rawPlayer.positionStream;

  Stream<PlayerState> get playerStateStream =>
      _handler.rawPlayer.playerStateStream;

  AudioPlayer get player => _handler.rawPlayer;
}
