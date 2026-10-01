import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/features/home/widgets/bottom_nav_bar.dart';
import 'package:music/features/sounds/screens/sounds_screen.dart';
import 'package:music/features/favorite/screens/favorites_screen.dart';
import 'package:music/features/home/widgets/home_app_bar_widget.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:music/features/playlist/screens/playlists_screen.dart';
import 'package:music/features/search/screens/search_screen.dart';
import 'package:music/features/home/cubit/home_cubit.dart';
import 'package:music/features/home/cubit/home_state.dart';

// bottomNavigationBar
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

  static const Duration _pageAnimDuration = Duration(milliseconds: 400);
  static const Curve _pageAnimCurve = Curves.easeInOutCubic;

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

  Future<void> _animateToPage(int index) async {
    if (!_pageController.hasClients) return;
    final currentPage = _pageController.page?.round() ?? 0;
    if (currentPage == index) return;

    final diff = (index - currentPage).abs();
    if (diff > 1) {
      _pageController.jumpToPage(index > currentPage ? index - 1 : index + 1);
    }

    await _pageController.animateToPage(
      index,
      duration: _pageAnimDuration,
      curve: _pageAnimCurve,
    );
  }

  void _onItemTapped(int index) {
    if (index == _localIndex) return;
    setState(() => _localIndex = index);
    _animateToPage(index);
    context.read<HomeCubit>().updateCurrentIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();
    final favoritesService = FavoritesService();
    final cubit = context.read<HomeCubit>();

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 1200
        ? screenWidth * 0.2
        : screenWidth > 800
        ? screenWidth * 0.1
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.transparent],
        ),
      ),
      child: Scaffold(
        extendBody: true,

        backgroundColor: Colors.transparent,
        bottomNavigationBar: BottomNavBar(
          currentIndex: _localIndex,
          onTap: _onItemTapped,
        ),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                // ✅ AppBar
                BlocBuilder<HomeCubit, HomeState>(
                  buildWhen: (p, c) =>
                      p.songs != c.songs || p.displaySongs != c.displaySongs,
                  builder: (context, state) => HomeAppBarWidget(
                    songs: state.songs,
                    audioService: audioService,
                    displaySongs: state.displaySongs,
                    onDisplaySongsChanged: cubit.updateDisplaySongs,
                    onRescan: cubit.initData,
                  ),
                ),

                // ✅ PageView
                Expanded(
                  child: RepaintBoundary(
                    child: BlocListener<HomeCubit, HomeState>(
                      listenWhen: (p, c) => p.currentIndex != c.currentIndex,
                      listener: (context, state) {
                        _animateToPage(state.currentIndex);
                      },
                      child: _buildPageView(
                        context,
                        audioService,
                        favoritesService,
                        cubit,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ PageView
  Widget _buildPageView(
    BuildContext context,
    AudioService audioService,
    FavoritesService favoritesService,
    HomeCubit cubit,
  ) {
    return PageView(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        setState(() => _localIndex = index);
        cubit.updateCurrentIndex(index);
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
