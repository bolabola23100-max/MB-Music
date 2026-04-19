import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/playlist/playlist_service.dart';
import 'package:music/core/widgets/menu_row.dart';
import 'package:music/core/widgets/song_tile_widget.dart';
import 'package:music/features/home/widgets/mini_player_widget.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:music/features/playlist/widgets/playlist_options_bottom_sheet.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;

class PlaylistDetailsScreen extends StatefulWidget {
  final PlaylistModels playlist;
  const PlaylistDetailsScreen({
    super.key,
    required this.playlist,
    this.onOptionSelected,
  });

  final void Function(SongSortOption option)? onOptionSelected;

  @override
  State<PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  final PlaylistService _service = PlaylistService();
  final AudioService _audioService = AudioService();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<PlaylistSong> _playlistSongs = [];
  List<SongModel> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);

    _playlistSongs = await _service.getPlaylistSongs(widget.playlist.id!);

    if (_playlistSongs.isNotEmpty) {
      final allSongs = await _audioQuery.querySongs();

      _songs = allSongs
          .where((s) => _playlistSongs.any((ps) => ps.songId == s.id))
          .toList();

      _songs.sort(
        (a, b) => _playlistSongs
            .indexWhere((ps) => ps.songId == a.id)
            .compareTo(_playlistSongs.indexWhere((ps) => ps.songId == b.id)),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _play(int index) {
    if (_songs.isEmpty) return;

    final s = _songs[index];
    _audioService.playSong(
      s.data,
      title: s.title,
      artist: s.artist,
      index: index,
      songId: s.id,
      queue: _songs,
    );
  }

  void _playRandomOnlyKeepOrder() {
    if (_songs.isEmpty) return;

    final shuffled = List<SongModel>.from(_songs);
    shuffled.shuffle();

    _audioService.playSong(
      shuffled.first.data,
      title: shuffled.first.title,
      artist: shuffled.first.artist,
      index: 0,
      songId: shuffled.first.id,
      queue: shuffled,
    );
  }

  void _showOptions(PlaylistSong song) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PlaylistOptionsBottomSheet(
        song: song,
        playlistId: widget.playlist.id!,
        onPlay: () {
          Navigator.pop(context);
          _play(_playlistSongs.indexOf(song));
        },
        onDelete: () {
          Navigator.pop(context);
          _delete(song);
        },
      ),
    );
  }

  void _delete(PlaylistSong song) async {
    await _service.removeSongFromPlaylist(widget.playlist.id!, song.songId);
    _loadSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.playlist.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10),
            child: IconButton(
              icon: SvgPicture.asset(AppIcons.icon, width: 15, height: 15),
              onPressed: () async {
                final RenderBox button =
                    context.findRenderObject() as RenderBox;
                final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;

                final RelativeRect position = RelativeRect.fromRect(
                  Rect.fromPoints(
                    button.localToGlobal(
                      Offset(button.size.width - 60, 60),
                      ancestor: overlay,
                    ),
                    button.localToGlobal(
                      Offset(button.size.width, 60),
                      ancestor: overlay,
                    ),
                  ),
                  Offset.zero & overlay.size,
                );

                final SongSortOption? result = await showMenu<SongSortOption>(
                  context: context,
                  position: position,
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  items: [
                    PopupMenuItem(
                      value: SongSortOption.oldestFirst,
                      child: MenuRow(
                        icon: Icons.arrow_upward_rounded,
                        label: 'sort.oldest_first'.tr(),
                      ),
                    ),

                    PopupMenuItem(
                      value: SongSortOption.newestFirst,
                      child: MenuRow(
                        icon: Icons.arrow_downward_rounded,
                        label: 'sort.newest_first'.tr(),
                      ),
                    ),
                  ],
                );

                if (result != null) {
                  setState(() {
                    switch (result) {
                      case SongSortOption.oldestFirst:
                        _songs.sort((a, b) {
                          final aDate = _playlistSongs
                              .firstWhere((ps) => ps.songId == a.id)
                              .addedAt;
                          final bDate = _playlistSongs
                              .firstWhere((ps) => ps.songId == b.id)
                              .addedAt;
                          return (aDate ?? DateTime.now()).compareTo(
                            bDate ?? DateTime.now(),
                          );
                        });
                        break;

                      case SongSortOption.newestFirst:
                        _songs.sort((a, b) {
                          final aDate = _playlistSongs
                              .firstWhere((ps) => ps.songId == a.id)
                              .addedAt;
                          final bDate = _playlistSongs
                              .firstWhere((ps) => ps.songId == b.id)
                              .addedAt;
                          return (bDate ?? DateTime.now()).compareTo(
                            aDate ?? DateTime.now(),
                          );
                        });
                        break;

                      // مش مستخدمين في منيو البلاي ليست دي
                      case SongSortOption.orderedPlay:
                        _songs.sort(
                          (a, b) => _playlistSongs
                              .indexWhere((ps) => ps.songId == a.id)
                              .compareTo(
                                _playlistSongs.indexWhere(
                                  (ps) => ps.songId == b.id,
                                ),
                              ),
                        );
                        break;

                      case SongSortOption.shufflePlay:
                        _songs.shuffle();
                        break;
                    }
                  });

                  widget.onOptionSelected?.call(result);
                }
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            )
          : Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildList()),
                MiniPlayerWidget(songs: _songs, audioService: _audioService),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(padding: const EdgeInsets.only(right: 10), child: c());
  }

  void _playOrderedOnly() => _play(0);

  Container c() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        // border: Border.all(color: Colors.grey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: AppColors.blue.withValues(alpha: 0.4),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(15),
                bottomStart: Radius.circular(15),
              ),
            ),
            child: InkWell(
              onTap: _playOrderedOnly,
              customBorder: const RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(15),
                  bottomStart: Radius.circular(15),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "player.sequential".tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ الجزء الأيسر - تشغيل عشوائي
          Material(
            color: AppColors.blue.withValues(alpha: 0.6),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.only(
                topEnd: Radius.circular(15),
                bottomEnd: Radius.circular(15),
              ),
            ),
            child: InkWell(
              onTap: _playRandomOnlyKeepOrder,
              customBorder: const RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.only(
                  topEnd: Radius.circular(15),
                  bottomEnd: Radius.circular(15),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shuffle_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "player.shuffle".tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ValueListenableBuilder<int?>(
      valueListenable: _audioService.currentSongIdNotifier,
      builder: (context, currentId, _) => ValueListenableBuilder<bool>(
        valueListenable: _audioService.isPlayingNotifier,
        builder: (context, isPlaying, _) => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _songs.length,
          itemBuilder: (context, index) {
            final s = _songs[index];
            return SongTileWidget(
              song: s,
              isCurrent: currentId == s.id,
              isPlaying: isPlaying,
              onTap: () => _play(index),
              onMoreTap: () => _showOptions(_playlistSongs[index]),
              onLongPress: () => _showOptions(_playlistSongs[index]),
            );
          },
        ),
      ),
    );
  }
}
