import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../data/repositories/preferences_repository.dart';
import '../../../data/repositories/server_repository.dart';
import '../../../data/services/ad_service.dart';
import '../../../data/services/review_service.dart';
import '../../../data/services/vpn_engine_service.dart';
import '../../../domain/models/app_preferences.dart';
import '../../../domain/models/routed_app.dart';
import '../../../domain/models/vpn_connection.dart';
import '../../../domain/models/vpn_server.dart';

class AppViewModel extends ChangeNotifier {
  AppViewModel({
    required this.preferencesRepository,
    required this.serverRepository,
    required this.vpnEngine,
    AdService? adService,
    ReviewService? reviewService,
  })  : adService = adService ?? NoopAdService(),
        reviewService = reviewService ?? NoopReviewService() {
    _servers = serverRepository.getServers();
    _installedApps = serverRepository.getInstalledApps();
    _statusSub = vpnEngine.statusStream.listen((next) {
      _connectionStatus = next;
      notifyListeners();
    });
    _statsSub = vpnEngine.statsStream.listen((next) {
      _sessionStats = next;
      notifyListeners();
    });
  }

  static const String appName = 'HappyVPN+ (Хэппи ВПН)';
  static const String shortAppName = 'HappyVPN+';
  static const String appVersion = '1.0.11';

  final PreferencesRepository preferencesRepository;
  final ServerRepository serverRepository;
  final VpnEngineService vpnEngine;
  final AdService adService;
  final ReviewService reviewService;

  late final StreamSubscription<VpnConnectionStatus> _statusSub;
  late final StreamSubscription<VpnSessionStats> _statsSub;

  AppPreferences _preferences = AppPreferences.defaults;
  List<VpnServer> _servers = const [];
  List<RoutedApp> _installedApps = const [];
  VpnConnectionStatus _connectionStatus = VpnConnectionStatus.disconnected;
  VpnSessionStats _sessionStats = VpnSessionStats.empty;
  VpnSessionReport? _lastReport;
  bool _isInitialized = false;
  bool _isRefreshingServers = false;
  String? _serverError;

  AppPreferences get preferences => _preferences;
  List<VpnServer> get servers => _servers;
  List<RoutedApp> get installedApps => _installedApps;
  VpnConnectionStatus get connectionStatus => _connectionStatus;
  VpnSessionStats get sessionStats => _sessionStats;
  VpnSessionReport? get lastReport => _lastReport;
  bool get isInitialized => _isInitialized;
  bool get isRefreshingServers => _isRefreshingServers;
  String? get serverError => _serverError;

  VpnServer get selectedServer =>
      serverRepository.resolveServer(_preferences.selectedServerId);

  VpnServer get activeResolvedServer => selectedServer.isAutomatic
      ? serverRepository.getBestServer()
      : selectedServer;

  Future<void> initialize() async {
    _preferences = await preferencesRepository.load();
    _isInitialized = true;
    notifyListeners();
    if (_preferences.privacyConsentCompleted) {
      unawaited(adService.initialize(userConsent: _preferences.usageAnalytics));
    }
  }

  void _triggerHaptic() {
    if (_preferences.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> completePrivacyConsent({required bool allowAnalytics}) async {
    _preferences = await preferencesRepository.update(
      _preferences.copyWith(
        privacyConsentCompleted: true,
        usageAnalytics: allowAnalytics,
      ),
    );
    notifyListeners();
    unawaited(adService.initialize(userConsent: allowAnalytics));
  }

  Future<void> grantVpnPermission({required bool notificationsAllowed}) async {
    _preferences = await preferencesRepository.update(
      _preferences.copyWith(
        vpnPermissionGranted: true,
        vpnNotifications: notificationsAllowed,
      ),
    );
    notifyListeners();
  }

  Future<void> connect() async {
    _triggerHaptic();
    _lastReport = null;
    final target = activeResolvedServer;
    await vpnEngine.connect(target);
  }

  Future<VpnSessionReport?> disconnect() async {
    _triggerHaptic();
    final report = await vpnEngine.disconnect();
    _lastReport = report;
    notifyListeners();
    // Show frequency-capped interstitial AFTER tunnel disconnects (better fill & policy).
    if (report != null) {
      await adService.showInterstitialIfReady();
      // Record completed session for Apple's native SKStoreReviewController prompt.
      unawaited(reviewService.recordCompletedSessionAndMaybePrompt());
    }
    return report;
  }

  Future<void> requestInAppReview() => reviewService.requestNativeReview();

  Future<void> openAppStoreReview() => reviewService.openStoreReviewPage();

  Future<bool> watchRewardedForAdFree() async {
    final earned = await adService.showRewardedAd();
    if (earned) {
      notifyListeners();
    }
    return earned;
  }

  Future<void> onAppResumed() async {
    if (!_preferences.privacyConsentCompleted) return;
    if (_connectionStatus == VpnConnectionStatus.preparing ||
        _connectionStatus == VpnConnectionStatus.connecting) {
      return;
    }
    await adService.showAppOpenIfReady();
  }

  void clearLastReport() {
    _lastReport = null;
    notifyListeners();
  }

  Future<void> selectServer(VpnServer server) async {
    _triggerHaptic();
    final wasConnected = _connectionStatus == VpnConnectionStatus.connected;
    _preferences = await preferencesRepository.update(
      _preferences.copyWith(selectedServerId: server.id),
    );
    notifyListeners();
    if (wasConnected) {
      await vpnEngine.disconnect(endedBy: 'Server switched');
      await connect();
    }
  }

  Future<void> toggleFavorite(String serverId) async {
    _triggerHaptic();
    final nextFavorites = Set<String>.from(_preferences.favoriteServerIds);
    if (!nextFavorites.add(serverId)) {
      nextFavorites.remove(serverId);
    }
    _preferences = await preferencesRepository.update(
      _preferences.copyWith(favoriteServerIds: nextFavorites),
    );
    notifyListeners();
  }

  Future<void> refreshServers() async {
    _isRefreshingServers = true;
    _serverError = null;
    notifyListeners();
    try {
      _servers = await serverRepository.refreshServers();
    } catch (_) {
      _serverError = 'Could not refresh servers. Check your network and try again.';
    } finally {
      _isRefreshingServers = false;
      notifyListeners();
    }
  }

  Future<void> setThemePreference(AppThemePreference theme) async {
    _triggerHaptic();
    _preferences = await preferencesRepository.update(
      _preferences.copyWith(themePreference: theme),
    );
    notifyListeners();
  }

  Future<void> setShowServerLatency(bool value) async {
    _preferences = await preferencesRepository.update(
      _preferences.copyWith(showServerLatency: value),
    );
    notifyListeners();
  }

  Future<void> setHapticFeedback(bool value) async {
    _preferences = await preferencesRepository.update(
      _preferences.copyWith(hapticFeedback: value),
    );
    notifyListeners();
  }

  Future<void> setVpnNotifications(bool value) async {
    _preferences = await preferencesRepository.update(
      _preferences.copyWith(vpnNotifications: value),
    );
    notifyListeners();
  }

  Future<void> setUsageAnalytics(bool value) async {
    _preferences = await preferencesRepository.update(
      _preferences.copyWith(usageAnalytics: value),
    );
    notifyListeners();
    await adService.updateUserConsent(value);
  }

  Future<void> setProxyAllApps(bool value) async {
    _preferences = await preferencesRepository.update(
      _preferences.copyWith(proxyAllApps: value),
    );
    notifyListeners();
  }

  Future<void> toggleAppProxied(String appId) async {
    final next = Set<String>.from(_preferences.proxiedAppIds);
    if (!next.add(appId)) {
      next.remove(appId);
    }
    _preferences = await preferencesRepository.update(
      _preferences.copyWith(proxiedAppIds: next),
    );
    notifyListeners();
  }

  Future<void> submitFeedback({
    required String message,
    required bool includeDiagnostics,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _preferences = await preferencesRepository.update(
      _preferences.copyWith(queuedFeedbackCount: 0),
    );
    notifyListeners();
  }

  Future<void> deleteQueuedFeedback() async {
    _preferences = await preferencesRepository.update(
      _preferences.copyWith(queuedFeedbackCount: 0),
    );
    notifyListeners();
  }

  Future<void> resetPreferences() async {
    _preferences = await preferencesRepository.resetPreferences();
    notifyListeners();
  }

  Future<void> deleteAllAppData() async {
    if (_connectionStatus.isActive) {
      await vpnEngine.disconnect();
    }
    _lastReport = null;
    _preferences = await preferencesRepository.deleteAllAppData();
    notifyListeners();
  }

  String buildDiagnosticsPreview() {
    final server = activeResolvedServer;
    return '''
App: HappyVPN+ (Хэппи ВПН) $appVersion
Status: ${_connectionStatus.label}
Selected server: ${selectedServer.displayName} (${server.id})
Protocol: ${server.protocol}
Routing: ${_preferences.proxyAllApps ? 'Proxy all apps' : '${_preferences.proxiedAppIds.length} selected apps'}
Latency: ${_sessionStats.latencyMs > 0 ? '${_sessionStats.latencyMs} ms' : '${server.latencyMs} ms'}
Platform: ${defaultTargetPlatform.name}
'''.trim();
  }

  @override
  void dispose() {
    _statusSub.cancel();
    _statsSub.cancel();
    adService.dispose();
    vpnEngine.dispose();
    super.dispose();
  }
}
