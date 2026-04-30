import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/audio/permission_service.dart';
import 'package:music/core/services/cache_helper.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/features/onboarding/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await CacheHelper.init();

  try {
    // ✅ 1. اطلب الصلاحيات الأول
    await PermissionService.requestAudioPermissions();
    await PermissionService.requestNotificationPermission();

    // ✅ 2. حمل الـ favorites
    await FavoritesService().loadFavorites();

    // ✅ 3. init الـ AudioService (اللي فيه الـ config الكامل)
    await AudioService().init();

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        saveLocale: true,
        child: const MainApp(),
      ),
    );
  } catch (e, s) {
    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        saveLocale: true,
        child: ErrorApp(error: e.toString(), stack: s.toString()),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        primaryColor: AppColors.white,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.blue,
          selectionColor: AppColors.gray,
          selectionHandleColor: AppColors.blue,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.white),
          bodyLarge: TextStyle(color: AppColors.white),
          bodySmall: TextStyle(color: AppColors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: AppColors.white),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.black,
          selectedItemColor: AppColors.white,
          unselectedItemColor: AppColors.white.withValues(alpha: 0.6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.black,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  final String stack;

  const ErrorApp({super.key, required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              'ERROR:\n$error\n\nSTACK:\n$stack',
              style: const TextStyle(color: AppColors.red, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
