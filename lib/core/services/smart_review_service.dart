import 'dart:developer' as developer;

import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Requests the native Google Play in-app review at a quiet, eligible moment.
class SmartReviewService {
  SmartReviewService._();

  static final SmartReviewService instance = SmartReviewService._();

  static const _firstLaunchKey = 'smart_review_first_launch';
  static const _songCountKey = 'smart_review_song_count';
  static const _lastSongKey = 'smart_review_last_song';
  static const _attemptCountKey = 'smart_review_attempt_count';
  static const _lastAttemptKey = 'smart_review_last_attempt';

  static const int _minimumDaysSinceFirstLaunch = 3;
  static const int _minimumSongsPlayed = 5;
  static const int _retryAfterDays = 14;
  static const int _maximumAttempts = 3;

  late SharedPreferences _preferences;
  bool _initialized = false;
  bool _requestInProgress = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _preferences = await SharedPreferences.getInstance();
    await _preferences.setString(
      _firstLaunchKey,
      _preferences.getString(_firstLaunchKey) ?? DateTime.now().toIso8601String(),
    );
    _initialized = true;
  }

  Future<void> recordSongStarted(String? songPath) async {
    if (!_initialized || songPath == null || songPath.isEmpty) return;

    final previousPath = _preferences.getString(_lastSongKey);
    if (previousPath == songPath) return;

    await _preferences.setString(_lastSongKey, songPath);
    final count = _preferences.getInt(_songCountKey) ?? 0;
    await _preferences.setInt(_songCountKey, count + 1);
  }

  Future<void> maybeRequestReview({
    required bool appIsResumed,
    required bool isPlaying,
  }) async {
    if (!_initialized ||
        !appIsResumed ||
        isPlaying ||
        _requestInProgress) {
      return;
    }

    final firstLaunchString = _preferences.getString(_firstLaunchKey);
    if (firstLaunchString == null) return;

    final firstLaunch = DateTime.tryParse(firstLaunchString);
    if (firstLaunch == null) return;

    final now = DateTime.now();
    if (now.difference(firstLaunch).inDays < _minimumDaysSinceFirstLaunch) {
      return;
    }

    if ((_preferences.getInt(_songCountKey) ?? 0) < _minimumSongsPlayed) {
      return;
    }

    final attempts = _preferences.getInt(_attemptCountKey) ?? 0;
    if (attempts >= _maximumAttempts) return;

    final lastAttemptString = _preferences.getString(_lastAttemptKey);
    if (lastAttemptString != null) {
      final lastAttempt = DateTime.tryParse(lastAttemptString);
      if (lastAttempt != null &&
          now.difference(lastAttempt).inDays < _retryAfterDays) {
        return;
      }
    }

    _requestInProgress = true;
    try {
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;

      // Save the attempt before calling Google Play to avoid repeated prompts
      // if the platform call returns quickly or the app is resumed again.
      await _preferences.setInt(_attemptCountKey, attempts + 1);
      await _preferences.setString(_lastAttemptKey, now.toIso8601String());
      await review.requestReview();
    } catch (error, stackTrace) {
      developer.log(
        'In-app review request failed: $error',
        name: 'MB-Music',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _requestInProgress = false;
    }
  }
}
