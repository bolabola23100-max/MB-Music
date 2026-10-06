import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:music/app/main_app.dart';
import 'package:music/core/services/app_version_service.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/audio/permission_service.dart';
import 'package:music/core/services/cache_helper.dart';
import 'package:music/core/services/smart_notification_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // CacheHelper is the only startup dependency because SplashScreen reads it.
  // All other services are initialized after the first Flutter frame so the
  // application can render even if a platform service is slow or unavailable.
  try {
    await CacheHelper.init();
  } catch (e, s) {
    developer.log(
      'Cache initialization failed: $e',
      name: 'MB-Music',
      error: e,
      stackTrace: s,
    );
  }

  runApp(const _StartupApp());
}

class _StartupApp extends StatefulWidget {
  const _StartupApp();

  @override
  State<_StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<_StartupApp> {
  bool _isNewVersion = false;
  bool _startupError = false;
  Object? _startupException;
  StackTrace? _startupStack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    // The UI is already visible here. Nothing below should prevent the first
    // frame from being displayed.
    try {
      final isNewVersion = await AppVersionService().isNewVersion();
      if (mounted) {
        setState(() => _isNewVersion = isNewVersion);
      }
    } catch (e, s) {
      developer.log(
        'App version check failed: $e',
        name: 'MB-Music',
        error: e,
        stackTrace: s,
      );
    }

    // Permissions must never be requested before the first frame.
    try {
      await PermissionService.requestAudioPermissions();
    } catch (e, s) {
      developer.log(
        'Audio permission request failed: $e',
        name: 'MB-Music',
        error: e,
        stackTrace: s,
      );
    }

    try {
      await PermissionService.requestNotificationPermission();
    } catch (e, s) {
      developer.log(
        'Notification permission request failed: $e',
        name: 'MB-Music',
        error: e,
        stackTrace: s,
      );
    }

    // These services are optional for opening the app.
    try {
      await SmartNotificationService.instance.initialize();
    } catch (e, s) {
      developer.log(
        'Smart notifications failed to initialize: $e',
        name: 'MB-Music',
        error: e,
        stackTrace: s,
      );
    }

    try {
      await FavoritesService().loadFavorites();
    } catch (e, s) {
      developer.log(
        'Favorites failed to load: $e',
        name: 'MB-Music',
        error: e,
        stackTrace: s,
      );
    }

    // Audio initialization is intentionally after the first frame. It may
    // restore an old file, configure AudioSession, or initialize the EQ.
    try {
      await AudioService().init();
    } catch (e, s) {
      developer.log(
        'Audio service failed to initialize: $e',
        name: 'MB-Music',
        error: e,
        stackTrace: s,
      );

      // Keep the app usable even if audio initialization fails on a device.
      if (mounted) {
        setState(() {
          _startupError = true;
          _startupException = e;
          _startupStack = s;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_startupError &&
        _startupException != null &&
        _startupStack != null) {
      // Do not replace the normal UI with an error screen. Audio is optional
      // for initial rendering, so keep the app available and only log details.
      developer.log(
        'Non-fatal startup service error: $_startupException',
        name: 'MB-Music',
        error: _startupException,
        stackTrace: _startupStack,
      );
    }

    return EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      child: Builder(
        builder: (context) => Directionality(
          textDirection: ui.TextDirection.ltr,
          child: MainApp(isNewVersion: _isNewVersion),
        ),
      ),
    );
  }
}
