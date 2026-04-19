import 'dart:async';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class SearchScreen extends StatefulWidget {
  final List<SongModel> allSongs;
  final Future<void> Function(List<SongModel> songs)? onDeleteSongs;

  const SearchScreen({super.key, required this.allSongs, this.onDeleteSongs});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController controller = TextEditingController();
  final AudioService audioService = AudioService();

  Timer? debounce;
  List<SongModel> filteredSongs = [];
  late List<_SearchItem> searchableSongs;

  @override
  void initState() {
    super.initState();
    _prepareSearchData();
    filteredSongs = widget.allSongs;
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.allSongs != widget.allSongs) {
      _prepareSearchData();
      _runSearch(controller.text);
    }
  }

  void _prepareSearchData() {
    searchableSongs = widget.allSongs.map((song) {
      final title = song.title.trim();
      String artist = (song.artist ?? "").trim();

      if (artist == "<unknown>") {
        artist = "";
      }

      final extraKeywords = _buildExtraKeywords(title);

      final searchText = _normalize(
        [title, artist, ...extraKeywords].join(' '),
      );

      return _SearchItem(song: song, searchText: searchText);
    }).toList();
  }

  List<String> _buildExtraKeywords(String title) {
    final lowerTitle = title.toLowerCase();
    final keywords = <String>[];

    if (lowerTitle.contains("despacito")) {
      keywords.add("ديسباسيتو");
    }

    if (lowerTitle.contains("believer")) {
      keywords.add("بيليفير");
    }

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

  void _onSearchChanged(String query) {
    setState(() {}); // For clear button visibility
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(query);
    });
  }

  void _runSearch(String query) {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      if (mounted) {
        setState(() {
          filteredSongs = widget.allSongs;
        });
      }
      return;
    }

    final queryWords = normalizedQuery
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    final results = searchableSongs
        .where((item) {
          return queryWords.every((word) => item.searchText.contains(word));
        })
        .map((item) {
          return item.song;
        })
        .toList();

    if (mounted) {
      setState(() {
        filteredSongs = results;
      });
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray.withValues(alpha: .01),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextFormField(
              controller: controller,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppColors.white),
              cursorColor: AppColors.blue,
              decoration: InputDecoration(
                hintText: "search_hint".tr(),
                hintStyle: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.white),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.white),
                        onPressed: () {
                          controller.clear();
                          _onSearchChanged("");
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.gray,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: AppColors.blue,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredSongs.isEmpty
                ? Center(
                    child: Text(
                      "common.no_results".tr(),
                      style: const TextStyle(color: AppColors.white),
                    ),
                  )
                : SongListWidget(
                    songs: filteredSongs,
                    audioService: audioService,
                    title: "search_results".tr(),
                    subtitle: "tracks_in_ether".tr(),
                    titleFontSize: 25,
                    showMiniPlayer: false,
                    isf: false,
                    onDeleteSongs: widget.onDeleteSongs,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchItem {
  final SongModel song;
  final String searchText;

  _SearchItem({required this.song, required this.searchText});
}
