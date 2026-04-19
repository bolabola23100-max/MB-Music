import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// ✅ Service to delete songs using the native Android MediaStore API.
/// Works on ALL Android versions:
/// - Android 10 and below: Uses ContentResolver.delete()
/// - Android 11+: Uses MediaStore.createDeleteRequest() (system dialog)
class SongDeleteService {
  static const _channel = MethodChannel('com.example.music/delete');

  /// Deletes songs by their MediaStore IDs.
  /// Returns a [SongDeleteResult] indicating success/failure.
  static Future<SongDeleteResult> deleteSongs(List<int> songIds) async {
    try {
      final result = await _channel.invokeMethod('deleteSongs', {
        'songIds': songIds,
      });

      final map = Map<String, dynamic>.from(result);
      final deleted = map['deleted'] as bool? ?? false;
      final count = map['count'] as int? ?? 0;

      return SongDeleteResult(
        success: deleted,
        deletedCount: count,
      );
    } on PlatformException catch (e) {
      debugPrint('❌ SongDeleteService error: ${e.message}');
      return SongDeleteResult(success: false, deletedCount: 0);
    } catch (e) {
      debugPrint('❌ SongDeleteService unexpected error: $e');
      return SongDeleteResult(success: false, deletedCount: 0);
    }
  }
}

class SongDeleteResult {
  final bool success;
  final int deletedCount;

  const SongDeleteResult({
    required this.success,
    required this.deletedCount,
  });
}
