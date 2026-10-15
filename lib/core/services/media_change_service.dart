import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MediaChangeService {
  static final MediaChangeService _instance = MediaChangeService._internal();
  factory MediaChangeService() => _instance;
  MediaChangeService._internal();

  static const EventChannel _channel =
      EventChannel('com.mbmusic.player/media_changes');

  late final Stream<void> changes = _channel
      .receiveBroadcastStream()
      .map<void>((_) {})
      .asBroadcastStream()
      .handleError((Object error, StackTrace stackTrace) {
        debugPrint('MediaChangeService error: $error');
        debugPrintStack(stackTrace: stackTrace);
      });
}
