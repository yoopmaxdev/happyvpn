import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// Centralized Yandex Mobile Ads unit IDs for HappyVPN / Super VPN.
///
/// Note: `yandex_mobileads` 8.7.0 provides Flutter APIs for Banner,
/// Interstitial, Rewarded, and App Open ads. Native and Feed ad unit IDs are
/// also registered here for native platform-view extensions.
class YandexAdConfig {
  static const String appId = '20506101';
  static const String bannerAdUnitId = 'R-M-20506101-1';
  static const String interstitialAdUnitId = 'R-M-20506101-2';
  static const String rewardedAdUnitId = 'R-M-20506101-3';
  static const String nativeAdUnitId = 'R-M-20506101-4';
  static const String appOpenAdUnitId = 'R-M-20506101-5';
  static const String feedAdUnitId = 'R-M-20506101-6';
}

/// Abstraction for ad delivery so tests and desktop targets can use [NoopAdService].
abstract class AdService {
  bool get isSupportedPlatform;
  bool get isInitialized;
  DateTime? get adFreeUntil;
  bool get isAdFreeActive =>
      adFreeUntil != null && DateTime.now().isBefore(adFreeUntil!);

  /// Initializes Yandex Mobile Ads after requesting iOS ATT (if applicable)
  /// and applying the user's privacy consent choice.
  Future<void> initialize({required bool userConsent});

  /// Updates user consent dynamically when toggled in Settings.
  Future<void> updateUserConsent(bool userConsent);

  /// Shows a frequency-capped interstitial ad (e.g. post-disconnect).
  Future<void> showInterstitialIfReady();

  /// Shows an opt-in rewarded ad and grants an ad-free window on reward.
  Future<bool> showRewardedAd({Duration rewardDuration = const Duration(hours: 2)});

  /// Shows a frequency-capped App Open ad on app resume.
  Future<void> showAppOpenIfReady();

  void dispose();
}

class YandexAdService implements AdService {
  YandexAdService({
    this.interstitialCooldown = const Duration(minutes: 3),
    this.appOpenCooldown = const Duration(minutes: 4),
  });

  final Duration interstitialCooldown;
  final Duration appOpenCooldown;

  bool _initialized = false;
  bool _isShowingFullscreen = false;
  DateTime? _lastInterstitialAt;
  DateTime? _lastAppOpenAt;
  DateTime? _adFreeUntil;

  InterstitialAdLoader? _interstitialLoader;
  InterstitialAd? _interstitialAd;

  RewardedAdLoader? _rewardedLoader;
  RewardedAd? _rewardedAd;

  AppOpenAdLoader? _appOpenLoader;
  AppOpenAd? _appOpenAd;

  @override
  bool get isSupportedPlatform => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  @override
  bool get isInitialized => _initialized;

  @override
  DateTime? get adFreeUntil => _adFreeUntil;

  @override
  bool get isAdFreeActive =>
      _adFreeUntil != null && DateTime.now().isBefore(_adFreeUntil!);

  @override
  Future<void> initialize({required bool userConsent}) async {
    if (!isSupportedPlatform || _initialized) return;

    try {
      // Apple App Store Guideline 5.1.2: request ATT on iOS after onboarding.
      bool trackingAuthorized = userConsent;
      if (Platform.isIOS) {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          final nextStatus =
              await AppTrackingTransparency.requestTrackingAuthorization();
          trackingAuthorized =
              userConsent && nextStatus == TrackingStatus.authorized;
        } else {
          trackingAuthorized =
              userConsent && status == TrackingStatus.authorized;
        }
      }

      await YandexAds.setUserConsent(trackingAuthorized);
      await YandexAds.setLocationTracking(false);
      await YandexAds.setLogging(kDebugMode);
      await YandexAds.initialize();

      _interstitialLoader = InterstitialAdLoader();
      _rewardedLoader = RewardedAdLoader();
      _appOpenLoader = AppOpenAdLoader();
      _initialized = true;

      // Preload fullscreen formats in the background (before VPN connects).
      unawaited(_preloadInterstitial());
      unawaited(_preloadRewarded());
      unawaited(_preloadAppOpen());
    } catch (e) {
      debugPrint('YandexAdService.initialize error: $e');
    }
  }

  @override
  Future<void> updateUserConsent(bool userConsent) async {
    if (!isSupportedPlatform) return;
    try {
      bool effectiveConsent = userConsent;
      if (Platform.isIOS) {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        effectiveConsent = userConsent && status == TrackingStatus.authorized;
      }
      await YandexAds.setUserConsent(effectiveConsent);
    } catch (e) {
      debugPrint('YandexAdService.updateUserConsent error: $e');
    }
  }

  Future<void> _preloadInterstitial() async {
    if (!_initialized || _interstitialAd != null) return;
    try {
      _interstitialAd = await _interstitialLoader?.loadAd(
        adRequest: const AdRequest(
          adUnitId: YandexAdConfig.interstitialAdUnitId,
        ),
      );
    } catch (e) {
      debugPrint('Yandex interstitial preload skipped: $e');
    }
  }

  Future<void> _preloadRewarded() async {
    if (!_initialized || _rewardedAd != null) return;
    try {
      _rewardedAd = await _rewardedLoader?.loadAd(
        adRequest: const AdRequest(
          adUnitId: YandexAdConfig.rewardedAdUnitId,
        ),
      );
    } catch (e) {
      debugPrint('Yandex rewarded preload skipped: $e');
    }
  }

  Future<void> _preloadAppOpen() async {
    if (!_initialized || _appOpenAd != null) return;
    try {
      _appOpenAd = await _appOpenLoader?.loadAd(
        adRequest: const AdRequest(
          adUnitId: YandexAdConfig.appOpenAdUnitId,
        ),
      );
    } catch (e) {
      debugPrint('Yandex app open preload skipped: $e');
    }
  }

  @override
  Future<void> showInterstitialIfReady() async {
    if (!_initialized || isAdFreeActive || _isShowingFullscreen) return;
    if (_lastInterstitialAt != null &&
        DateTime.now().difference(_lastInterstitialAt!) < interstitialCooldown) {
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      unawaited(_preloadInterstitial());
      return;
    }

    _interstitialAd = null;
    _isShowingFullscreen = true;
    try {
      await ad.setAdEventListener(
        eventListener: InterstitialAdEventListener(
          onAdDismissed: () => ad.destroy(),
          onAdFailedToShow: (_) => ad.destroy(),
        ),
      );
      await ad.show();
      await ad.waitForDismiss();
      _lastInterstitialAt = DateTime.now();
    } catch (e) {
      debugPrint('Yandex interstitial show error: $e');
      await ad.destroy();
    } finally {
      _isShowingFullscreen = false;
      unawaited(_preloadInterstitial());
    }
  }

  @override
  Future<bool> showRewardedAd({
    Duration rewardDuration = const Duration(hours: 2),
  }) async {
    if (!_initialized || _isShowingFullscreen) return false;

    RewardedAd? ad = _rewardedAd;
    if (ad == null) {
      await _preloadRewarded();
      ad = _rewardedAd;
    }
    if (ad == null) return false;

    _rewardedAd = null;
    _isShowingFullscreen = true;
    var earned = false;
    try {
      await ad.setAdEventListener(
        eventListener: RewardedAdEventListener(
          onRewarded: (_) => earned = true,
          onAdDismissed: () => ad?.destroy(),
          onAdFailedToShow: (_) => ad?.destroy(),
        ),
      );
      await ad.show();
      final reward = await ad.waitForDismiss();
      if (reward != null) earned = true;
      if (earned) {
        _adFreeUntil = DateTime.now().add(rewardDuration);
      }
      return earned;
    } catch (e) {
      debugPrint('Yandex rewarded show error: $e');
      await ad.destroy();
      return false;
    } finally {
      _isShowingFullscreen = false;
      unawaited(_preloadRewarded());
    }
  }

  @override
  Future<void> showAppOpenIfReady() async {
    if (!_initialized || isAdFreeActive || _isShowingFullscreen) return;
    if (_lastAppOpenAt != null &&
        DateTime.now().difference(_lastAppOpenAt!) < appOpenCooldown) {
      return;
    }

    final ad = _appOpenAd;
    if (ad == null) {
      unawaited(_preloadAppOpen());
      return;
    }

    _appOpenAd = null;
    _isShowingFullscreen = true;
    try {
      await ad.setAdEventListener(
        eventListener: AppOpenAdEventListener(
          onAdDismissed: () => ad.destroy(),
          onAdFailedToShow: (_) => ad.destroy(),
        ),
      );
      await ad.show();
      await ad.waitForDismiss();
      _lastAppOpenAt = DateTime.now();
    } catch (e) {
      debugPrint('Yandex app open show error: $e');
      await ad.destroy();
    } finally {
      _isShowingFullscreen = false;
      unawaited(_preloadAppOpen());
    }
  }

  @override
  void dispose() {
    unawaited(_interstitialAd?.destroy());
    unawaited(_rewardedAd?.destroy());
    unawaited(_appOpenAd?.destroy());
    _interstitialAd = null;
    _rewardedAd = null;
    _appOpenAd = null;
  }
}

/// Safe no-op implementation for widget tests and unsupported platforms.
class NoopAdService implements AdService {
  DateTime? _adFreeUntil;

  @override
  bool get isSupportedPlatform => false;

  @override
  bool get isInitialized => true;

  @override
  DateTime? get adFreeUntil => _adFreeUntil;

  @override
  bool get isAdFreeActive =>
      _adFreeUntil != null && DateTime.now().isBefore(_adFreeUntil!);

  @override
  Future<void> initialize({required bool userConsent}) async {}

  @override
  Future<void> updateUserConsent(bool userConsent) async {}

  @override
  Future<void> showInterstitialIfReady() async {}

  @override
  Future<bool> showRewardedAd({
    Duration rewardDuration = const Duration(hours: 2),
  }) async {
    _adFreeUntil = DateTime.now().add(rewardDuration);
    return true;
  }

  @override
  Future<void> showAppOpenIfReady() async {}

  @override
  void dispose() {}
}
