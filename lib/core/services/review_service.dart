import 'dart:developer' as developer;

import 'package:in_app_review/in_app_review.dart';
import 'package:music/core/services/cache_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class ReviewService {
  final inAppReview = InAppReview.instance;

  Future<void> requestReview() async {
    final isAvailable = await inAppReview.isAvailable();
    developer.log(
      '❤️❤️❤️❤️ InAppReview isAvailable: $isAvailable',
      name: 'ReviewService',
    );

    if (isAvailable) {
      await inAppReview.requestReview();
      return;
    }

    await openStoreReviewPage();
  }

  Future<void> openStoreReviewPage() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.mbmusic.player&reviewId=0',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open Google Play review page');
    }
  }

  Future<void> openStoreListing() async {
    await inAppReview.openStoreListing();
  }

  Future<void> resetReviewCount() async {
    CacheHelper.reviewActionCount = 0;
    developer.log(
      '❤️❤️❤️❤️ Review action count reset to 0',
      name: 'ReviewService',
    );
  }

  Future<void> registerPositiveAction() async {
    final currentCount = CacheHelper.reviewActionCount;
    developer.log(
      '❤️❤️❤️❤️ Current review count in cache: $currentCount',
      name: 'ReviewService',
    );

    if (currentCount >= 3) {
      developer.log(
        '❤️❤️❤️❤️ Review count already reached max limit (3). Resetting count or returning.',
        name: 'ReviewService',
      );
      return;
    }

    final newCount = currentCount + 1;
    CacheHelper.reviewActionCount = newCount;

    developer.log(
      '❤️❤️❤️❤️ Review count updated to: $newCount',
      name: 'ReviewService',
    );

    if (newCount == 3) {
      developer.log(
        '❤️❤️❤️❤️ Reached 3 positive actions! Requesting review...',
        name: 'ReviewService',
      );
      await requestReview();
    }
  }
}
