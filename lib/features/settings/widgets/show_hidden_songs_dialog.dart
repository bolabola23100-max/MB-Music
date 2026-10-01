import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/hidden_songs_service.dart';
import 'package:on_audio_query/on_audio_query.dart';

Future<void> showHiddenSongsDialog(
  BuildContext context,
  List<SongModel> songs,
) async {
  final service = HiddenSongsService();
  await service.init();
  if (!context.mounted) return;

  final hidden = songs.where((song) => service.isHidden(song.id)).toList();

  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.black,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Hidden Songs',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (hidden.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No hidden songs',
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          await service.clearAll();
                          hidden.clear();
                          setState(() {});
                        },
                        child: const Text('Unhide all'),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: hidden.length,
                        itemBuilder: (_, index) {
                          final song = hidden[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              song.title,
                              style: const TextStyle(color: AppColors.white),
                            ),
                            subtitle: Text(
                              song.artist ?? 'Unknown artist',
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                color: AppColors.blue,
                              ),
                              onPressed: () async {
                                await service.unhideSong(song.id);
                                hidden.removeAt(index);
                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
