import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:music/core/services/playlist/playlist_service.dart';
import 'package:music/features/playlist/screens/playlist_details_screen.dart';
import 'package:music/features/playlist/widgets/empty_playlists_state.dart';
import 'package:music/features/playlist/widgets/playlist_dialogs.dart';
import 'package:music/features/playlist/widgets/playlist_grid.dart';
import 'package:music/features/playlist/widgets/playlist_menu_bottom_sheet.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final PlaylistService _playlistService = PlaylistService();
  List<PlaylistModels> _playlists = [];
  Map<int, List<int>> _playlistThumbnails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final playlists = await _playlistService.getPlaylists();
      final Map<int, List<int>> thumbnails = {};
      for (final p in playlists) {
        if (p.id != null) {
          final songs = await _playlistService.getPlaylistSongs(p.id!);
          thumbnails[p.id!] = songs.take(4).map((s) => s.songId).toList();
        }
      }
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _playlistThumbnails = thumbnails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPlaylistMenu(PlaylistModels playlist) {
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
          PlaylistDialogs.showRenameDialog(context, playlist, _loadPlaylists);
        },
        onDelete: () {
          Navigator.pop(context);
          PlaylistDialogs.showDeleteDialog(context, playlist, _loadPlaylists);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray.withValues(alpha: .01),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildHeader(),

            const SizedBox(height: 15),
            _buildBody(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            PlaylistDialogs.showCreateDialog(context, _loadPlaylists),
        backgroundColor: const Color(0xFF00C8FF),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading)
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: 50),
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    if (_playlists.isEmpty) return const EmptyPlaylistsState();
    return PlaylistGrid(
      playlists: _playlists,
      thumbnails: _playlistThumbnails,
      onTap: (p) => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => PlaylistDetailsScreen(playlist: p)),
      ).then((_) => _loadPlaylists()),
      onLongPress: _showPlaylistMenu,
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
