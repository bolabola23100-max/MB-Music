import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/services/playlist/playlist_service.dart';
import 'playlist_state.dart';

class PlaylistCubit extends Cubit<PlaylistState> {
  final PlaylistService _playlistService = PlaylistService();

  PlaylistCubit() : super(const PlaylistState());

  Future<void> loadPlaylists() async {
    emit(state.copyWith(status: PlaylistStatus.loading));
    try {
      final playlists = await _playlistService.getPlaylists();
      final thumbnails = <int, List<int>>{};
      for (final p in playlists) {
        if (p.id != null) {
          final songs = await _playlistService.getPlaylistSongs(p.id!);
          thumbnails[p.id!] = songs.take(4).map((s) => s.songId).toList();
        }
      }
      emit(state.copyWith(
        status: PlaylistStatus.success,
        playlists: playlists,
        thumbnails: thumbnails,
      ));
    } catch (e) {
      emit(state.copyWith(status: PlaylistStatus.failure));
    }
  }
}
