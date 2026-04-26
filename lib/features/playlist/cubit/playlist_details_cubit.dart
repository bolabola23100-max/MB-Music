import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/playlist/playlist_service.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;
import 'playlist_details_state.dart';

class PlaylistDetailsCubit extends Cubit<PlaylistDetailsState> {
  final PlaylistService _service = PlaylistService();
  final AudioService _audioService = AudioService();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final int playlistId;

  PlaylistDetailsCubit({required this.playlistId}) : super(const PlaylistDetailsState()) {
    loadSongs();
  }

  Future<void> loadSongs() async {
    emit(state.copyWith(status: PlaylistDetailsStatus.loading));
    try {
      final playlistSongs = await _service.getPlaylistSongs(playlistId);
      List<SongModel> songs = [];

      if (playlistSongs.isNotEmpty) {
        final allSongs = await _audioQuery.querySongs();
        songs = allSongs.where((s) => playlistSongs.any((ps) => ps.songId == s.id)).toList();
        songs.sort((a, b) => playlistSongs
            .indexWhere((ps) => ps.songId == a.id)
            .compareTo(playlistSongs.indexWhere((ps) => ps.songId == b.id)));
      }

      emit(state.copyWith(
        status: PlaylistDetailsStatus.success,
        playlistSongs: playlistSongs,
        songs: songs,
      ));
    } catch (e) {
      emit(state.copyWith(status: PlaylistDetailsStatus.failure));
    }
  }

  void play(int index) {
    if (state.songs.isEmpty) return;
    final s = state.songs[index];
    _audioService.playSong(
      s.data,
      title: s.title,
      artist: s.artist,
      index: index,
      songId: s.id,
      queue: state.songs,
    );
  }

  void playRandom() {
    if (state.songs.isEmpty) return;
    final shuffled = List<SongModel>.from(state.songs)..shuffle();
    final first = shuffled.first;
    _audioService.playSong(
      first.data,
      title: first.title,
      artist: first.artist,
      index: 0,
      songId: first.id,
      queue: shuffled,
    );
  }

  Future<void> deleteSong(PlaylistSong song) async {
    await _service.removeSongFromPlaylist(playlistId, song.songId);
    await loadSongs();
  }

  void sortSongs(SongSortOption option) {
    if (state.songs.isEmpty) return;
    List<SongModel> sortedSongs = List.from(state.songs);

    switch (option) {
      case SongSortOption.oldestFirst:
        sortedSongs.sort((a, b) {
          final aDate = state.playlistSongs.firstWhere((ps) => ps.songId == a.id).addedAt;
          final bDate = state.playlistSongs.firstWhere((ps) => ps.songId == b.id).addedAt;
          return (aDate ?? DateTime.now()).compareTo(bDate ?? DateTime.now());
        });
        break;
      case SongSortOption.newestFirst:
        sortedSongs.sort((a, b) {
          final aDate = state.playlistSongs.firstWhere((ps) => ps.songId == a.id).addedAt;
          final bDate = state.playlistSongs.firstWhere((ps) => ps.songId == b.id).addedAt;
          return (bDate ?? DateTime.now()).compareTo(aDate ?? DateTime.now());
        });
        break;
      case SongSortOption.orderedPlay:
        sortedSongs.sort((a, b) => state.playlistSongs
            .indexWhere((ps) => ps.songId == a.id)
            .compareTo(state.playlistSongs.indexWhere((ps) => ps.songId == b.id)));
        break;
      case SongSortOption.shufflePlay:
        sortedSongs.shuffle();
        break;
    }
    emit(state.copyWith(songs: sortedSongs));
  }
}
