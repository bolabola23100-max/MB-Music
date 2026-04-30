import 'package:curved_navigation_bar/curved_navigation_bar.dart';
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

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late PageController _pageController;

  int _localIndex = 0;

  @override
  void initState() {
    super.initState();
    _localIndex = context.read<HomeCubit>().state.currentIndex;
    _pageController = PageController(initialPage: _localIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AudioService audioService = AudioService();
    final FavoritesService favoritesService = FavoritesService();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.black.withValues(alpha: 0.5), AppColors.black],
        ),
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        bottomNavigationBar: BlocSelector<HomeCubit, HomeState, int>(
          selector: (state) => state.currentIndex,
          builder: (context, currentIndex) {
            _localIndex = currentIndex;
            return _buildBottomNavigationBar(context, currentIndex);
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              BlocBuilder<HomeCubit, HomeState>(
                buildWhen: (p, c) =>
                    p.songs != c.songs || p.displaySongs != c.displaySongs,
                builder: (context, state) => HomeAppBarWidget(
                  songs: state.songs,
                  audioService: audioService,
                  displaySongs: state.displaySongs,
                  onDisplaySongsChanged: (sorted) {
                    context.read<HomeCubit>().updateDisplaySongs(sorted);
                  },
                  onRescan: () => context.read<HomeCubit>().initData(),
                ),
              ),
              Expanded(
                child: RepaintBoundary(
                  child: BlocListener<HomeCubit, HomeState>(
                    listenWhen: (p, c) => p.currentIndex != c.currentIndex,
                    listener: (context, state) {
                      if (_pageController.hasClients) {
                        final currentPage = _pageController.page?.round() ?? 0;
                        if (currentPage != state.currentIndex) {
                          _pageController.jumpToPage(state.currentIndex);
                        }
                      }
                    },
                    child: _buildPageView(
                      context,
                      audioService,
                      favoritesService,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, int currentIndex) {
    return RepaintBoundary(
      child: CurvedNavigationBar(
        key: const ValueKey('curved_nav_bar'),
        index: _localIndex,
        height: 60,
        backgroundColor: Colors.transparent,
        color: AppColors.gray.withValues(alpha: 0.4),
        buttonBackgroundColor: AppColors.blue,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeOutCubic,
        items: <Widget>[
          _buildNavItem(AppIcons.sounds, _localIndex == 0, isSvg: false),
          _buildNavItem(AppIcons.song, _localIndex == 1),
          _buildNavItem(AppIcons.favorite, _localIndex == 2),
          _buildNavItem(AppIcons.playlist, _localIndex == 3),
          _buildNavItem(AppIcons.search, _localIndex == 4),
        ],
        onTap: (index) {
          if (index != _localIndex) {
            setState(() {
              _localIndex = index;
            });
            context.read<HomeCubit>().updateCurrentIndex(index);
          }
        },
      ),
    );
  }

  Widget _buildNavItem(String iconPath, bool isSelected, {bool isSvg = true}) {
    final Color color = isSelected ? AppColors.black : AppColors.white;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: isSvg
          ? SvgPicture.asset(
              iconPath,
              height: 24,
              width: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            )
          : Image.asset(iconPath, height: 24, width: 24, color: color),
    );
  }

  Widget _buildPageView(
    BuildContext context,
    AudioService audioService,
    FavoritesService favoritesService,
  ) {
    final cubit = context.read<HomeCubit>();
    return PageView(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        if (index != _localIndex) {
          setState(() {
            _localIndex = index;
          });
          context.read<HomeCubit>().updateCurrentIndex(index);
        }
      },
      children: [
        BlocBuilder<HomeCubit, HomeState>(
          buildWhen: (p, c) => p.displaySongs != c.displaySongs,
          builder: (context, state) => SongListWidget(
            key: const PageStorageKey("songs_list"),
            songs: state.displaySongs,
            audioService: audioService,
            isFavoriteChecker: (s) =>
                favoritesService.favoriteIdsNotifier.value.contains(s.id),
            onToggleFavorite: (s) => favoritesService.toggleFavorite(s.id),
            onOptionSelected: cubit.handleSort,
            isTitle: false,
            openPlayerOnSongTap: true,
            onDeleteSongs: cubit.onDeleteSongs,
            isf: false,
          ),
        ),
        BlocBuilder<HomeCubit, HomeState>(
          buildWhen: (p, c) => p.sounds != c.sounds,
          builder: (context, state) => SoundsScreen(
            key: const PageStorageKey("sounds_screen"),
            songs: state.sounds,
            audioService: audioService,
            onDeleteSongs: cubit.onDeleteSongs,
          ),
        ),
        BlocBuilder<HomeCubit, HomeState>(
          buildWhen: (p, c) => p.songs != c.songs,
          builder: (context, state) => FavoritesScreen(
            key: const PageStorageKey("favs_screen"),
            allSongs: state.songs,
            audioService: audioService,
            onDeleteSongs: cubit.onDeleteSongs,
          ),
        ),
        const PlaylistsScreen(key: PageStorageKey("playlists_screen")),
        BlocBuilder<HomeCubit, HomeState>(
          buildWhen: (p, c) => p.songs != c.songs,
          builder: (context, state) => SearchScreen(
            key: const PageStorageKey("search_screen"),
            allSongs: state.songs,
            onDeleteSongs: cubit.onDeleteSongs,
          ),
        ),
      ],
    );
  }
}
