import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:music/features/playlist/screens/playlist_details_screen.dart';
import 'package:music/features/playlist/widgets/empty_playlists_state.dart';
import 'package:music/features/playlist/widgets/playlist_dialogs.dart';
import 'package:music/features/playlist/widgets/playlist_grid.dart';
import 'package:music/features/playlist/widgets/playlist_menu_bottom_sheet.dart';
import 'package:music/features/playlist/cubit/playlist_cubit.dart';
import 'package:music/features/playlist/cubit/playlist_state.dart';
import 'package:music/features/home/cubit/home_cubit.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlaylistCubit()..loadPlaylists(),
      child: const PlaylistsView(),
    );
  }
}

class PlaylistsView extends StatelessWidget {
  const PlaylistsView({super.key});

  void _showPlaylistMenu(BuildContext context, PlaylistModels playlist) {
    final cubit = context.read<PlaylistCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.gray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => PlaylistMenuBottomSheet(
        playlist: playlist,
        onRename: () {
          Navigator.pop(context);
          PlaylistDialogs.showRenameDialog(
            context,
            playlist,
            cubit.loadPlaylists,
          );
        },
        onDelete: () {
          Navigator.pop(context);
          PlaylistDialogs.showDeleteDialog(
            context,
            playlist,
            cubit.loadPlaylists,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaylistCubit, PlaylistState>(
      builder: (context, state) {
        // final cubit = context.read<PlaylistCubit>();
        return Scaffold(
          backgroundColor: AppColors.gray.withOpacity(0.01),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 15),
                _buildBody(context, state),
                const SizedBox(height: 100),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => PlaylistDialogs.showCreateDialog(context, (id) {
              final cubit = context.read<PlaylistCubit>();
              final homeCubit = context.read<HomeCubit>();
              cubit.loadPlaylists();
              PlaylistDialogs.showAddSongsDialog(
                context,
                id,
                homeCubit.state.songs,
                cubit.loadPlaylists,
              );
            }),
            backgroundColor: const Color(0xFF00C8FF),
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.black, size: 30),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PlaylistState state) {
    if (state.status == PlaylistStatus.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 50),
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    }
    if (state.playlists.isEmpty) return const EmptyPlaylistsState();
    return PlaylistGrid(
      playlists: state.playlists,
      thumbnails: state.thumbnails,
      onTap: (p) => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => PlaylistDetailsScreen(playlist: p)),
      ).then((_) => context.read<PlaylistCubit>().loadPlaylists()),
      onLongPress: (p) => _showPlaylistMenu(context, p),
    );
  }

  Widget _buildHeader() {
    return Text(
      "playlists_title".tr(),
      style: const TextStyle(
        fontSize: 50,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
    );
  }
}
