import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/constants/app_colors.dart';
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

  static const double _circleSize = 44; // 🔥 حجم الدائرة
  static const double _barHeight = 55; // 🔥 ارتفاع البار

  static const Duration _pageAnimDuration = Duration(milliseconds: 400);
  static const Curve _pageAnimCurve = Curves.easeInOutCubic;

  static const List<IconData> _icons = [
    Icons.music_note_rounded,
    Icons.graphic_eq_rounded,
    Icons.favorite_rounded,
    Icons.queue_music_rounded,
    Icons.search_rounded,
  ];

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
        bottomNavigationBar: _buildBottomBar(context),
        body: SafeArea(
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

  // ✅ Bottom Bar
  Widget _buildBottomBar(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final itemWidth = width / _icons.length;
    final notchCenterX = itemWidth * _localIndex + itemWidth / 2;

    return SafeArea(
      child: SizedBox(
        height: _barHeight + _circleSize / 2,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // ✅ الشكل المحفور (Notch)
            AnimatedBuilder(
              animation: AlwaysStoppedAnimation(_localIndex.toDouble()),
              builder: (_, __) => CustomPaint(
                painter: _NotchPainter(
                  color: AppColors.gray.withValues(alpha: 0.4),
                  notchCenterX: notchCenterX,

                  circleRadius: _circleSize / 2 + 2,
                  barHeight: _barHeight,
                ),
                child: SizedBox(width: width, height: _barHeight),
              ),
            ),

            // ✅ أيقونات البار
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: _barHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_icons.length, (index) {
                    if (index == _localIndex) {
                      return SizedBox(width: itemWidth);
                    }
                    return SizedBox(
                      width: itemWidth,
                      child: GestureDetector(
                        onTap: () => _onItemTapped(index),
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          _icons[index],
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // ✅ الدائرة الزرقاء المتحركة
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _barHeight - _circleSize / 2,
              left: notchCenterX - _circleSize / 2,
              child: GestureDetector(
                onTap: () => _onItemTapped(_localIndex),
                child: Container(
                  width: _circleSize,
                  height: _circleSize,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icons[_localIndex],
                    size: 22,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
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

// ✅ CustomPainter للـ Notch المحفور
class _NotchPainter extends CustomPainter {
  final Color color;
  final double notchCenterX;
  final double circleRadius;
  final double barHeight;

  _NotchPainter({
    required this.color,
    required this.notchCenterX,
    required this.circleRadius,
    required this.barHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    const double notchMargin = 10;
    final double notchLeft = notchCenterX - circleRadius - notchMargin;
    final double notchRight = notchCenterX + circleRadius + notchMargin;
    const double curveDepth = 12;

    path.moveTo(0, 0);
    path.lineTo(notchLeft - 20, 0);

    // ✅ منحنى يسار
    path.quadraticBezierTo(notchLeft, 0, notchLeft + 10, curveDepth);

    // ✅ القوس المحفور
    path.arcToPoint(
      Offset(notchRight - 10, curveDepth),
      radius: Radius.circular(circleRadius + notchMargin),
      clockwise: false,
    );

    // ✅ منحنى يمين
    path.quadraticBezierTo(notchRight, 0, notchRight + 20, 0);

    path.lineTo(size.width, 0);
    path.lineTo(size.width, barHeight);
    path.lineTo(0, barHeight);
    path.close();

    // ✅ تقويس الزوايا
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, barHeight),
        const Radius.circular(20),
      ),
      paint,
    );

    // ✅ رسم الـ Notch
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_NotchPainter oldDelegate) =>
      oldDelegate.notchCenterX != notchCenterX;
}
