import 'dart:async';

import 'package:flutter/services.dart';

class MediaChangeService {
  static final MediaChangeService _instance = MediaChangeService._internal();
  factory MediaChangeService() => _instance;
  MediaChangeService._internal();

  static const EventChannel _channel =
      EventChannel('com.mbmusic.player/media_changes');

  late final Stream<void> changes = _channel
      .receiveBroadcastStream()
      .handleError((Object error, StackTrace stackTrace) {
        // Keep the stream alive if the native observer reports an error.
      })
      .map<void>((_) {});
}
