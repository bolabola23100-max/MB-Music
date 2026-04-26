import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/features/sounds/screens/sounds_screen.dart';
import 'package:music/features/favorite/screens/favorites_screen.dart';
import 'package:music/features/home/widgets/home_app_bar_widget.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:music/features/playlist/screens/playlists_screen.dart';
import 'package:music/features/search/screens/search_screen.dart';
import 'package:music/features/home/cubit/home_cubit.dart';
import 'package:music/features/home/cubit/home_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit()..initData(),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final AudioService audioService = AudioService();
    final FavoritesService favoritesService = FavoritesService();

    return DefaultTabController(
      length: 5,
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final cubit = context.read<HomeCubit>();
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.black.withValues(alpha: 0.5),
                  AppColors.black,
                ],
              ),
            ),
            child: Scaffold(
              extendBody: true,
              backgroundColor: Colors.transparent,
              bottomNavigationBar: CurvedNavigationBar(
                backgroundColor: Colors.blueAccent,
                buttonBackgroundColor: Colors.black26,
                items: <Widget>[
                  Icon(Icons.add, size: 30),
                  Icon(Icons.list, size: 30),
                  Icon(Icons.compare_arrows, size: 30),
                ],
                onTap: (index) {
                  cubit.updateCurrentIndex(index);
                },
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    HomeAppBarWidget(
                      songs: state.songs,
                      audioService: audioService,
                      displaySongs: state.displaySongs,
                      onDisplaySongsChanged: (sorted) {
                        cubit.updateDisplaySongs(sorted);
                      },
                    ),
                    Expanded(
                      child: _buildTabView(
                        context,
                        state,
                        audioService,
                        favoritesService,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget _buildBottomNavigationBar(BuildContext context, int currentIndex) {
  //   return Builder(
  //     builder: (context) {
  //       final tabController = DefaultTabController.of(context);
  //       return BottomNavigationBar(
  //         currentIndex: currentIndex,
  //         onTap: (index) {
  //           context.read<HomeCubit>().updateCurrentIndex(index);
  //           tabController.animateTo(index);
  //         },
  //         type: BottomNavigationBarType.fixed,
  //         backgroundColor: Colors.transparent,
  //         elevation: 0,
  //         selectedItemColor: AppColors.blue,
  //         unselectedItemColor: Colors.grey,
  //         items: [
  //           BottomNavigationBarItem(
  //             icon: Image.asset(
  //               AppIcons.sounds,
  //               color: currentIndex == 0 ? AppColors.blue : AppColors.white,
  //               height: 20,
  //               width: 20,
  //             ),
  //             label: 'songs'.tr(),
  //           ),
  //           BottomNavigationBarItem(
  //             icon: SvgPicture.asset(
  //               AppIcons.song,
  //               colorFilter: ColorFilter.mode(
  //                 currentIndex == 1 ? AppColors.blue : AppColors.white,
  //                 BlendMode.srcIn,
  //               ),
  //             ),
  //             label: 'sounds'.tr(),
  //           ),
  //           BottomNavigationBarItem(
  //             icon: SvgPicture.asset(
  //               AppIcons.favorite,
  //               colorFilter: ColorFilter.mode(
  //                 currentIndex == 2 ? AppColors.blue : AppColors.white,
  //                 BlendMode.srcIn,
  //               ),
  //             ),
  //             label: 'favorite'.tr(),
  //           ),
  //           BottomNavigationBarItem(
  //             icon: SvgPicture.asset(
  //               AppIcons.playlist,
  //               colorFilter: ColorFilter.mode(
  //                 currentIndex == 3 ? AppColors.blue : AppColors.white,
  //                 BlendMode.srcIn,
  //               ),
  //             ),
  //             label: 'playlists'.tr(),
  //           ),
  //           BottomNavigationBarItem(
  //             icon: SvgPicture.asset(
  //               AppIcons.search,
  //               colorFilter: ColorFilter.mode(
  //                 currentIndex == 4 ? AppColors.blue : AppColors.white,
  //                 BlendMode.srcIn,
  //               ),
  //             ),
  //             label: 'search'.tr(),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Widget _buildTabView(
    BuildContext context,
    HomeState state,
    AudioService audioService,
    FavoritesService favoritesService,
  ) {
    final cubit = context.read<HomeCubit>();
    return ValueListenableBuilder<Set<int>>(
      valueListenable: favoritesService.favoriteIdsNotifier,
      builder: (context, favoriteIds, _) => TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          SongListWidget(
            key: ValueKey("songs_${state.displaySongs.length}"),
            songs: state.displaySongs,
            audioService: audioService,
            isFavoriteChecker: (s) => favoriteIds.contains(s.id),
            onToggleFavorite: (s) => favoritesService.toggleFavorite(s.id),
            onOptionSelected: cubit.handleSort,
            isTitle: false,
            openPlayerOnSongTap: true,
            onDeleteSongs: cubit.onDeleteSongs,
          ),
          SoundsScreen(
            key: ValueKey("sounds_${state.sounds.length}"),
            songs: state.sounds,
            audioService: audioService,
            onDeleteSongs: cubit.onDeleteSongs,
          ),
          FavoritesScreen(
            key: ValueKey("favs_${favoriteIds.length}_${state.songs.length}"),
            allSongs: state.songs,
            audioService: audioService,
            onDeleteSongs: cubit.onDeleteSongs,
          ),
          const PlaylistsScreen(),
          SearchScreen(
            key: ValueKey("search_${state.songs.length}"),
            allSongs: state.songs,
            onDeleteSongs: cubit.onDeleteSongs,
          ),
        ],
      ),
    );
  }
}
