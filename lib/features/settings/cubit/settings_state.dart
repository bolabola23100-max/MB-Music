import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final Duration? sleepTimerRemaining;
  final String languageCode;

  const SettingsState({
    this.sleepTimerRemaining,
    this.languageCode = 'en',
  });

  SettingsState copyWith({
    Duration? sleepTimerRemaining,
    bool clearSleepTimer = false,
    String? languageCode,
  }) {
    return SettingsState(
      sleepTimerRemaining: clearSleepTimer ? null : (sleepTimerRemaining ?? this.sleepTimerRemaining),
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  List<Object?> get props => [sleepTimerRemaining, languageCode];
}
