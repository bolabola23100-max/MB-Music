import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/features/home/widgets/song_options_bottom_sheet.dart';
import 'package:music/features/listening_stats_screen/widgets/extra_stats_list.dart';
import 'package:music/features/listening_stats_screen/widgets/stats_grid_display.dart';
import 'package:music/features/listening_stats_screen/widgets/stats_hero_display.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music/features/listening_stats_screen/cubit/listening_stats_cubit.dart';
import 'package:music/features/listening_stats_screen/cubit/listening_stats_state.dart';

class ListeningStatsScreen extends StatelessWidget {
  final List<SongModel> allSongs;
  final AudioService audioService;

  const ListeningStatsScreen({
    super.key,
    required this.allSongs,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ListeningStatsCubit(),
      child: ListeningStatsView(allSongs: allSongs, audioService: audioService),
    );
  }
}

class ListeningStatsView extends StatefulWidget {
  final List<SongModel> allSongs;
  final AudioService audioService;

  const ListeningStatsView({
    super.key,
    required this.allSongs,
    required this.audioService,
  });

  @override
  State<ListeningStatsView> createState() => _ListeningStatsViewState();
}

class _ListeningStatsViewState extends State<ListeningStatsView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListeningStatsCubit, ListeningStatsState>(
      builder: (context, state) {
        final cubit = context.read<ListeningStatsCubit>();
        if (state.status == ListeningStatsStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
          );
        }

        return GestureDetector(
          onVerticalDragStart: (details) {
            if (_scrollController.hasClients && _scrollController.offset <= 0) {
              cubit.setCanDrag(true);
            } else {
              cubit.setCanDrag(false);
            }
          },
          onVerticalDragUpdate: (details) {
            cubit.updateDrag(details.delta.dy);
          },
          onVerticalDragEnd: (details) {
            if (!state.canDrag) return;
            cubit.setIsDragging(false);
            if (state.offsetY > 150 || (details.primaryVelocity ?? 0) > 600) {
              Navigator.pop(context);
            } else {
              cubit.resetDrag();
            }
          },
          onVerticalDragCancel: cubit.resetDrag,
          child: AnimatedContainer(
            duration: state.isDragging ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, state.offsetY, 0),
            child: Scaffold(
              body: _buildBody(context, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ListeningStatsState state) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildAppHeader(context, state),
            StatsHeroDisplay(topSong: state.topSong),
            const SizedBox(height: 35),
            StatsGridDisplay(
              today: state.todayPlays,
              weekly: state.weeklyPlays,
              monthly: state.monthlyPlays,
              yearly: state.yearlyPlays,
            ),
            const SizedBox(height: 30),
            ExtraStatsList(totalTime: state.totalTimeStreamed),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context, ListeningStatsState state) {
    return Row(
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
              if (state.topSong == null || state.topSong!['song_id'] == null) return;

              final int topSongId = state.topSong!['song_id'] as int;
              final favoritesService = FavoritesService();

              final songIndex = widget.allSongs.indexWhere((s) => s.id == topSongId);

              if (songIndex != -1) {
                final song = widget.allSongs[songIndex];
                SongOptionsBottomSheet.show(
                  context,
                  song: song,
                  index: songIndex,
                  audioService: widget.audioService,
                  isFavoriteChecker: (s) => favoritesService.isFavorite(s.id),
                  onToggleFavorite: (s) => favoritesService.toggleFavorite(s.id),
                  playlist: false,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('stats.not_found'.tr())),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
