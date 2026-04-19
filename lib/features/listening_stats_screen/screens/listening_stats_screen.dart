import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/core/services/listening_stats_service.dart';
import 'package:music/features/home/widgets/song_options_bottom_sheet.dart';
import 'package:music/features/listening_stats_screen/widgets/extra_stats_list.dart';
import 'package:music/features/listening_stats_screen/widgets/stats_grid_display.dart';
import 'package:music/features/listening_stats_screen/widgets/stats_hero_display.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Main screen for displaying listening statistics and insights.
class ListeningStatsScreen extends StatefulWidget {
  final List<SongModel> allSongs;
  final AudioService audioService;

  const ListeningStatsScreen({
    super.key,
    required this.allSongs,
    required this.audioService,
  });

  @override
  State<ListeningStatsScreen> createState() => _ListeningStatsScreenState();
}

class _ListeningStatsScreenState extends State<ListeningStatsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _topSong;
  int _todayPlays = 0;
  int _weeklyPlays = 0;
  int _monthlyPlays = 0;
  int _yearlyPlays = 0;
  int _totalTimeStreamed = 0;
  double offsetY = 0;
  bool canDrag = false;
  bool _isDragging = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadAllStats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Loads all stats from the service and updates the UI.
  Future<void> _loadAllStats() async {
    final service = ListeningStatsService();
    final now = DateTime.now();

    // Fetch data in parallel for better performance
    final results = await Future.wait([
      service.getTopSongAllTime(),
      service.getPlaysForPeriod(
        DateTime(now.year, now.month, now.day),
        now.add(const Duration(days: 1)),
      ),
      service.getPlaysForPeriod(
        DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1)),
        now.add(const Duration(days: 1)),
      ),
      service.getPlaysForPeriod(
        DateTime(now.year, now.month, 1),
        now.add(const Duration(days: 1)),
      ),
      service.getPlaysForPeriod(
        DateTime(now.year, 1, 1),
        now.add(const Duration(days: 1)),
      ),
    ]);

    if (mounted) {
      setState(() {
        _topSong = results[0] as Map<String, dynamic>?;
        _todayPlays = results[1] as int;
        _weeklyPlays = results[2] as int;
        _monthlyPlays = results[3] as int;
        _yearlyPlays = results[4] as int;
        // Estimate listening time (3 mins per song)
        _totalTimeStreamed = _yearlyPlays * 3;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        // Allow dragging only if we are at the top of the scroll view
        if (_scrollController.hasClients && _scrollController.offset <= 0) {
          canDrag = true;
          _isDragging = true;
        } else {
          canDrag = false;
        }
      },
      onVerticalDragUpdate: (details) {
        if (!canDrag) return;

        setState(() {
          // Allow smooth up/down movement while dragging
          offsetY = (offsetY + details.delta.dy).clamp(0.0, double.infinity);
        });
      },
      onVerticalDragEnd: (details) {
        if (!canDrag) return;

        setState(() => _isDragging = false);

        // Reduced thresholds: 150px or flick velocity > 600
        if (offsetY > 150 || (details.primaryVelocity ?? 0) > 600) {
          Navigator.pop(context);
        } else {
          setState(() {
            offsetY = 0;
            canDrag = false;
          });
        }
      },
      onVerticalDragCancel: () {
        if (canDrag) {
          setState(() {
            offsetY = 0;
            _isDragging = false;
            canDrag = false;
          });
        }
      },
      child: AnimatedContainer(
        // Duration is 0 while dragging for instant feedback, 200ms for smooth reset
        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, offsetY, 0),
        child: Scaffold(
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.blue),
                )
              : _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 80),
                  child: Text(
                    'stats.insights'.tr(),
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 30),
                  child: IconButton(
                    icon: const Icon(Icons.more_vert, color: AppColors.white),
                    onPressed: () {
                      if (_topSong == null || _topSong!['song_id'] == null)
                        return;

                      final int topSongId = _topSong!['song_id'] as int;
                      final favoritesService = FavoritesService();

                      // Find the SongModel in allSongs by its ID
                      final songIndex = widget.allSongs.indexWhere(
                        (s) => s.id == topSongId,
                      );

                      if (songIndex != -1) {
                        final song = widget.allSongs[songIndex];
                        SongOptionsBottomSheet.show(
                          context,
                          song: song,
                          index: songIndex,
                          audioService: widget.audioService,
                          isFavoriteChecker: (s) =>
                              favoritesService.isFavorite(s.id),
                          onToggleFavorite: (s) =>
                              favoritesService.toggleFavorite(s.id),
                          playlist: false,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('stats.not_found'.tr()),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            StatsHeroDisplay(topSong: _topSong),
            const SizedBox(height: 35),
            StatsGridDisplay(
              today: _todayPlays,
              weekly: _weeklyPlays,
              monthly: _monthlyPlays,
              yearly: _yearlyPlays,
            ),
            const SizedBox(height: 30),
            ExtraStatsList(totalTime: _totalTimeStreamed),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
