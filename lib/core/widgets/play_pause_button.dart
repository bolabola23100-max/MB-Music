import 'package:flutter/material.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/services/audio/audio_service.dart';

class PlayPauseButton extends StatelessWidget {
  final AudioService audioService;
  final double size;
  final Color? color;

  // جعلنا المتغيرات final وأسميناها بشكل واضح
  final Widget? playIcon;
  final Widget? pauseIcon;

  const PlayPauseButton({
    super.key,
    required this.audioService,
    this.size = 30,
    this.color,
    this.playIcon,
    this.pauseIcon,
  });

  @override
  Widget build(BuildContext context) {
    // تحديد الأيقونات الافتراضية مع تطبيق الحجم واللون
    final defaultPlayIcon = Image.asset(
      AppIcons.playArrow,
      width: size,
      height: size,
      color: color, // لتلوين الأيقونة إذا كانت PNG شفافة
    );

    // ملاحظة: تأكد من إضافة مسار أيقونة الإيقاف المؤقت في ملف AppIcons
    final defaultPauseIcon = Image.asset(
      AppIcons.pause, // تأكد من وجود هذا المتغير في AppIcons
      width: size,
      height: size,
      color: color,
    );

    return ValueListenableBuilder<bool>(
      valueListenable: audioService.isPlayingNotifier,
      builder: (context, isPlaying, _) {
        return IconButton(
          iconSize: size,
          color: color,
          // المنطق الصحيح: إذا كان يعمل أظهر Pause، وإذا كان متوقفاً أظهر Play
          icon: isPlaying
              ? (pauseIcon ?? defaultPauseIcon)
              : (playIcon ?? defaultPlayIcon),
          onPressed: () {
            if (isPlaying) {
              audioService.pause();
            } else {
              // تأكد من وجود دالة resume() في خدمتك، وإلا استخدم play()
              audioService.resume();
            }
          },
        );
      },
    );
  }
}
