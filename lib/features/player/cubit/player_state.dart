import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerState extends Equatable {
  final List<SongModel> songs;
  final int currentIndex;
  final bool isPlaying;
  final double offsetY;
  final bool canDrag;
  final String? customTitle;
  final String? customArtist;
  final String? customArtPath;

  const PlayerState({
    required this.songs,
    required this.currentIndex,
    this.isPlaying = true,
    this.offsetY = 0,
    this.canDrag = false,
    this.customTitle,
    this.customArtist,
    this.customArtPath,
  });

  PlayerState copyWith({
    List<SongModel>? songs,
    int? currentIndex,
    bool? isPlaying,
    double? offsetY,
    bool? canDrag,
    String? Function()? customTitle,
    String? Function()? customArtist,
    String? Function()? customArtPath,
  }) {
    return PlayerState(
      songs: songs ?? this.songs,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      offsetY: offsetY ?? this.offsetY,
      canDrag: canDrag ?? this.canDrag,
      customTitle: customTitle != null ? customTitle() : this.customTitle,
      customArtist: customArtist != null ? customArtist() : this.customArtist,
      customArtPath: customArtPath != null ? customArtPath() : this.customArtPath,
    );
  }

  @override
  List<Object?> get props => [
        songs,
        currentIndex,
        isPlaying,
        offsetY,
        canDrag,
        customTitle,
        customArtist,
        customArtPath,
      ];
}
