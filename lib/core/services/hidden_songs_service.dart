import 'package:shared_preferences/shared_preferences.dart';

class HiddenSongsService {
  static final HiddenSongsService _instance = HiddenSongsService._internal();
  factory HiddenSongsService() => _instance;
  HiddenSongsService._internal();

  static const String _key = 'hidden_song_ids';
  Set<int> _hiddenIds = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    _hiddenIds = list.map(int.parse).toSet();
  }

  Future<void> hideSong(int songId) async {
    _hiddenIds.add(songId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _hiddenIds.map((e) => e.toString()).toList(),
    );
  }

  Future<void> hideSongs(Iterable<int> songIds) async {
    _hiddenIds.addAll(songIds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _hiddenIds.map((e) => e.toString()).toList(),
    );
  }

  bool isHidden(int songId) {
    return _hiddenIds.contains(songId);
  }

  List<T> filterHidden<T>(List<T> songs, int Function(T) idGetter) {
    return songs.where((s) => !isHidden(idGetter(s))).toList();
  }
}
