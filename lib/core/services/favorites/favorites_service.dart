import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  FavoritesService._internal();
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;

  static const String _favoritesKey = 'favorite_song_ids';

  final ValueNotifier<Set<int>> favoriteIdsNotifier = ValueNotifier(<int>{});

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_favoritesKey) ?? [];

    favoriteIdsNotifier.value = ids.map(int.parse).toSet();
  }

  Future<void> toggleFavorite(int songId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentFavorites = Set<int>.from(favoriteIdsNotifier.value);

    if (currentFavorites.contains(songId)) {
      currentFavorites.remove(songId);
    } else {
      currentFavorites.add(songId);
    }

    favoriteIdsNotifier.value = currentFavorites;

    await prefs.setStringList(
      _favoritesKey,
      currentFavorites.map((id) => id.toString()).toList(),
    );
  }

  bool isFavorite(int songId) {
    return favoriteIdsNotifier.value.contains(songId);
  }
}
