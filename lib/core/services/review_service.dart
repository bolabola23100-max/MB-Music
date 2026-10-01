import 'package:in_app_review/in_app_review.dart';
import 'package:music/core/services/cache_helper.dart';

class ReviewService {
  final inAppReview = InAppReview.instance;

  Future<void> requestReview() async {
    final isAvailable = await inAppReview.isAvailable();
    print('❤️❤️❤️❤️ InAppReview isAvailable: $isAvailable');

    if (isAvailable) {
      await inAppReview.requestReview();
    } else {
      print(
        '⚠️ InAppReview is NOT available (Normal on Emulator / Debug Mode / App not downloaded from Google Play Store).',
      );
    }
  }

  Future<void> openStoreListing() async {
    await inAppReview.openStoreListing();
  }

  Future<void> resetReviewCount() async {
    CacheHelper.reviewActionCount = 0;
    print('❤️❤️❤️❤️ Review action count reset to 0');
  }

  Future<void> registerPositiveAction() async {
    final currentCount = CacheHelper.reviewActionCount;
    print('❤️❤️❤️❤️ Current review count in cache: $currentCount');

    if (currentCount >= 3) {
      print(
        '❤️❤️❤️❤️ Review count already reached max limit (3). Resetting count or returning.',
      );
      return;
    }

    final newCount = currentCount + 1;
    CacheHelper.reviewActionCount = newCount;

    print('❤️❤️❤️❤️ Review count updated to: $newCount');

    if (newCount == 3) {
      print('❤️❤️❤️❤️ Reached 3 positive actions! Requesting review...');
      await requestReview();
    }
  }
}
