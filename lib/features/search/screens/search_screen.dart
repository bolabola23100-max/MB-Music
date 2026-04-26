import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:music/features/search/cubit/search_cubit.dart';
import 'package:music/features/search/cubit/search_state.dart';

class SearchScreen extends StatelessWidget {
  final List<SongModel> allSongs;
  final Future<void> Function(List<SongModel> songs)? onDeleteSongs;

  const SearchScreen({super.key, required this.allSongs, this.onDeleteSongs});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchCubit(allSongs: allSongs),
      child: SearchContextHandler(
        allSongs: allSongs,
        onDeleteSongs: onDeleteSongs,
      ),
    );
  }
}

class SearchContextHandler extends StatelessWidget {
  final List<SongModel> allSongs;
  final Future<void> Function(List<SongModel> songs)? onDeleteSongs;

  const SearchContextHandler({
    super.key,
    required this.allSongs,
    this.onDeleteSongs,
  });

  @override
  Widget build(BuildContext context) {
    // Listen for changes in allSongs to update the cubit
    return BlocListener<SearchCubit, SearchState>(
      listenWhen: (previous, current) =>
          false, // We use this purely to react to widget prop changes
      listener: (context, state) {},
      child: SearchBody(onDeleteSongs: onDeleteSongs),
    );
  }
}

class SearchBody extends StatefulWidget {
  final Future<void> Function(List<SongModel> songs)? onDeleteSongs;

  const SearchBody({super.key, this.onDeleteSongs});

  @override
  State<SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<SearchBody> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();
    final cubit = context.read<SearchCubit>();

    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.gray.withValues(alpha: .01),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextFormField(
                  controller: controller,
                  onChanged: cubit.onSearchChanged,
                  style: const TextStyle(color: AppColors.white),
                  cursorColor: AppColors.blue,
                  decoration: InputDecoration(
                    hintText: "search_hint".tr(),
                    hintStyle: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.white,
                    ),
                    suffixIcon: state.query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.white,
                            ),
                            onPressed: () {
                              controller.clear();
                              cubit.clearSearch();
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
                child: state.filteredSongs.isEmpty
                    ? Center(
                        child: Text(
                          "common.no_results".tr(),
                          style: const TextStyle(color: AppColors.white),
                        ),
                      )
                    : SongListWidget(
                        key: ValueKey(
                          "search_list_${state.filteredSongs.length}",
                        ),
                        songs: state.filteredSongs,
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
      },
    );
  }
}
