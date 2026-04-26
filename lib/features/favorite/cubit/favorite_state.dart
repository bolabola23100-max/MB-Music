import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';

class FavoriteState extends Equatable {
  final List<SongModel> favoriteSongs;
  final Set<int> favoriteIds;

  const FavoriteState({
    this.favoriteSongs = const [],
    this.favoriteIds = const {},
  });

  FavoriteState copyWith({
    List<SongModel>? favoriteSongs,
    Set<int>? favoriteIds,
  }) {
    return FavoriteState(
      favoriteSongs: favoriteSongs ?? this.favoriteSongs,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }

  @override
  List<Object?> get props => [favoriteSongs, favoriteIds];
}
