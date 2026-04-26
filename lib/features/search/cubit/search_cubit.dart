import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  Timer? _debounce;
  late List<_SearchItem> _searchableSongs;

  SearchCubit({required List<SongModel> allSongs})
      : super(SearchState(allSongs: allSongs, filteredSongs: allSongs)) {
    _prepareSearchData();
  }

  void _prepareSearchData() {
    _searchableSongs = state.allSongs.map((song) {
      final title = song.title.trim();
      String artist = (song.artist ?? "").trim();
      if (artist == "<unknown>") artist = "";

      final extraKeywords = _buildExtraKeywords(title);
      final searchText = _normalize([title, artist, ...extraKeywords].join(' '));

      return _SearchItem(song: song, searchText: searchText);
    }).toList();
  }

  List<String> _buildExtraKeywords(String title) {
    final lowerTitle = title.toLowerCase();
    final keywords = <String>[];
    if (lowerTitle.contains("despacito")) keywords.add("ديسباسيتو");
    if (lowerTitle.contains("believer")) keywords.add("بيليفير");
    return keywords;
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-zA-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void onSearchChanged(String query) {
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(query);
    });
  }

  void _runSearch(String query) {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      emit(state.copyWith(filteredSongs: state.allSongs));
      return;
    }

    final queryWords = normalizedQuery.split(' ').where((word) => word.isNotEmpty).toList();

    final results = _searchableSongs
        .where((item) => queryWords.every((word) => item.searchText.contains(word)))
        .map((item) => item.song)
        .toList();

    emit(state.copyWith(filteredSongs: results));
  }

  void clearSearch() {
    onSearchChanged("");
  }

  void updateAllSongs(List<SongModel> allSongs) {
    emit(state.copyWith(allSongs: allSongs));
    _prepareSearchData();
    _runSearch(state.query);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

class _SearchItem {
  final SongModel song;
  final String searchText;
  _SearchItem({required this.song, required this.searchText});
}
