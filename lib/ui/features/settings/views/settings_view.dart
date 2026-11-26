import 'package:flutter/material.dart';
import '../../../../domain/models/app_preferences.dart';
import '../../app/app_view_model.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.viewModel,
    required this.onOpenAppRouting,
    required this.onOpenFeedback,
    required this.onOpenLicenses,
  });

  final AppViewModel viewModel;
  final VoidCallback onOpenAppRouting;
  final VoidCallback onOpenFeedback;
  final VoidCallback onOpenLicenses;

  Future<void> _showThemeSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final current = viewModel.preferences.themePreference;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                ...AppThemePreference.values.map(
                  (pref) => ListTile(
                    title: Text(pref.label),
                    subtitle: Text(pref.description),
                    trailing: pref == current
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onTap: () async {
                      await viewModel.setThemePreference(pref);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRateDialog(BuildContext context) async {
    final shouldRate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate HappyVPN+'),
        content: const Text(
          'Your review on the App Store helps us keep HappyVPN+ (Хэппи ВПН) fast and free. Would you like to leave a rating?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.star_rounded, size: 18),
            label: const Text('Rate on App Store'),
          ),
        ],
      ),
    );
    if (shouldRate == true) {
      await viewModel.openAppStoreReview();
    }
  }

  Future<void> _confirmResetPreferences(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset preferences?'),
        content: const Text(
          'Restore the system theme, default server and display options, and clear favorites.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await viewModel.resetPreferences();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences reset to defaults.')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAppData(BuildContext context) async {
    if (viewModel.connectionStatus.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disconnect first before deleting app data.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete my app data'),
        content: const Text(
          'This clears cached servers, favorites, queued reports, and resets privacy consent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await viewModel.deleteAllAppData();
    }
  }

  void _showPolicyDialog(BuildContext context, String title, String content) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final prefs = viewModel.preferences;
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _SettingsSection(
                title: 'Appearance',
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Theme'),
                    subtitle: Text(prefs.themePreference.label),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showThemeSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Preferences',
                children: [
                  ListTile(
                    leading: const Icon(Icons.alt_route_rounded),
                    title: const Text('App routing'),
                    subtitle: Text(
                      prefs.proxyAllApps
                          ? 'Proxy all apps'
                          : '${prefs.proxiedAppIds.length} apps selected',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: onOpenAppRouting,
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    secondary: const Icon(Icons.speed_rounded),
                    title: const Text('Show server latency'),
                    value: prefs.showServerLatency,
                    onChanged: viewModel.setShowServerLatency,
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    secondary: const Icon(Icons.vibration_rounded),
                    title: const Text('Haptic feedback'),
                    value: prefs.hapticFeedback,
                    onChanged: viewModel.setHapticFeedback,
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('VPN notifications'),
                    subtitle: const Text('Show VPN status'),
                    value: prefs.vpnNotifications,
                    onChanged: viewModel.setVpnNotifications,
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    secondary: const Icon(Icons.analytics_outlined),
                    title: const Text('Personalized ads & analytics'),
                    subtitle: const Text('Yandex Mobile Ads consent'),
                    value: prefs.usageAnalytics,
                    onChanged: viewModel.setUsageAnalytics,
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.card_giftcard_rounded),
                    title: const Text('Go ad-free for 2 hours'),
                    subtitle: Text(
                      viewModel.adService.isAdFreeActive
                          ? 'Ad-free reward active'
                          : 'Watch a short rewarded ad',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final earned = await viewModel.watchRewardedForAdFree();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              earned
                                  ? 'Ad-free mode enabled for 2 hours!'
                                  : 'Rewarded ad is not ready yet. Please try again shortly.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.restore_rounded),
                    title: const Text('Reset preferences'),
                    onTap: () => _confirmResetPreferences(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'About HappyVPN+ (Хэппи ВПН)',
                children: [
                  ListTile(
                    leading: const Icon(Icons.feedback_outlined),
                    title: const Text('Send feedback'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: onOpenFeedback,
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.star_outline_rounded),
                    title: const Text('Rate HappyVPN+'),
                    subtitle: const Text('App Store review'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showRateDialog(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy policy'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showPolicyDialog(
                      context,
                      'Privacy policy',
                      'HappyVPN+ (Хэппи ВПН) provides free encrypted VPN connections supported by Yandex Mobile Ads. Device traffic uses your selected server and we do not collect browsing history. You can opt out of personalized ads anytime in Settings or iOS Tracking settings.',
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms of service'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showPolicyDialog(
                      context,
                      'Terms of service',
                      'Use HappyVPN+ responsibly and in compliance with applicable laws. Recognized torrents and regional direct-routing rules may bypass the VPN tunnel.',
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.code_rounded),
                    title: const Text('Open-source licenses'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: onOpenLicenses,
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: Icon(Icons.delete_outline_rounded, color: colors.error),
                    title: Text(
                      'Delete my app data',
                      style: TextStyle(color: colors.error),
                    ),
                    onTap: () => _confirmDeleteAppData(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Version ${AppViewModel.appVersion}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HappyVPN+ (Хэппи ВПН) provides free encrypted VPN connections supported by ads.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}
