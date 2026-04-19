import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ListeningStatsService {
  ListeningStatsService._internal();
  static final ListeningStatsService _instance =
      ListeningStatsService._internal();
  factory ListeningStatsService() => _instance;

  static const String _historyKey = 'listening_history';

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _getHistory() async {
    final prefs = await _prefs;
    final String? historyJson = prefs.getString(_historyKey);
    if (historyJson == null) return [];
    try {
      return List<Map<String, dynamic>>.from(json.decode(historyJson));
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveHistory(List<Map<String, dynamic>> history) async {
    final prefs = await _prefs;
    await prefs.setString(_historyKey, json.encode(history));
  }

  Future<void> recordPlay({
    required int songId,
    required String title,
    required String artist,
  }) async {
    final history = await _getHistory();
    history.add({
      'song_id': songId,
      'title': title,
      'artist': artist,
      'played_at': DateTime.now().toIso8601String(),
    });
    
    // Limit history size to prevent SharedPreferences bloat
    if (history.length > 2000) {
      history.removeRange(0, history.length - 2000);
    }
    await _saveHistory(history);
  }

  Future<Map<String, dynamic>?> getTopSongToday() async {
    final history = await _getHistory();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    final filtered = history.where((h) {
      final playedAt = DateTime.tryParse(h['played_at'] ?? '') ?? DateTime(2000);
      return playedAt.isAfter(start) || playedAt.isAtSameMomentAs(start);
    }).toList();

    return _calculateTopSong(filtered);
  }

  Future<Map<String, dynamic>?> getTopSongThisMonth() async {
    final history = await _getHistory();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);

    final filtered = history.where((h) {
      final playedAt = DateTime.tryParse(h['played_at'] ?? '') ?? DateTime(2000);
      return playedAt.isAfter(start) || playedAt.isAtSameMomentAs(start);
    }).toList();

    return _calculateTopSong(filtered);
  }

  Future<Map<String, dynamic>?> getTopSongThisYear() async {
    final history = await _getHistory();
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);

    final filtered = history.where((h) {
      final playedAt = DateTime.tryParse(h['played_at'] ?? '') ?? DateTime(2000);
      return playedAt.isAfter(start) || playedAt.isAtSameMomentAs(start);
    }).toList();

    return _calculateTopSong(filtered);
  }

  Future<Map<String, dynamic>?> getTopSongAllTime() async {
    final history = await _getHistory();
    return _calculateTopSong(history);
  }

  Map<String, dynamic>? _calculateTopSong(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return null;

    final Map<int, int> counts = {};
    final Map<int, Map<String, dynamic>> details = {};

    for (var h in history) {
      final id = h['song_id'] as int;
      counts[id] = (counts[id] ?? 0) + 1;
      details[id] = h;
    }

    int topId = -1;
    int maxCount = -1;

    counts.forEach((id, count) {
      if (count > maxCount) {
        maxCount = count;
        topId = id;
      }
    });

    if (topId == -1) return null;
    return {
      ...details[topId]!,
      'play_count': maxCount,
    };
  }

  Future<int> getPlaysForPeriod(DateTime start, DateTime end) async {
    final history = await _getHistory();
    return history.where((h) {
      final playedAt = DateTime.tryParse(h['played_at'] ?? '') ?? DateTime(2000);
      return (playedAt.isAfter(start) || playedAt.isAtSameMomentAs(start)) &&
             playedAt.isBefore(end);
    }).length;
  }

  Future<List<int>> getLast30DaysActivity() async {
    final history = await _getHistory();
    final now = DateTime.now();
    final List<int> activity = List.filled(30, 0);

    for (var h in history) {
      final playedAt = DateTime.tryParse(h['played_at'] as String? ?? '') ?? DateTime(2000);
      final diff = now.difference(playedAt).inDays;
      if (diff >= 0 && diff < 30) {
        activity[29 - diff]++;
      }
    }
    return activity;
  }
}
