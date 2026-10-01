import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/app/error_app.dart';
import 'package:music/app/main_app.dart';
import 'package:music/core/services/app_version_service.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/audio/permission_service.dart';
import 'package:music/core/services/cache_helper.dart';
import 'package:music/core/services/smart_notification_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await CacheHelper.init();
  try {
    final isNewVersion = await AppVersionService().isNewVersion();
    developer.log('Is New Version: $isNewVersion', name: 'MB-Music');

    await PermissionService.requestAudioPermissions();
    await PermissionService.requestNotificationPermission();
    await SmartNotificationService.instance.initialize();
    await FavoritesService().loadFavorites();
    await AudioService().init();

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        saveLocale: true,
        child: Builder(
          builder: (context) => Directionality(
            textDirection: ui.TextDirection.ltr,
            child: MainApp(isNewVersion: isNewVersion),
          ),
        ),
      ),
    );
  } catch (e, s) {
    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        saveLocale: true,
        child: Builder(
          builder: (context) => Directionality(
            textDirection: ui.TextDirection.ltr,
            child: ErrorApp(error: e.toString(), stack: s.toString()),
          ),
        ),
      ),
    );
  }
}
