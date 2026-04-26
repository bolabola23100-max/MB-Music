import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'favorite_state.dart';

class FavoriteCubit extends Cubit<FavoriteState> {
  final FavoritesService _favoritesService = FavoritesService();
  final List<SongModel> _allSongs;

  FavoriteCubit({required List<SongModel> allSongs})
      : _allSongs = allSongs,
        super(const FavoriteState()) {
    _init();
  }

  void _init() {
    _favoritesService.favoriteIdsNotifier.addListener(_onFavoritesChanged);
    _onFavoritesChanged();
  }

  void _onFavoritesChanged() {
    final favoriteIds = _favoritesService.favoriteIdsNotifier.value;
    final favoriteSongs = _allSongs.where((song) => favoriteIds.contains(song.id)).toList();
    emit(state.copyWith(
      favoriteSongs: favoriteSongs,
      favoriteIds: favoriteIds,
    ));
  }

  Future<void> toggleFavorite(int songId) async {
    await _favoritesService.toggleFavorite(songId);
  }

  @override
  Future<void> close() {
    _favoritesService.favoriteIdsNotifier.removeListener(_onFavoritesChanged);
    return super.close();
  }
}
