import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/cache_helper.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/features/onboarding/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await CacheHelper.init();

  try {
    await _requestPermissions();
    await FavoritesService().loadFavorites();
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

Future<void> _requestPermissions() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      await Permission.audio.request();
      await Permission.notification.request();
    } else {
      await Permission.storage.request();
    }
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
        scaffoldBackgroundColor: AppColors.black,
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
          backgroundColor: AppColors.black,
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
