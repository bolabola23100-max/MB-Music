import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<void> saveQueue(List<Map<String, dynamic>> maps) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = maps.map((m) => jsonEncode(m)).toList();
    await prefs.setStringList(_lastQueueKey, jsonList);
  }

  static Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_lastQueueKey);
    if (jsonList == null) return [];
    return jsonList.map((j) => jsonDecode(j) as Map<String, dynamic>).toList();
  }

  static Future<void> saveSongMetadata({
    required String path,
    required String title,
    String? artist,
    int? songId,
    int? index,
    Duration? duration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSongPathKey, path);
    await prefs.setString(_lastSongTitleKey, title);
    await prefs.setString(_lastSongArtistKey, artist ?? 'Unknown');
    if (songId != null) await prefs.setInt(_lastSongIdKey, songId);
    if (index != null) await prefs.setInt(_lastSongIndexKey, index);
    if (duration != null) {
      await prefs.setInt(_lastSongDurationKey, duration.inMilliseconds);
    }
  }

  static Future<void> savePosition(Duration pos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSongPositionKey, pos.inMilliseconds);
  }

  static Future<Map<String, dynamic>?> restorePlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_lastSongPathKey);
    if (path == null) return null;

    return {
      'path': path,
      'title': prefs.getString(_lastSongTitleKey) ?? 'Unknown',
      'artist': prefs.getString(_lastSongArtistKey) ?? 'Unknown',
      'songId': prefs.getInt(_lastSongIdKey),
      'index': prefs.getInt(_lastSongIndexKey),
      'position': Duration(milliseconds: prefs.getInt(_lastSongPositionKey) ?? 0),
      'duration': prefs.getInt(_lastSongDurationKey) != null
          ? Duration(milliseconds: prefs.getInt(_lastSongDurationKey)!)
          : null,
    };
  }

  // Sleep Timer Persistence
  static Future<void> saveSleepTimerEndTime(DateTime endTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sleepTimerKey, endTime.toIso8601String());
  }

  static Future<DateTime?> getSleepTimerEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeStr = prefs.getString(_sleepTimerKey);
    return endTimeStr != null ? DateTime.parse(endTimeStr) : null;
  }

  static Future<void> clearSleepTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sleepTimerKey);
  }
}
