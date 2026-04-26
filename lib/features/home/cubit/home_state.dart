import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<SongModel> originalSongs;
  final List<SongModel> songs;
  final List<SongModel> displaySongs;
  final List<SongModel> sounds;
  final int currentIndex;

  const HomeState({
    this.status = HomeStatus.initial,
    this.originalSongs = const [],
    this.songs = const [],
    this.displaySongs = const [],
    this.sounds = const [],
    this.currentIndex = 0,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<SongModel>? originalSongs,
    List<SongModel>? songs,
    List<SongModel>? displaySongs,
    List<SongModel>? sounds,
    int? currentIndex,
  }) {
    return HomeState(
      status: status ?? this.status,
      originalSongs: originalSongs ?? this.originalSongs,
      songs: songs ?? this.songs,
      displaySongs: displaySongs ?? this.displaySongs,
      sounds: sounds ?? this.sounds,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
  

  @override
  List<Object?> get props => [
        status,
        originalSongs,
        songs,
        displaySongs,
        sounds,
        currentIndex,
      ];
}
