import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/features/listening_stats_screen/screens/listening_stats_screen.dart';
import 'package:music/features/settings/widgets/build_badge.dart';
import 'package:music/features/settings/widgets/build_footer.dart';
import 'package:music/features/settings/widgets/build_section_header.dart';
import 'package:music/features/settings/widgets/build_setting_tile.dart';
import 'package:music/features/settings/widgets/format_duration.dart';
import 'package:music/features/settings/widgets/show_language_dialog.dart';
import 'package:music/features/settings/widgets/show_sleep_timer_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music/features/settings/cubit/settings_cubit.dart';
import 'package:music/features/settings/cubit/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.songs,
    required this.audioService,
    required this.onRescan,
  });

  final List<SongModel> songs;
  final AudioService audioService;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    return BlocProvider(
      create: (context) => SettingsCubit()..updateLanguage(languageCode),
      child: SettingsView(
        songs: songs,
        audioService: audioService,
        onRescan: onRescan,
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  final List<SongModel> songs;
  final AudioService audioService;
  final VoidCallback onRescan;

  const SettingsView({
    super.key,
    required this.songs,
    required this.audioService,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        return Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0,
            title: Text(
              'settings.title'.tr(),
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: lis(context, state, cubit),
        );
      },
    );
  }

  ListView lis(BuildContext context, SettingsState state, SettingsCubit cubit) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 10),
        buildSectionHeader('settings.general'.tr()),
        buildSettingTile(
          icon: Icons.bar_chart_rounded,
          title: 'settings.listening_stats'.tr(),
          subtitle: 'settings.listening_stats_desc'.tr(),
          onTap: () {
            AppNavigator.push(
              context,
              ListeningStatsScreen(allSongs: songs, audioService: audioService),
            );
          },
        ),
        buildSettingTile(
          icon: Icons.equalizer_rounded,
          title: 'settings.equalizer'.tr(),
          subtitle: 'settings.equalizer_desc'.tr(),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('settings.equalizer_feature_coming_soon'.tr()),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        buildSectionHeader('settings.audio'.tr()),
        buildSettingTile(
          icon: Icons.timer_outlined,
          title: 'settings.sleep_timer'.tr(),
          subtitle: state.sleepTimerRemaining == null
              ? 'settings.off'.tr()
              : '${'settings.stopping_in'.tr()} ${formatDuration(state.sleepTimerRemaining!)}',
          onTap: () => showSleepTimerDialog(context, cubit),
        ),
        buildSettingTile(
          icon: Icons.high_quality_rounded,
          title: 'settings.audio_quality'.tr(),
          subtitle: 'settings.audio_quality_desc'.tr(),
          onTap: () {},
        ),
        const SizedBox(height: 20),
        buildSectionHeader('settings.library'.tr()),
        buildSettingTile(
          icon: Icons.visibility_off_outlined,
          title: 'settings.hidden_songs'.tr(),
          subtitle: 'settings.hidden_songs_desc'.tr(),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'settings.hidden_songs_management_coming_soon'.tr(),
                ),
              ),
            );
          },
        ),
        buildSettingTile(
          icon: Icons.refresh_rounded,
          title: 'settings.re_scan_library'.tr(),
          subtitle: 'settings.re_scan_library_desc'.tr(),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('settings.refreshing_library'.tr())),
            );
            onRescan();
          },
        ),
        const SizedBox(height: 20),
        buildSectionHeader('settings.appearance'.tr()),
        buildSettingTile(
          icon: Icons.palette_outlined,
          title: 'settings.theme_mode'.tr(),
          subtitle: 'settings.theme_mode_desc'.tr(),
          trailing: buildBadge('settings.dark'.tr()),
        ),
        buildSettingTile(
          icon: Icons.language_rounded,
          title: 'settings.language'.tr(),
          subtitle: 'settings.language_desc'.tr(),
          onTap: () => showLanguageDialog(context, cubit),
          trailing: buildBadge(
            state.languageCode == 'ar'
                ? 'settings.arabic'.tr()
                : 'settings.english'.tr(),
          ),
        ),
        const SizedBox(height: 20),
        buildSectionHeader('settings.about'.tr()),
        buildSettingTile(
          icon: Icons.info_outline_rounded,
          title: 'settings.version'.tr(),
          subtitle: '1.0.0 (V24.04)',
        ),
        buildSettingTile(
          icon: Icons.share_rounded,
          title: 'settings.share_app'.tr(),
          onTap: () {},
        ),
        buildSettingTile(
          icon: Icons.star_outline_rounded,
          title: 'settings.rate_app'.tr(),
          onTap: () {},
        ),
        const SizedBox(height: 40),
        buildFooter(),
      ],
    );
  }
}
