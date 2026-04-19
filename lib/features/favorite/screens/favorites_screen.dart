import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:easy_localization/easy_localization.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.allSongs,
    required this.audioService,
    this.onDeleteSongs,
  });

  final List<SongModel> allSongs;
  final AudioService audioService;
  final Future<void> Function(List<SongModel> songs)? onDeleteSongs;

  @override
  Widget build(BuildContext context) {
    final favoritesService = FavoritesService();

    return ValueListenableBuilder<Set<int>>(
      valueListenable: favoritesService.favoriteIdsNotifier,
      builder: (context, favoriteIds, _) {
        final favoriteSongs = allSongs
            .where((song) => favoriteIds.contains(song.id))
            .toList();

        if (favoriteSongs.isEmpty) {
          return const _EmptyFavoritesView();
        }

        return SongListWidget(
          songs: favoriteSongs,
          audioService: audioService,
          isFavoriteChecker: (song) => favoriteIds.contains(song.id),
          onToggleFavorite: (song) async {
            await favoritesService.toggleFavorite(song.id);
          },
          onDeleteSongs: onDeleteSongs,
          title: "favorites_title".tr(),
          subtitle: "favorite_songs_subtitle".tr(),
        );
      },
    );
  }
}

class _EmptyFavoritesView extends StatelessWidget {
  const _EmptyFavoritesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: AppColors.blue, size: 70),
            const SizedBox(height: 16),
            Text(
              "no_favorites".tr(),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "add_favorites_hint".tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
