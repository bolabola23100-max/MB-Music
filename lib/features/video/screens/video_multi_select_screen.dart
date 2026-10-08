import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/video/video_favorites_service.dart';
import 'package:music/core/services/video/video_playlist_service.dart';
import 'package:music/features/video/widgets/video_selection_grid_tile.dart';

class VideoMultiSelectScreen extends StatefulWidget {
  final List<AssetEntity> videos;

  final String? initiallySelectedVideoId;

  const VideoMultiSelectScreen({
    super.key,
    required this.videos,
    this.initiallySelectedVideoId,
  });

  @override
  State<VideoMultiSelectScreen> createState() => _VideoMultiSelectScreenState();
}

class _VideoMultiSelectScreenState extends State<VideoMultiSelectScreen> {
  late final Set<String> _selected = <String>{
    if (widget.initiallySelectedVideoId != null &&
        widget.videos.any((video) => video.id == widget.initiallySelectedVideoId))
      widget.initiallySelectedVideoId!,
  };
  final _favorites = VideoFavoritesService();
  final _playlists = VideoPlaylistService();

  List<AssetEntity> get _selectedVideos =>
      widget.videos.where((v) => _selected.contains(v.id)).toList();

  void _toggle(AssetEntity video) {
    setState(() {
      if (!_selected.add(video.id)) _selected.remove(video.id);
    });
  }

  Future<void> _addToPlaylist() async {
    if (_selected.isEmpty) return;
    final playlists = await _playlists.getPlaylists();
    if (!mounted) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.gray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.blue),
                title: const Text('Create new playlist', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(sheetContext, '__create__'),
              ),
              ...playlists.map((playlist) => ListTile(
                    leading: const Icon(Icons.playlist_play_rounded, color: AppColors.blue),
                    title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${playlist.videoIds.length} videos', style: const TextStyle(color: Colors.white54)),
                    onTap: () => Navigator.pop(sheetContext, playlist.id),
                  )),
            ],
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;

    if (result == '__create__') {
      await _createPlaylistFlow();
      return;
    }

    final playlist = playlists.firstWhere((p) => p.id == result);
    var added = 0;
    for (final video in _selectedVideos) {
      if (await _playlists.addVideo(playlist.id, video.id)) added++;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$added video${added == 1 ? '' : 's'} added to ${playlist.name}')),
    );
    Navigator.pop(context);
  }

  Future<void> _createPlaylistFlow() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: const Text('New video playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Next'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (!mounted || name == null || name.isEmpty) return;

    // A new playlist is not created yet. The user must choose at least one
    // video first. This sheet cannot be dismissed by tapping outside.
    final chosenIds = await _showRequiredVideoPicker();
    if (!mounted || chosenIds == null || chosenIds.isEmpty) return;

    final playlistId = await _playlists.createPlaylist(name);
    var added = 0;
    for (final videoId in chosenIds) {
      if (await _playlists.addVideo(playlistId, videoId)) added++;
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playlist "$name" created with $added video${added == 1 ? '' : 's'}')),
    );
    Navigator.pop(context);
  }

  Future<Set<String>?> _showRequiredVideoPicker() async {
    final selectedIds = <String>{..._selected};

    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.gray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * .72,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Text(
                      'Choose videos for the playlist',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Choose at least one video',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: .82,
                      ),
                      itemCount: widget.videos.length,
                      itemBuilder: (_, index) {
                        final video = widget.videos[index];
                        final selected = selectedIds.contains(video.id);
                        return VideoSelectionGridTile(
                          video: video,
                          selected: selected,
                          showTitle: false,
                          onTap: () {
                            setSheetState(() {
                              if (!selectedIds.add(video.id)) {
                                selectedIds.remove(video.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: selectedIds.isEmpty
                            ? null
                            : () => Navigator.pop(sheetContext, selectedIds),
                        child: Text(selectedIds.isEmpty ? 'Select a video' : 'Add ${selectedIds.length} video${selectedIds.length == 1 ? '' : 's'}'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addToFavorites() async {
    if (_selected.isEmpty) return;
    await _favorites.addFavorites(_selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selected.length} videos added to favorites')),
    );
    Navigator.pop(context);
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: const Text('Delete selected videos?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete ${_selected.length} selected videos from the device?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      final ids = _selected.toList();
      final deletedIds = await PhotoManager.editor.deleteWithIds(ids);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${deletedIds.length} video${deletedIds.length == 1 ? '' : 's'} deleted')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete selected videos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _selected.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('$count of ${widget.videos.length} videos selected'),
        actions: [
          IconButton(
            tooltip: 'Select all',
            onPressed: () => setState(() {
              if (_selected.length == widget.videos.length) {
                _selected.clear();
              } else {
                _selected.addAll(widget.videos.map((v) => v.id));
              }
            }),
            icon: Icon(
              _selected.length == widget.videos.length
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        itemCount: widget.videos.length,
        itemBuilder: (context, index) {
          final video = widget.videos[index];
          final selected = _selected.contains(video.id);
          return VideoSelectionGridTile(
            video: video,
            selected: selected,
            onTap: () => _toggle(video),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionIcon(
                icon: Icons.playlist_add_rounded,
                tooltip: 'Playlist',
                onPressed: count == 0 ? null : _addToPlaylist,
              ),
              _ActionIcon(
                icon: Icons.favorite_rounded,
                tooltip: 'Favorites',
                onPressed: count == 0 ? null : _addToFavorites,
              ),
              _ActionIcon(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete',
                onPressed: count == 0 ? null : _deleteSelected,
                destructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool destructive;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: destructive ? Colors.redAccent : Colors.white,
      disabledColor: Colors.white30,
      iconSize: 28,
    );
  }
}
