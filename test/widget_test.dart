import 'package:flutter_test/flutter_test.dart';
import 'package:music/features/settings/widgets/format_duration.dart';

void main() {
  test('formats durations correctly', () {
    expect(
      formatDuration(const Duration(minutes: 3, seconds: 7)),
      '03:07',
    );
    expect(
      formatDuration(const Duration(hours: 1, minutes: 2, seconds: 9)),
      '1:02:09',
    );
  });
}
