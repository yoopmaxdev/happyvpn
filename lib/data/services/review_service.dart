import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App Store–compliant in-app review manager for HappyVPN+ (iOS App ID 6839425968).
///
/// Follows Apple App Store Review Guidelines 1.1.7 & 5.6.1:
/// - Always uses Apple's native `SKStoreReviewController` (`requestReview`)
///   for automatic prompts with zero sentiment gating or star filtering.
/// - Limits automatic requests to a natural milestone (2nd completed session)
///   with a 90-day cooldown (Apple also enforces <= 3 prompts/year on iOS).
/// - Uses `openStoreListing(appStoreId: '6839425968')` only when the user
///   explicitly taps "Rate HappyVPN+" in Settings or the session report.
abstract class ReviewService {
  static const String iosAppStoreId = '6839425968';

  /// Records a completed VPN session and triggers Apple's native review prompt
  /// when the user reaches a natural milestone.
  Future<void> recordCompletedSessionAndMaybePrompt();

  /// Requests the native OS in-app review sheet (no sentiment gating).
  Future<void> requestNativeReview();

  /// Opens the App Store review page directly for user-initiated taps.
  Future<void> openStoreReviewPage();
}

class StoreReviewService implements ReviewService {
  StoreReviewService({
    this.minSessionsBeforePrompt = 2,
    this.promptCooldown = const Duration(days: 90),
  });

  static const _kCompletedSessions = 'review_completed_sessions';
  static const _kLastPromptEpochMs = 'review_last_prompt_epoch_ms';

  final int minSessionsBeforePrompt;
  final Duration promptCooldown;

  @override
  Future<void> recordCompletedSessionAndMaybePrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_kCompletedSessions) ?? 0) + 1;
      await prefs.setInt(_kCompletedSessions, count);

      if (count < minSessionsBeforePrompt) return;

      final lastMs = prefs.getInt(_kLastPromptEpochMs);
      if (lastMs != null) {
        final elapsed = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(lastMs),
        );
        if (elapsed < promptCooldown) return;
      }

      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
        await prefs.setInt(
          _kLastPromptEpochMs,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      debugPrint('StoreReviewService.recordCompletedSession error: $e');
    }
  }

  @override
  Future<void> requestNativeReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await openStoreReviewPage();
      }
    } catch (e) {
      debugPrint('StoreReviewService.requestNativeReview error: $e');
    }
  }

  @override
  Future<void> openStoreReviewPage() async {
    try {
      await InAppReview.instance.openStoreListing(
        appStoreId: ReviewService.iosAppStoreId,
      );
    } catch (e) {
      debugPrint('StoreReviewService.openStoreReviewPage error: $e');
    }
  }
}

/// Safe no-op implementation for widget tests.
class NoopReviewService implements ReviewService {
  int completedSessionsRecorded = 0;
  int nativeReviewCalls = 0;
  int storeListingCalls = 0;

  @override
  Future<void> recordCompletedSessionAndMaybePrompt() async {
    completedSessionsRecorded++;
  }

  @override
  Future<void> requestNativeReview() async {
    nativeReviewCalls++;
  }

  @override
  Future<void> openStoreReviewPage() async {
    storeListingCalls++;
  }
}
