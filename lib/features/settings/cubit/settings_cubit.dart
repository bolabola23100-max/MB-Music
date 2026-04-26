import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final AudioService _audioService = AudioService();

  SettingsCubit() : super(const SettingsState()) {
    _init();
  }

  void _init() {
    _audioService.sleepTimerRemainingNotifier.addListener(_onSleepTimerChanged);
  }

  void _onSleepTimerChanged() {
    emit(state.copyWith(
      sleepTimerRemaining: _audioService.sleepTimerRemainingNotifier.value,
      clearSleepTimer: _audioService.sleepTimerRemainingNotifier.value == null,
    ));
  }

  void setSleepTimer(Duration duration) {
    _audioService.setSleepTimer(duration);
  }

  void stopSleepTimer() {
    _audioService.stopSleepTimer();
  }

  void updateLanguage(String code) {
    emit(state.copyWith(languageCode: code));
  }

  @override
  Future<void> close() {
    _audioService.sleepTimerRemainingNotifier.removeListener(_onSleepTimerChanged);
    return super.close();
  }
}
