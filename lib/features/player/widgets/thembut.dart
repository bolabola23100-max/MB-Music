// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';

// import 'package:music/core/constants/app_colors.dart';
// import 'package:music/core/constants/app_icons.dart';
// import 'package:music/core/services/cache_helper.dart';
// import 'package:music/core/widgets/player_builder.dart';
// import 'package:on_audio_query/on_audio_query.dart';

// class thembut extends StatelessWidget {
//   final int currentIndex;
//   final List<SongModel> songs;
//   thembut({super.key, required this.currentIndex, required this.songs});

//   void _saveThemeAndNavigate(BuildContext context, int themeStyle) {
//     CacheHelper.playerThemeStyle = themeStyle;
//     Navigator.pop(context);

//     final safeIndex = currentIndex.clamp(0, songs.length - 1);

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) =>
//             resolvePlayerScreen(songs: songs, index: safeIndex),
//       ),
//     );
//   }

//   final Map<int, String> themeImages = {1: AppIcons.th1, 2: AppIcons.th2};
//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       icon: const Icon(Icons.theater_comedy, color: AppColors.white, size: 32),
//       onPressed: () {
//         showModalBottomSheet(
//           context: context,
//           isScrollControlled: true,
//           backgroundColor: Colors.transparent,
//           builder: (context) {
//             return DraggableScrollableSheet(
//               initialChildSize: 0.9,
//               minChildSize: 0.5,
//               maxChildSize: 0.95,
//               expand: false,
//               builder: (context, scrollController) {
//                 return Container(
//                   decoration: const BoxDecoration(
//                     color: AppColors.gray,
//                     borderRadius: BorderRadius.vertical(
//                       top: Radius.circular(24),
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 4,
//                         margin: const EdgeInsets.symmetric(vertical: 12),
//                         decoration: BoxDecoration(
//                           color: AppColors.white.withValues(alpha: 0.2),
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                       const Text(
//                         "اختر شكل المشغل",
//                         style: TextStyle(
//                           color: AppColors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       SizedBox(
//                         height: 140,
//                         child: ListView(
//                           controller: scrollController,
//                           scrollDirection: Axis.horizontal,
//                           padding: const EdgeInsets.symmetric(horizontal: 20),
//                           children: playerThemes.keys.map((themeId) {
//                             final isSelected =
//                                 CacheHelper.playerThemeStyle == themeId;
//                             return Padding(
//                               padding: const EdgeInsets.only(right: 12),
//                               child: InkWell(
//                                 onTap: () =>
//                                     _saveThemeAndNavigate(context, themeId),
//                                 borderRadius: BorderRadius.circular(16),
//                                 child: Container(
//                                   width: 90,
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(16),
//                                     border: Border.all(
//                                       color: isSelected
//                                           ? AppColors.blue
//                                           : Colors.transparent,
//                                       width: 2,
//                                     ),
//                                   ),
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(16),
//                                     child: Image.asset(
//                                       themeImages[themeId]!,
//                                       width: 100,
//                                       height: 140,
//                                       fit: BoxFit.cover,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }
