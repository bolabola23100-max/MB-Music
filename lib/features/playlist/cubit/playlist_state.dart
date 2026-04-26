import 'package:equatable/equatable.dart';
import 'package:music/core/models/playlist_model.dart';

enum PlaylistStatus { initial, loading, success, failure }

class PlaylistState extends Equatable {
  final PlaylistStatus status;
  final List<PlaylistModels> playlists;
  final Map<int, List<int>> thumbnails;

  const PlaylistState({
    this.status = PlaylistStatus.initial,
    this.playlists = const [],
    this.thumbnails = const {},
  });

  PlaylistState copyWith({
    PlaylistStatus? status,
    List<PlaylistModels>? playlists,
    Map<int, List<int>>? thumbnails,
  }) {
    return PlaylistState(
      status: status ?? this.status,
      playlists: playlists ?? this.playlists,
      thumbnails: thumbnails ?? this.thumbnails,
    );
  }

  @override
  List<Object?> get props => [status, playlists, thumbnails];
}
