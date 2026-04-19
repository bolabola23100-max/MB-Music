import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/widgets/menu_row.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// SortButton للسونج العادي (مش Playlists)
/// الفكرة: الزرار بيرتب نسخة من الليست ويرجّعها للـ Screen عشان تعمل setState
class SortButton extends StatelessWidget {
  const SortButton({
    super.key,
    required this.songs,
    required this.onSongsSorted,
  });

  /// الليست الحالية المعروضة
  final List<SongModel> songs;

  /// بيرجع الليست بعد الترتيب (الـ Screen تعمل setState بيها)
  final ValueChanged<List<SongModel>> onSongsSorted;

  List<SongModel> _sortedList(SongSortOption option) {
    final sorted = List<SongModel>.from(songs);

    int added(SongModel s) => s.dateAdded ?? 0;

    switch (option) {
      case SongSortOption.oldestFirst:
        sorted.sort((a, b) => added(a).compareTo(added(b)));
        break;

      case SongSortOption.newestFirst:
        sorted.sort((a, b) => added(b).compareTo(added(a)));
        break;

      // مش مستخدمين هنا
      case SongSortOption.orderedPlay:
      case SongSortOption.shufflePlay:
        break;
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SongSortOption>(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(-20, 45),
      icon: SvgPicture.asset(AppIcons.icon, width: 15, height: 15),
      onSelected: (option) {
        final sorted = _sortedList(option);
        onSongsSorted(sorted);
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: SongSortOption.oldestFirst,
          child: MenuRow(
            icon: Icons.arrow_upward_rounded,
            label: 'الأقدم أولاً',
          ),
        ),
        PopupMenuItem(
          value: SongSortOption.newestFirst,
          child: MenuRow(
            icon: Icons.arrow_downward_rounded,
            label: 'الأحدث أولاً',
          ),
        ),
      ],
    );
  }
}
