import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SearchState extends Equatable {
  final List<SongModel> allSongs;
  final List<SongModel> filteredSongs;
  final String query;

  const SearchState({
    required this.allSongs,
    this.filteredSongs = const [],
    this.query = '',
  });

  SearchState copyWith({
    List<SongModel>? allSongs,
    List<SongModel>? filteredSongs,
    String? query,
  }) {
    return SearchState(
      allSongs: allSongs ?? this.allSongs,
      filteredSongs: filteredSongs ?? this.filteredSongs,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [allSongs, filteredSongs, query];
}
