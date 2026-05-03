import 'dart:io';
import 'package:music/core/services/song_delete_service.dart';

import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/core/services/song_edit/song_edit_service.dart';
import 'package:music/core/widgets/app_artwork.dart';
import 'package:music/features/home/widgets/song_options_bottom_sheet.dart';
import 'package:music/features/playlist/widgets/add_to_playlist_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:easy_localization/easy_localization.dart';

class SongSelectScreen extends StatefulWidget {
  static void show(
    BuildContext context,
    List<SongModel> songs,
    AudioService audioService,
    bool Function(SongModel song)? isFavoriteChecker,
    Future<void> Function(SongModel song)? onToggleFavorite, {
    int? initialSelectedSongId,
    Future<void> Function(List<SongModel> songs)? onDeleteSongs,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongSelectScreen(
          songs: songs,
          audioService: audioService,
          isFavoriteChecker: isFavoriteChecker,
          onToggleFavorite: onToggleFavorite,
          initialSelectedSongId: initialSelectedSongId,
          onDeleteSongs: onDeleteSongs,
        ),
      ),
    );
  }

  const SongSelectScreen({
    super.key,
    required this.songs,
    required this.audioService,
    this.isFavoriteChecker,
    this.onToggleFavorite,
    this.initialSelectedSongId,
    this.onDeleteSongs,
  });

  final List<SongModel> songs;
  final AudioService audioService;
  final int? initialSelectedSongId;

  final bool Function(SongModel song)? isFavoriteChecker;
  final Future<void> Function(SongModel song)? onToggleFavorite;
  final Future<void> Function(List<SongModel> songs)? onDeleteSongs;

  @override
  State<SongSelectScreen> createState() => _SongSelectScreenState();
}

class _SongSelectScreenState extends State<SongSelectScreen> {
  final Set<int> _selectedIds = <int>{};

  final Map<int, Map<String, dynamic>> _editsBySongId = {};

  bool _loadingEdits = true;

  bool get _isSelecting => _selectedIds.isNotEmpty;

  void _showFavoriteSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : Colors.green,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedSongId != null) {
      _selectedIds.add(widget.initialSelectedSongId!);
    }
    _loadEditsForAllSongs();
  }

  Future<void> _loadEditsForAllSongs() async {
    if (mounted) setState(() => _loadingEdits = true);

    final service = SongEditService();
    final Map<int, Map<String, dynamic>> temp = {};

    for (final song in widget.songs) {
      final edit = await service.getEdit(song.id);
      if (edit != null) {
        temp[song.id] = Map<String, dynamic>.from(edit);
      }
    }

    if (!mounted) return;
    setState(() {
      _editsBySongId
        ..clear()
        ..addAll(temp);
      _loadingEdits = false;
    });
  }

  String _displayTitle(SongModel song) {
    final edit = _editsBySongId[song.id];
    final editedTitle = (edit?['title'] as String?)?.trim();
    if (editedTitle != null && editedTitle.isNotEmpty) return editedTitle;
    return song.title;
  }

  String _displayArtist(SongModel song) {
    final edit = _editsBySongId[song.id];
    final editedArtist = (edit?['artist'] as String?)?.trim();
    if (editedArtist != null && editedArtist.isNotEmpty) return editedArtist;

    final a = song.artist?.trim();
    return (a != null && a.isNotEmpty && a != "<unknown>")
        ? a
        : "common.unknown_artist".tr();
  }

  String _displayAlbum(SongModel song) {
    final a = song.album?.trim();
    return (a != null && a.isNotEmpty && a != "<unknown>")
        ? a
        : "common.unknown_album".tr();
  }

  String? _displayArtPath(SongModel song) {
    final edit = _editsBySongId[song.id];
    final path = (edit?['artPath'] as String?)?.trim();
    if (path == null || path.isEmpty) return null;

    final file = File(path);
    if (!file.existsSync()) return null;

    return path;
  }

  void _toggleSelection(SongModel song) {
    setState(() {
      if (_selectedIds.contains(song.id)) {
        _selectedIds.remove(song.id);
      } else {
        _selectedIds.add(song.id);
      }
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  List<SongModel> get _selectedSongs =>
      widget.songs.where((s) => _selectedIds.contains(s.id)).toList();

  Future<void> _playSelectedOrdered() async {
    final selected = _selectedSongs;
    if (selected.isEmpty) return;

    final first = selected.first;
    await widget.audioService.playSong(
      first.data,
      title: _displayTitle(first),
      artist: _displayArtist(first),
      index: 0,
      songId: first.id,
      queue: selected,
    );
  }

  Future<void> _toggleSelectedFavorites() async {
    final selected = _selectedSongs;
    if (selected.isEmpty) return;

    if (widget.onToggleFavorite == null) return;

    for (final s in selected) {
      await widget.onToggleFavorite!(s);
    }

    _showFavoriteSnackBar(
      "selection.processed_items".tr(args: [selected.length.toString()]),
    );
  }

  Future<void> _deleteSelectedPlaceholder() async {
    final selected = _selectedSongs;
    if (selected.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          "options.delete".tr(),
          style: const TextStyle(color: AppColors.white),
        ),
        content: Text(
          "selection.delete_items_q".tr(args: [selected.length.toString()]),
          style: const TextStyle(color: AppColors.blue),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "common.cancel".tr(),
              style: const TextStyle(color: AppColors.blue),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "options.delete".tr(),
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      final toDelete = List<SongModel>.from(selected);
      final songIds = toDelete.map((s) => s.id).toList();

      final deleteResult = await SongDeleteService.deleteSongs(songIds);

      if (deleteResult.success) {
        if (widget.onDeleteSongs != null) {
          await widget.onDeleteSongs!(toDelete);
        }

        _clearSelection();

        if (mounted) {
          _showFavoriteSnackBar(
            "selection.deleted_msg".tr(args: [toDelete.length.toString()]),
            isError: true,
          );
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showFavoriteSnackBar(
            "options.delete_failed".tr(),
            isError: true,
          );
        }
      }
    }
  }

  void _moreSelected() {
    final selected = _selectedSongs;
    if (selected.isEmpty) return;

    if (selected.length == 1) {
      final song = selected.first;
      final originalIndex = widget.songs.indexWhere((e) => e.id == song.id);

      SongOptionsBottomSheet.show(
        context,
        song: song,
        index: originalIndex == -1 ? 0 : originalIndex,
        audioService: widget.audioService,
        isFavoriteChecker: widget.isFavoriteChecker,
        onToggleFavorite: widget.onToggleFavorite,
        onDeleteSongs: widget.onDeleteSongs,
        isDelete: false,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                "selection.items_selected".tr(args: [selected.length.toString()]),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: AppColors.white),
              title: Text(
                "selection.play_selected".tr(),
                style: const TextStyle(color: AppColors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _playSelectedOrdered();
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: AppColors.white),
              title: Text(
                "options.add_to_playlist".tr(),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AddToPlaylistDialog(songs: selected),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_isSelecting && widget.initialSelectedSongId == null) {
      _clearSelection();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final count = _selectedIds.length;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () {
              if (_isSelecting && widget.initialSelectedSongId == null) {
                _clearSelection();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            _isSelecting
                ? (count == 1
                    ? "selection.item_selected".tr()
                    : "selection.items_selected".tr(args: [count.toString()]))
                : "common.select".tr(),
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              tooltip: "common.select_all".tr(),
              onPressed: () {
                setState(() {
                  if (_selectedIds.length == widget.songs.length) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds
                      ..clear()
                      ..addAll(widget.songs.map((e) => e.id));
                  }
                });
              },
              icon: _buildSelectionIndicator(
                _selectedIds.length == widget.songs.length,
              ),
            ),
          ],
        ),
        bottomNavigationBar: _isSelecting
            ? BottomAppBar(
                color: AppColors.black,
                elevation: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _actionButton(
                          onPressed: _playSelectedOrdered,
                          icon: Icons.play_circle_outline,
                        ),
                        _actionButton(
                          onPressed: _toggleSelectedFavorites,
                          icon: Icons.favorite_border,
                        ),
                        _actionButton(
                          onPressed: _deleteSelectedPlaceholder,
                          icon: Icons.delete_outline,
                        ),
                        _actionButton(
                          onPressed: _moreSelected,
                          icon: Icons.more_horiz,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        body: _loadingEdits
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.blue),
              )
            : ListView.builder(
                itemCount: widget.songs.length,
                itemBuilder: (context, index) {
                  final song = widget.songs[index];
                  final isSelected = _selectedIds.contains(song.id);

                  final title = _displayTitle(song);
                  final artist = _displayArtist(song);
                  final album = _displayAlbum(song);
                  final artPath = _displayArtPath(song);

                  return InkWell(
                    onTap: () => _toggleSelection(song),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.blue.withOpacity(0.10)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 45,
                              height: 45,
                              child: artPath != null
                                  ? Image.file(
                                      File(artPath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) {
                                        return AppArtwork(
                                          id: song.id,
                                          isCurrent: isSelected,
                                          borderRadius: 10,
                                          size: 45,
                                        );
                                      },
                                    )
                                  : AppArtwork(
                                      id: song.id,
                                      isCurrent: isSelected,
                                      borderRadius: 10,
                                      size: 45,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.blue
                                        : AppColors.white.withOpacity(0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$artist • $album",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.white.withOpacity(0.45),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildFavIcon(song),
                          _buildSelectionIndicator(isSelected),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFavIcon(SongModel song) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: FavoritesService().favoriteIdsNotifier,
      builder: (context, favIds, _) {
        if (favIds.contains(song.id)) {
          return const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.favorite, color: Colors.red, size: 16),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSelectionIndicator(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.blue : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? AppColors.blue
              : AppColors.white.withOpacity(0.30),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: AppColors.black)
          : null,
    );
  }

  Widget _actionButton({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: AppColors.blue.withOpacity(0.9),
    );
  }
}
