import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:music/core/services/audio/audio_service.dart' as app_service;
import 'audio_persistence_helper.dart';

class SleepTimerHandler {
  Timer? _sleepTimer;
  final VoidCallback onTimerElapsed;

  SleepTimerHandler({required this.onTimerElapsed});

  Future<void> loadPersistentSleepTimer() async {
    final endTime = await AudioPersistenceHelper.getSleepTimerEndTime();
    if (endTime != null) {
      final remaining = endTime.difference(DateTime.now());
      if (remaining.inSeconds > 0) {
        startSleepTimer(remaining);
      } else {
        await AudioPersistenceHelper.clearSleepTimer();
      }
    }
  }

  Future<void> setSleepTimer(Duration duration) async {
    _sleepTimer?.cancel();
    final endTime = DateTime.now().add(duration);
    await AudioPersistenceHelper.saveSleepTimerEndTime(endTime);
    startSleepTimer(duration);
  }

  Future<void> stopSleepTimer() async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    app_service.AudioService().sleepTimerRemainingNotifier.value = null;
    await AudioPersistenceHelper.clearSleepTimer();
  }

  void startSleepTimer(Duration duration) {
    app_service.AudioService().sleepTimerRemainingNotifier.value = duration;
    _sleepTimer?.cancel();
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final currentRemaining =
          app_service.AudioService().sleepTimerRemainingNotifier.value;
      if (currentRemaining == null || currentRemaining.inSeconds <= 0) {
        timer.cancel();
        _sleepTimer = null;
        onTimerElapsed();
        await AudioPersistenceHelper.clearSleepTimer();
        app_service.AudioService().sleepTimerRemainingNotifier.value = null;
      } else {
        app_service.AudioService().sleepTimerRemainingNotifier.value =
            currentRemaining - const Duration(seconds: 1);
      }
    });
  }

  void cancel() {
    _sleepTimer?.cancel();
  }
}
