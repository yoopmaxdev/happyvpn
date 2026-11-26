import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

import '../../../data/services/ad_service.dart';

/// Anchored sticky Yandex Banner widget (`R-M-20506101-1`).
///
/// Automatically hides itself on unsupported platforms, during an active
/// ad-free reward window, or if no ad is currently loaded.
class YandexBannerSlot extends StatefulWidget {
  const YandexBannerSlot({
    super.key,
    required this.adService,
    this.adUnitId = YandexAdConfig.bannerAdUnitId,
  });

  final AdService adService;
  final String adUnitId;

  @override
  State<YandexBannerSlot> createState() => _YandexBannerSlotState();
}

class _YandexBannerSlotState extends State<YandexBannerSlot> {
  BannerAd? _bannerAd;
  StreamSubscription<BannerAdLoadState>? _loadSub;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initBannerIfNeeded();
  }

  void _initBannerIfNeeded() {
    if (!widget.adService.isSupportedPlatform ||
        widget.adService.isAdFreeActive ||
        _bannerAd != null) {
      return;
    }

    final width = MediaQuery.sizeOf(context).width.round().clamp(300, 728);
    final brightness = Theme.of(context).brightness;
    final banner = BannerAd(adSize: BannerAdSize.sticky(width: width));

    _loadSub = banner.loadStateStream.listen((state) {
      if (!mounted) return;
      final loaded = state is BannerAdLoadStateLoaded;
      if (loaded != _isLoaded) {
        setState(() => _isLoaded = loaded);
      }
    });

    _bannerAd = banner;
    unawaited(
      banner.load(
        AdRequest(
          adUnitId: widget.adUnitId,
          preferredTheme:
              brightness == Brightness.dark ? AdTheme.dark : AdTheme.light,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loadSub?.cancel();
    unawaited(_bannerAd?.destroy());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _bannerAd;
    if (banner == null ||
        !widget.adService.isSupportedPlatform ||
        widget.adService.isAdFreeActive) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        child: Container(
          alignment: Alignment.center,
          padding: _isLoaded
              ? const EdgeInsets.symmetric(vertical: 4)
              : EdgeInsets.zero,
          child: AdWidget(bannerAd: banner),
        ),
      ),
    );
  }
}
