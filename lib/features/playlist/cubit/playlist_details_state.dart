import 'package:equatable/equatable.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;

enum PlaylistDetailsStatus { initial, loading, success, failure }

class PlaylistDetailsState extends Equatable {
  final PlaylistDetailsStatus status;
  final List<PlaylistSong> playlistSongs;
  final List<SongModel> songs;

  const PlaylistDetailsState({
    this.status = PlaylistDetailsStatus.initial,
    this.playlistSongs = const [],
    this.songs = const [],
  });

  PlaylistDetailsState copyWith({
    PlaylistDetailsStatus? status,
    List<PlaylistSong>? playlistSongs,
    List<SongModel>? songs,
  }) {
    return PlaylistDetailsState(
      status: status ?? this.status,
      playlistSongs: playlistSongs ?? this.playlistSongs,
      songs: songs ?? this.songs,
    );
  }

  @override
  List<Object?> get props => [status, playlistSongs, songs];
}
