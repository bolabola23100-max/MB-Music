import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/features/home/widgets/bottom_nav_bar.dart';
import 'package:music/features/sounds/screens/sounds_screen.dart';
import 'package:music/features/favorite/screens/favorites_screen.dart';
import 'package:music/features/home/widgets/home_app_bar_widget.dart';
import 'package:music/features/home/widgets/home_page_view.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:music/features/playlist/screens/playlists_screen.dart';
import 'package:music/features/search/screens/search_screen.dart';
import 'package:music/features/home/cubit/home_cubit.dart';
import 'package:music/features/home/cubit/home_state.dart';
import 'package:music/features/video/screens/video_albums_screen.dart';
import 'package:music/features/video/services/video_library_service.dart';
import 'package:music/features/video/screens/video_favorites_screen.dart';
import 'package:music/features/video/screens/video_playlists_screen.dart';
import 'package:music/features/video/screens/video_search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(),
      child: const _HomeScreenBody(),
    );
  }
}

class _HomeScreenBody extends StatefulWidget {
  const _HomeScreenBody();

  @override
  State<_HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<_HomeScreenBody> {
  final VideoLibraryService _videoService = VideoLibraryService();
  late PageController _pageController;
  int _localIndex = 0;
  bool _isVideoMode = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (_localIndex == index) return;
    setState(() => _localIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _toggleMode() {
    setState(() {
      _isVideoMode = !_isVideoMode;
      _localIndex = 0;
    });
    _pageController.dispose();
    _pageController = PageController(initialPage: 0);
  }

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();
    final cubit = context.read<HomeCubit>();

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 1200
        ? screenWidth * 0.2
        : screenWidth > 800
        ? screenWidth * 0.1
        : 0.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          HomeAppBarWidget(
            isVideoMode: _isVideoMode,
            onToggleMode: _toggleMode,
          ),
          Expanded(
            child: HomePageView(
              pageController: _pageController,
              isVideoMode: _isVideoMode,
              videoService: _videoService,
              audioService: audioService,
              cubit: cubit,
            ),
          ),
          BottomNavBar(
            currentIndex: _localIndex,
            onTap: _onTabChanged,
            isVideoMode: _isVideoMode,
          ),
        ],
      ),
    );
  }
}
