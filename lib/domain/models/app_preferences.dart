import 'package:flutter/material.dart';

enum AppThemePreference {
  system('System', 'Use device appearance', ThemeMode.system),
  light('Light', 'Light theme', ThemeMode.light),
  dark('Dark', 'Dark theme', ThemeMode.dark);

  const AppThemePreference(this.label, this.description, this.themeMode);
  final String label;
  final String description;
  final ThemeMode themeMode;
}

@immutable
class AppPreferences {
  const AppPreferences({
    this.themePreference = AppThemePreference.system,
    this.selectedServerId = 'auto',
    this.favoriteServerIds = const <String>{},
    this.showServerLatency = true,
    this.hapticFeedback = true,
    this.vpnNotifications = true,
    this.usageAnalytics = false,
    this.privacyConsentCompleted = false,
    this.proxyAllApps = true,
    this.proxiedAppIds = const <String>{},
    this.vpnPermissionGranted = false,
    this.queuedFeedbackCount = 0,
  });

  final AppThemePreference themePreference;
  final String selectedServerId;
  final Set<String> favoriteServerIds;
  final bool showServerLatency;
  final bool hapticFeedback;
  final bool vpnNotifications;
  final bool usageAnalytics;
  final bool privacyConsentCompleted;
  final bool proxyAllApps;
  final Set<String> proxiedAppIds;
  final bool vpnPermissionGranted;
  final int queuedFeedbackCount;

  static const defaults = AppPreferences();

  AppPreferences copyWith({
    AppThemePreference? themePreference,
    String? selectedServerId,
    Set<String>? favoriteServerIds,
    bool? showServerLatency,
    bool? hapticFeedback,
    bool? vpnNotifications,
    bool? usageAnalytics,
    bool? privacyConsentCompleted,
    bool? proxyAllApps,
    Set<String>? proxiedAppIds,
    bool? vpnPermissionGranted,
    int? queuedFeedbackCount,
  }) {
    return AppPreferences(
      themePreference: themePreference ?? this.themePreference,
      selectedServerId: selectedServerId ?? this.selectedServerId,
      favoriteServerIds: favoriteServerIds ?? this.favoriteServerIds,
      showServerLatency: showServerLatency ?? this.showServerLatency,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      vpnNotifications: vpnNotifications ?? this.vpnNotifications,
      usageAnalytics: usageAnalytics ?? this.usageAnalytics,
      privacyConsentCompleted:
          privacyConsentCompleted ?? this.privacyConsentCompleted,
      proxyAllApps: proxyAllApps ?? this.proxyAllApps,
      proxiedAppIds: proxiedAppIds ?? this.proxiedAppIds,
      vpnPermissionGranted: vpnPermissionGranted ?? this.vpnPermissionGranted,
      queuedFeedbackCount: queuedFeedbackCount ?? this.queuedFeedbackCount,
    );
  }
}
