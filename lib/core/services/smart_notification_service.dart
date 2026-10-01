import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class SmartNotificationService with WidgetsBindingObserver {
  SmartNotificationService._();

  static final SmartNotificationService instance = SmartNotificationService._();

  static const int _firstNotificationId = 7300;
  static const int _dailyNotificationId = 7500;
  static const int _scheduledCount = 120;
  static const int _daysBetweenNotifications = 3;
  static const int _morningHour = 10;
  static const int _morningMinute = 0;


  static const List<Map<String, String>> _dailyMessages = [
    {'title': 'صباح الفل يا نجم ☀️', 'body': 'يلا بأغنية كده تظبط المود من بدري 🎧'},
    {'title': 'صباحك مزيكا 🎵', 'body': 'قبل ما اليوم يزنقك.. خدلك أغنية حلوة 😂'},
    {'title': 'صحيت ولا لسه؟ 😂', 'body': 'MB-Music بيقولك صباح الخير يا معلم ☀️'},
    {'title': 'يلا نبدأ اليوم 🎧', 'body': 'أغنية واحدة بس.. وبعدها نشوف اليوم هيودينا فين.'},
    {'title': 'صباح الروقان ☕', 'body': 'القهوة ناقصها أغنية حلوة كده ولا إيه؟'},
    {'title': 'صباح الخير يا صاحبي 👋', 'body': 'شغّل حاجة بتحبها وخلي اليوم يبدأ صح.'},
    {'title': 'الساعة 10 يا نجم ⏰', 'body': 'ده وقت أغنية حلوة.. متخليناش نزعل منك 😂'},
  ];

  static const List<Map<String, String>> _messages = [
    {'title': 'يا نجم 👀', 'body': 'بقالك 3 أيام مش نورت MB-Music.. نروقها بأغنية؟ 🎧'},
    {'title': 'فينك يا معلم 😂', 'body': 'إحنا قولنا نسيّت التطبيق ولا إيه؟ افتح كده واسمع حاجة.'},
    {'title': 'طب حتى أغنية واحدة 🎵', 'body': 'بقالنا كام يوم مش سامعين صوتك.. يلا نبدأ واحدة حلوة.'},
    {'title': 'MB-Music بيسأل عليك 👀', 'body': 'مختفي ليه يا صاحبي؟ تعالى نكمّل الـvibe.'},
    {'title': 'يا عم الغيبة دي كتير 😂', 'body': '3 أيام كاملة؟ افتح MB-Music ونسمع أي حاجة كده.'},
    {'title': 'المزيكا ناقصة حاجة 🤔', 'body': 'آه.. إنت مش موجود 😂 افتح MB-Music ونظبطها.'},
    {'title': 'رجعت في دماغنا 🎧', 'body': 'بقالك شوية غايب.. عندك أغنية تستاهل تتسمع.'},
    {'title': 'إحنا مش بنزن والله 😂', 'body': 'بس افتح MB-Music كده.. يمكن تلاقي المود اللي ناقصك.'},
    {'title': 'صباح المزيكا يا نجم ☀️', 'body': 'لو لسه مبدأتش يومك.. خد أغنية تظبط الدماغ.'},
    {'title': 'عامل إيه يا صاحبي؟ 🎶', 'body': 'بقالك كام يوم سايب المزيكا.. نرجعها ولا إيه؟'},
  ];

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _scheduling = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      WidgetsBinding.instance.addObserver(this);

      tz.initializeTimeZones();
      try {
        final timezone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezone.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      }

      const androidSettings = AndroidInitializationSettings('ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _notifications.initialize(settings);

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'mb_music_daily',
          'MB-Music Daily',
          description: 'Daily MB-Music morning reminders',
          importance: Importance.high,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'mb_music_return',
          'MB-Music',
          description: 'MB-Music return reminders',
          importance: Importance.high,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();

      _initialized = true;
      debugPrint('SmartNotificationService initialized successfully');
      await onAppOpened();
    } catch (error, stackTrace) {
      // Notifications are optional. Never prevent MB-Music from starting.
      debugPrint('SmartNotificationService initialization failed: $error');
      debugPrint('$stackTrace');
      _initialized = false;
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  Future<void> _scheduleDailyNotification() async {
    final now = tz.TZDateTime.now(tz.local);

    var date = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _morningHour,
      _morningMinute,
    );

    if (!date.isAfter(now)) {
      date = date.add(const Duration(days: 1));
    }

    await _scheduleDailyAt(date, repeating: true);
  }

  Future<void> _scheduleDailyAt(
    tz.TZDateTime date, {
    bool repeating = false,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mb_music_daily',
      'MB-Music Daily',
      channelDescription: 'Daily MB-Music morning reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);
    final dayIndex = date.difference(
      tz.TZDateTime(tz.local, 2026, 1, 1),
    ).inDays;
    final message = _dailyMessages[dayIndex % _dailyMessages.length];

    await _notifications.zonedSchedule(
      _dailyNotificationId,
      message['title'],
      message['body'],
      date,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents:
          repeating ? DateTimeComponents.time : null,
      payload: 'mb_music_daily',
    );
  }

  Future<void> sendTestNotification() async {
    if (!_initialized) {
      await initialize();
    }

    if (!_initialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'mb_music_return',
        'MB-Music',
        channelDescription: 'MB-Music return reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const details = NotificationDetails(android: androidDetails);

      await _notifications.show(
        7600,
        'تمام يا نجم 🎧',
        'الإشعارات شغالة عندك وMB-Music جاهز للمزيكا 🔥',
        details,
        payload: 'mb_music_test',
      );
      debugPrint('Smart notifications: test notification sent');
    } catch (error, stackTrace) {
      debugPrint('SmartNotificationService test notification failed: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> onAppOpened() async {
    if (!_initialized) return;
    await _cancelScheduledNotifications();
    await _notifications.cancel(_dailyNotificationId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_initialized) return;

    if (state == AppLifecycleState.resumed) {
      onAppOpened();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      scheduleAfterLeavingApp();
    }
  }

  Future<void> scheduleAfterLeavingApp() async {
    if (!_initialized || _scheduling) return;

    _scheduling = true;
    try {
      debugPrint('Smart notifications: scheduling after app background');
      await _cancelScheduledNotifications();
      await _notifications.cancel(_dailyNotificationId);
      await _scheduleDailyNotification();
      debugPrint('Smart notifications: daily notification scheduled');

      final now = tz.TZDateTime.now(tz.local);

      final threshold = now.add(
        const Duration(days: _daysBetweenNotifications),
      );

      var firstDate = tz.TZDateTime(
        tz.local,
        threshold.year,
        threshold.month,
        threshold.day,
        _morningHour,
        _morningMinute,
      );

      if (!firstDate.isAfter(threshold)) {
        firstDate = firstDate.add(const Duration(days: 1));
      }

      for (var i = 0; i < _scheduledCount; i++) {
        final date = firstDate.add(
          Duration(days: _daysBetweenNotifications * i),
        );
        await _scheduleOne(i, date);
      }
    } catch (error, stackTrace) {
      debugPrint('SmartNotificationService scheduling failed: $error');
      debugPrint('$stackTrace');
    } finally {
      _scheduling = false;
    }
  }

  Future<void> _scheduleOne(int index, tz.TZDateTime date) async {
    final message = _messages[index % _messages.length];

    const androidDetails = AndroidNotificationDetails(
      'mb_music_return',
      'MB-Music',
      channelDescription: 'MB-Music return reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      _firstNotificationId + index,
      message['title'],
      message['body'],
      date,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'mb_music_return',
    );
  }

  Future<void> _cancelScheduledNotifications() async {
    for (var i = 0; i < _scheduledCount; i++) {
      await _notifications.cancel(_firstNotificationId + i);
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }
}
