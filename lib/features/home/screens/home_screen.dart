import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/core/services/hidden_songs_service.dart';
import 'package:music/features/sounds/screens/sounds_screen.dart';
import 'package:music/features/favorite/screens/favorites_screen.dart';
import 'package:music/features/home/widgets/home_app_bar_widget.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:music/core/services/playlist/playlist_service.dart';
import 'package:music/features/playlist/screens/playlists_screen.dart';
import 'package:music/features/search/screens/search_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<SongModel> _originalSongs = [];
  List<SongModel> songs = [];
  List<SongModel> displaySongs = [];
  List<SongModel> sounds = [];

  final OnAudioQuery audioQuery = OnAudioQuery();
  final AudioService audioService = AudioService();
  final FavoritesService favoritesService = FavoritesService();

  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentIndex = _tabController.index);
      }
    });

    _initData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await [
      Permission.storage,
      Permission.audio,
      Permission.notification,
    ].request();

    await HiddenSongsService().init();

    final queried = await audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
    );

    // ✅ Filter out durations < 1 min and hidden songs
    final songsList = HiddenSongsService().filterHidden(queried, (s) => s.id);

    final filtered = songsList
        .where((s) => (s.duration ?? 0) >= 60000)
        .toList();
    final filteredSounds = songsList
        .where((s) => (s.duration ?? 0) < 60000)
        .toList();

    setState(() {
      _originalSongs = List.from(filtered);
      songs = List.from(filtered);
      displaySongs = List.from(filtered);
      sounds = List.from(filteredSounds);
    });
  }

  void _handleSort(SongSortOption option) async {
    List<SongModel> newList = List.from(
      displaySongs.isNotEmpty ? displaySongs : songs,
    );

    if (option == SongSortOption.newestFirst) {
      newList = List.from(_originalSongs);
    } else if (option == SongSortOption.oldestFirst) {
      newList = List.from(_originalSongs.reversed);
    } else if (option == SongSortOption.shufflePlay) {
      newList = List.from(displaySongs.isNotEmpty ? displaySongs : songs);
      newList.shuffle();
      audioService.currentQueue = newList;
    } else if (option == SongSortOption.orderedPlay) {
      newList = List.from(displaySongs.isNotEmpty ? displaySongs : songs);
      audioService.currentQueue = newList;
    }

    setState(() {
      displaySongs = newList;
    });

    if (option == SongSortOption.orderedPlay ||
        option == SongSortOption.shufflePlay) {
      if (displaySongs.isNotEmpty) await _playAtIndex(0);
    }
  }

  Future<void> _playAtIndex(int index) async {
    final s = displaySongs[index];
    await audioService.playSong(
      s.data,
      title: s.title,
      artist: s.artist,
      index: index,
      songId: s.id,
      queue: displaySongs,
    );
  }

  Future<void> _onDeleteSongs(List<SongModel> deletedSongs) async {
    final deletedIds = deletedSongs.map((s) => s.id).toSet();
    final playlistService = PlaylistService();

    for (final song in deletedSongs) {
      // 1. Remove from Favorites if exists
      if (favoritesService.isFavorite(song.id)) {
        await favoritesService.toggleFavorite(song.id);
      }
      // 2. Remove from all Playlists in DB
      await playlistService.removeSongFromAllPlaylists(song.id);
    }

    // 3. Mark as hidden permanently in App
    await HiddenSongsService().hideSongs(deletedIds);

    setState(() {
      // ✅ Create NEW lists so Flutter detects the reference change and rebuilds widgets
      _originalSongs = _originalSongs
          .where((s) => !deletedIds.contains(s.id))
          .toList();
      songs = songs.where((s) => !deletedIds.contains(s.id)).toList();
      displaySongs = displaySongs
          .where((s) => !deletedIds.contains(s.id))
          .toList();
      sounds = sounds.where((s) => !deletedIds.contains(s.id)).toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1A1A1A), AppColors.black],
        ),
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.blue,
          unselectedItemColor: Colors.grey,

          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                AppIcons.sounds,
                color: _currentIndex == 0 ? AppColors.blue : AppColors.white,
                height: 20,
                width: 20,
              ),
              label: 'songs'.tr(),
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                AppIcons.song,
                colorFilter: ColorFilter.mode(
                  _currentIndex == 1 ? AppColors.blue : AppColors.white,
                  BlendMode.srcIn,
                ),
              ),
              label: 'sounds'.tr(),
            ),

            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                AppIcons.favorite,
                colorFilter: ColorFilter.mode(
                  _currentIndex == 2 ? AppColors.blue : AppColors.white,
                  BlendMode.srcIn,
                ),
              ),
              label: 'favorite'.tr(),
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                AppIcons.playlist,
                colorFilter: ColorFilter.mode(
                  _currentIndex == 3 ? AppColors.blue : AppColors.white,
                  BlendMode.srcIn,
                ),
              ),
              label: 'playlists'.tr(),
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                AppIcons.search,
                colorFilter: ColorFilter.mode(
                  _currentIndex == 4 ? AppColors.blue : AppColors.white,
                  BlendMode.srcIn,
                ),
              ),
              label: 'search'.tr(),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              HomeAppBarWidget(
                songs: songs,
                audioService: audioService,
                displaySongs: displaySongs,
                onDisplaySongsChanged: (sorted) {
                  setState(() => displaySongs = sorted);
                },
              ),
              Expanded(child: _buildTabView()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabView() {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: favoritesService.favoriteIdsNotifier,
      builder: (context, favoriteIds, _) => TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          SongListWidget(
            key: ValueKey("songs_${displaySongs.length}"), // ✅ Force refresh
            songs: displaySongs,
            audioService: audioService,
            isFavoriteChecker: (s) => favoriteIds.contains(s.id),
            onToggleFavorite: (s) => favoritesService.toggleFavorite(s.id),
            onOptionSelected: _handleSort,
            isTitle: false,
            openPlayerOnSongTap: true,
            onDeleteSongs: _onDeleteSongs,
          ),
          SoundsScreen(
            key: ValueKey("sounds_${sounds.length}"), // ✅ Force refresh
            songs: sounds,
            audioService: audioService,
            onDeleteSongs: _onDeleteSongs,
          ),
          FavoritesScreen(
            key: ValueKey(
              "favs_${favoriteIds.length}_${songs.length}",
            ), // ✅ Force refresh
            allSongs: songs,
            audioService: audioService,
            onDeleteSongs: _onDeleteSongs,
          ),
          const PlaylistsScreen(),
          SearchScreen(
            key: ValueKey("search_${songs.length}"),
            allSongs: songs,
            onDeleteSongs: _onDeleteSongs,
          ),
        ],
      ),
    );
  }
}
