import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoFavoritesService {
  VideoFavoritesService._internal();
  static final VideoFavoritesService _instance = VideoFavoritesService._internal();
  factory VideoFavoritesService() => _instance;

  static const String _key = 'favorite_video_ids';
  final ValueNotifier<Set<String>> favoriteIdsNotifier = ValueNotifier(<String>{});

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    favoriteIdsNotifier.value = (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  bool isFavorite(String id) => favoriteIdsNotifier.value.contains(id);

  Future<void> toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = Set<String>.from(favoriteIdsNotifier.value);
    if (!ids.add(id)) ids.remove(id);
    favoriteIdsNotifier.value = ids;
    await prefs.setStringList(_key, ids.toList());
  }
}
