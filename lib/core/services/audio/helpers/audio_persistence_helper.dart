import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AudioPersistenceHelper {
  static const String _sleepTimerKey = 'sleep_timer_end_time';

  static const String _lastSongPathKey = 'last_song_path';
  static const String _lastSongTitleKey = 'last_song_title';
  static const String _lastSongArtistKey = 'last_song_artist';
  static const String _lastSongIdKey = 'last_song_id';
  static const String _lastSongIndexKey = 'last_song_index';
  static const String _lastSongPositionKey = 'last_song_position';
  static const String _lastSongDurationKey = 'last_song_duration';

  static const String _lastQueueKey = 'last_queue_data';

  static const String _playbackModeKey = 'playback_mode_index';

  // ترتيب الأغاني الظاهر في Home
  static const String _displayOrderKey = 'display_song_order';

  // ============================================================
  // QUEUE
  // ============================================================

  static Future<void> saveQueue(
    List<Map<String, dynamic>> maps,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = maps.map((m) => jsonEncode(m)).toList();

    await prefs.setStringList(
      _lastQueueKey,
      jsonList,
    );
  }

  static Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = prefs.getStringList(_lastQueueKey);

    if (jsonList == null || jsonList.isEmpty) {
      return [];
    }

    return jsonList
        .map(
          (j) => Map<String, dynamic>.from(
            jsonDecode(j) as Map,
          ),
        )
        .toList();
  }

  // ============================================================
  // DISPLAY SONG ORDER
  // ============================================================

  static Future<void> saveDisplayOrder(
    List<SongModel> songs,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final ids = songs
        .map((song) => song.id.toString())
        .toList();

    await prefs.setStringList(
      _displayOrderKey,
      ids,
    );
  }

  static Future<List<int>> getDisplayOrder() async {
    final prefs = await SharedPreferences.getInstance();

    final ids = prefs.getStringList(
      _displayOrderKey,
    );

    if (ids == null || ids.isEmpty) {
      return [];
    }

    return ids
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toList();
  }

  static Future<void> clearDisplayOrder() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      _displayOrderKey,
    );
  }

  // ============================================================
  // SONG METADATA
  // ============================================================

  static Future<void> saveSongMetadata({
    required String path,
    required String title,
    String? artist,
    int? songId,
    int? index,
    Duration? duration,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _lastSongPathKey,
      path,
    );

    await prefs.setString(
      _lastSongTitleKey,
      title,
    );

    await prefs.setString(
      _lastSongArtistKey,
      artist ?? 'Unknown',
    );

    if (songId != null) {
      await prefs.setInt(
        _lastSongIdKey,
        songId,
      );
    }

    if (index != null) {
      await prefs.setInt(
        _lastSongIndexKey,
        index,
      );
    }

    if (duration != null) {
      await prefs.setInt(
        _lastSongDurationKey,
        duration.inMilliseconds,
      );
    }
  }

  // ============================================================
  // POSITION
  // ============================================================

  static Future<void> savePosition(
    Duration pos,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      _lastSongPositionKey,
      pos.inMilliseconds,
    );
  }

  // ============================================================
  // RESTORE PLAYBACK
  // ============================================================

  static Future<Map<String, dynamic>?> restorePlaybackState() async {
    final prefs = await SharedPreferences.getInstance();

    final path = prefs.getString(
      _lastSongPathKey,
    );

    if (path == null) {
      return null;
    }

    final durationMilliseconds =
        prefs.getInt(_lastSongDurationKey);

    return {
      'path': path,
      'title': prefs.getString(_lastSongTitleKey) ?? 'Unknown',
      'artist': prefs.getString(_lastSongArtistKey) ?? 'Unknown',
      'songId': prefs.getInt(_lastSongIdKey),
      'index': prefs.getInt(_lastSongIndexKey),
      'position': Duration(
        milliseconds:
            prefs.getInt(_lastSongPositionKey) ?? 0,
      ),
      'duration': durationMilliseconds != null
          ? Duration(
              milliseconds: durationMilliseconds,
            )
          : null,
    };
  }

  // ============================================================
  // PLAYBACK MODE
  // ============================================================

  static Future<void> savePlaybackMode(
    int modeIndex,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      _playbackModeKey,
      modeIndex,
    );
  }

  static Future<int> getPlaybackMode() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(
          _playbackModeKey,
        ) ??
        0;
  }

  // ============================================================
  // SLEEP TIMER
  // ============================================================

  static Future<void> saveSleepTimerEndTime(
    DateTime endTime,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _sleepTimerKey,
      endTime.toIso8601String(),
    );
  }

  static Future<DateTime?> getSleepTimerEndTime() async {
    final prefs = await SharedPreferences.getInstance();

    final endTimeStr = prefs.getString(
      _sleepTimerKey,
    );

    if (endTimeStr == null) {
      return null;
    }

    return DateTime.parse(endTimeStr);
  }

  static Future<void> clearSleepTimer() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      _sleepTimerKey,
    );
  }
}