import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/features/listening_stats_screen/screens/listening_stats_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music/features/settings/cubit/settings_cubit.dart';
import 'package:music/features/settings/cubit/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.songs,
    required this.audioService,
  });

  final List<SongModel> songs;
  final AudioService audioService;

  Future<void> rescanLibrary() async {
    // Logic for library rescan
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SettingsCubit()..updateLanguage(context.locale.languageCode),
      child: SettingsView(
        songs: songs,
        audioService: audioService,
        rescanLibrary: rescanLibrary,
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  final List<SongModel> songs;
  final AudioService audioService;
  final Future<void> Function() rescanLibrary;

  const SettingsView({
    super.key,
    required this.songs,
    required this.audioService,
    required this.rescanLibrary,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        return Scaffold(
          backgroundColor: AppColors.black,
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
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 10),
              _buildSectionHeader('settings.general'.tr()),
              _buildSettingTile(
                icon: Icons.bar_chart_rounded,
                title: 'settings.listening_stats'.tr(),
                subtitle: 'settings.listening_stats_desc'.tr(),
                onTap: () {
                  AppNavigator.push(
                    context,
                    ListeningStatsScreen(
                      allSongs: songs,
                      audioService: audioService,
                    ),
                  );
                },
              ),
              _buildSettingTile(
                icon: Icons.equalizer_rounded,
                title: 'settings.equalizer'.tr(),
                subtitle: 'settings.equalizer_desc'.tr(),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'settings.equalizer_feature_coming_soon'.tr(),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildSectionHeader('settings.audio'.tr()),
              _buildSettingTile(
                icon: Icons.timer_outlined,
                title: 'settings.sleep_timer'.tr(),
                subtitle: state.sleepTimerRemaining == null
                    ? 'settings.off'.tr()
                    : '${'settings.stopping_in'.tr()} ${_formatDuration(state.sleepTimerRemaining!)}',
                onTap: () => _showSleepTimerDialog(context, cubit),
              ),
              _buildSettingTile(
                icon: Icons.high_quality_rounded,
                title: 'settings.audio_quality'.tr(),
                subtitle: 'settings.audio_quality_desc'.tr(),
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _buildSectionHeader('settings.library'.tr()),
              _buildSettingTile(
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
              _buildSettingTile(
                icon: Icons.refresh_rounded,
                title: 'settings.re_scan_library'.tr(),
                subtitle: 'settings.re_scan_library_desc'.tr(),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('settings.refreshing_library'.tr())),
                  );
                  await rescanLibrary();
                },
              ),
              const SizedBox(height: 20),
              _buildSectionHeader('settings.appearance'.tr()),
              _buildSettingTile(
                icon: Icons.palette_outlined,
                title: 'settings.theme_mode'.tr(),
                subtitle: 'settings.theme_mode_desc'.tr(),
                trailing: _buildBadge('settings.dark'.tr()),
              ),
              _buildSettingTile(
                icon: Icons.language_rounded,
                title: 'settings.language'.tr(),
                subtitle: 'settings.language_desc'.tr(),
                onTap: () => _showLanguageDialog(context, cubit),
                trailing: _buildBadge(
                  state.languageCode == 'ar'
                      ? 'settings.arabic'.tr()
                      : 'settings.english'.tr(),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader('settings.about'.tr()),
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: 'settings.version'.tr(),
                subtitle: '1.0.0 (V24.04)',
              ),
              _buildSettingTile(
                icon: Icons.share_rounded,
                title: 'settings.share_app'.tr(),
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.star_outline_rounded,
                title: 'settings.rate_app'.tr(),
                onTap: () {},
              ),
              const SizedBox(height: 40),
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, bottom: 12, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.gray.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.blue, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (trailing != null)
                trailing
              else if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.white.withValues(alpha: 0.2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.blue, fontSize: 12),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Image.asset(
              AppIcons.logo,
              height: 50,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.music_note_rounded,
                size: 50,
                color: AppColors.blue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'MB Music Player',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'settings.made_with_love'.tr(),
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context, SettingsCubit cubit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.gray.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'settings.sleep_timer'.tr(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'settings.automatically_stop_playback_after'.tr(),
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.6,
                children: [
                  _timerOption(context, 'settings.off'.tr(), null, cubit),
                  _timerOption(
                    context,
                    '15m',
                    const Duration(minutes: 15),
                    cubit,
                  ),
                  _timerOption(
                    context,
                    '30m',
                    const Duration(minutes: 30),
                    cubit,
                  ),
                  _timerOption(
                    context,
                    '45m',
                    const Duration(minutes: 45),
                    cubit,
                  ),
                  _timerOption(context, '1h', const Duration(hours: 1), cubit),
                  _timerOption(context, '2h', const Duration(hours: 2), cubit),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _timerOption(
    BuildContext context,
    String label,
    Duration? duration,
    SettingsCubit cubit,
  ) {
    return InkWell(
      onTap: () {
        if (duration == null) {
          cubit.stopSleepTimer();
        } else {
          cubit.setSleepTimer(duration);
        }
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:${twoDigitMinutes}:${twoDigitSeconds}";
    }
    return "${twoDigitMinutes}:${twoDigitSeconds}";
  }

  void _showLanguageDialog(BuildContext context, SettingsCubit cubit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.gray.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'settings.language'.tr(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _languageOption(
                context,
                'settings.english'.tr(),
                'en',
                context.locale.languageCode == 'en',
                cubit,
              ),
              _languageOption(
                context,
                'settings.arabic'.tr(),
                'ar',
                context.locale.languageCode == 'ar',
                cubit,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(
    BuildContext context,
    String title,
    String languageCode,
    bool isSelected,
    SettingsCubit cubit,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.setLocale(Locale(languageCode));
          cubit.updateLanguage(languageCode);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.blue.withValues(alpha: 0.1)
                : AppColors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.blue.withValues(alpha: 0.5)
                  : AppColors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.blue : AppColors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: AppColors.blue)
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
