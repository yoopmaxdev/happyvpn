import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/app_preferences.dart';

class PreferencesStorageService {
  static const _kTheme = 'theme_mode';
  static const _kSelectedServer = 'selected_server_id';
  static const _kFavorites = 'favorite_server_ids';
  static const _kShowLatency = 'show_server_latency';
  static const _kHaptics = 'haptic_feedback';
  static const _kNotifications = 'vpn_notifications';
  static const _kAnalytics = 'usage_analytics';
  static const _kPrivacyDone = 'privacy_consent_completed';
  static const _kProxyAllApps = 'proxy_all_apps';
  static const _kProxiedApps = 'proxied_app_ids';
  static const _kVpnPermission = 'vpn_permission_granted';
  static const _kQueuedFeedback = 'queued_feedback_count';

  Future<AppPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_kTheme) ?? 0;
    final theme = AppThemePreference
        .values[themeIndex.clamp(0, AppThemePreference.values.length - 1)];

    return AppPreferences(
      themePreference: theme,
      selectedServerId: prefs.getString(_kSelectedServer) ?? 'auto',
      favoriteServerIds:
          (prefs.getStringList(_kFavorites) ?? const <String>[]).toSet(),
      showServerLatency: prefs.getBool(_kShowLatency) ?? true,
      hapticFeedback: prefs.getBool(_kHaptics) ?? true,
      vpnNotifications: prefs.getBool(_kNotifications) ?? true,
      usageAnalytics: prefs.getBool(_kAnalytics) ?? false,
      privacyConsentCompleted: prefs.getBool(_kPrivacyDone) ?? false,
      proxyAllApps: prefs.getBool(_kProxyAllApps) ?? true,
      proxiedAppIds:
          (prefs.getStringList(_kProxiedApps) ?? const <String>[]).toSet(),
      vpnPermissionGranted: prefs.getBool(_kVpnPermission) ?? false,
      queuedFeedbackCount: prefs.getInt(_kQueuedFeedback) ?? 0,
    );
  }

  Future<void> save(AppPreferences value) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_kTheme, value.themePreference.index),
      prefs.setString(_kSelectedServer, value.selectedServerId),
      prefs.setStringList(_kFavorites, value.favoriteServerIds.toList()),
      prefs.setBool(_kShowLatency, value.showServerLatency),
      prefs.setBool(_kHaptics, value.hapticFeedback),
      prefs.setBool(_kNotifications, value.vpnNotifications),
      prefs.setBool(_kAnalytics, value.usageAnalytics),
      prefs.setBool(_kPrivacyDone, value.privacyConsentCompleted),
      prefs.setBool(_kProxyAllApps, value.proxyAllApps),
      prefs.setStringList(_kProxiedApps, value.proxiedAppIds.toList()),
      prefs.setBool(_kVpnPermission, value.vpnPermissionGranted),
      prefs.setInt(_kQueuedFeedback, value.queuedFeedbackCount),
    ]);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
