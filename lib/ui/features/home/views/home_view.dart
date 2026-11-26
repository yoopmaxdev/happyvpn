import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/country_flag_badge.dart';
import '../../../core/widgets/latency_badge.dart';
import '../../../../domain/models/vpn_connection.dart';
import '../../app/app_view_model.dart';
import 'session_report_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    required this.viewModel,
    required this.onOpenServers,
    required this.onOpenFeedback,
  });

  final AppViewModel viewModel;
  final VoidCallback onOpenServers;
  final VoidCallback onOpenFeedback;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    widget.viewModel.addListener(_syncPulseAnimation);
    _syncPulseAnimation();
  }

  void _syncPulseAnimation() {
    final active = widget.viewModel.connectionStatus.isActive;
    if (active && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!active && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncPulseAnimation);
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handlePowerTap() async {
    final vm = widget.viewModel;
    final status = vm.connectionStatus;

    if (status == VpnConnectionStatus.connected) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Disconnect from ${vm.activeResolvedServer.city}?'),
          content: const Text(
            'Your traffic will return to your direct internet connection.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Disconnect'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await vm.disconnect();
      }
      return;
    }

    if (status == VpnConnectionStatus.preparing ||
        status == VpnConnectionStatus.connecting) {
      await vm.disconnect();
      return;
    }

    if (!vm.preferences.vpnPermissionGranted) {
      final granted = await _showPermissionsSheet();
      if (!granted) return;
    }

    await vm.connect();
  }

  Future<bool> _showPermissionsSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Connection permissions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Android needs your approval to create the VPN tunnel. Allow notifications to see your VPN status and disconnect from the notification.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  await widget.viewModel
                      .grantVpnPermission(notificationsAllowed: true);
                  if (context.mounted) Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.vpn_lock_rounded),
                label: const Text('Allow VPN & notifications'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  await widget.viewModel
                      .grantVpnPermission(notificationsAllowed: false);
                  if (context.mounted) Navigator.of(context).pop(true);
                },
                child: const Text('Continue without notifications'),
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final report = vm.lastReport;
        if (report != null && vm.connectionStatus == VpnConnectionStatus.disconnected) {
          return SessionReportView(
            report: report,
            onBackHome: vm.clearLastReport,
            onReconnect: () async {
              vm.clearLastReport();
              await vm.connect();
            },
            onRateApp: vm.requestInAppReview,
            onSendFeedback: widget.onOpenFeedback,
          );
        }

        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final status = vm.connectionStatus;
        final stats = vm.sessionStats;
        final selected = vm.selectedServer;
        final resolved = vm.activeResolvedServer;
        final isConnected = status == VpnConnectionStatus.connected;
        final isBusy = status == VpnConnectionStatus.preparing ||
            status == VpnConnectionStatus.connecting;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 30,
                    height: 30,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'HappyVPN+',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Хэппи ВПН',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF10D978),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isConnected ? AppTheme.brandEmerald : colors.outline)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isConnected
                              ? AppTheme.brandEmerald
                              : isBusy
                                  ? Colors.amber
                                  : colors.outline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isConnected
                              ? AppTheme.brandEmerald
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Power Button Hero
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulse = isConnected || isBusy
                            ? _pulseController.value
                            : 0.0;
                        final accent = isConnected
                            ? AppTheme.brandEmerald
                            : isBusy
                                ? Colors.amber
                                : colors.primary;
                        return GestureDetector(
                          onTap: _handlePowerTap,
                          child: Container(
                            width: 196,
                            height: 196,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(
                                alpha: 0.08 + (pulse * 0.08),
                              ),
                              boxShadow: isConnected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.brandEmerald.withValues(
                                          alpha: 0.22 + (pulse * 0.14),
                                        ),
                                        blurRadius: 34,
                                        spreadRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Container(
                              width: 152,
                              height: 152,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isConnected
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF1DF28B),
                                          Color(0xFF00A859),
                                        ],
                                      )
                                    : null,
                                color: isConnected
                                    ? null
                                    : colors.surfaceContainerHighest,
                                border: Border.all(
                                  color: isConnected
                                      ? Colors.transparent
                                      : accent.withValues(alpha: 0.45),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isBusy)
                                    SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: accent,
                                      ),
                                    )
                                  else
                                    Icon(
                                      isConnected
                                          ? Icons.shield_rounded
                                          : Icons.power_settings_new_rounded,
                                      size: 48,
                                      color: isConnected
                                          ? const Color(0xFF032012)
                                          : accent,
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isConnected
                                        ? 'Disconnect'
                                        : isBusy
                                            ? status.label
                                            : 'Connect',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isConnected
                                          ? const Color(0xFF032012)
                                          : colors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isConnected
                        ? Formatters.duration(stats.duration)
                        : 'An encrypted connection',
                    textAlign: TextAlign.center,
                    style: isConnected
                        ? theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )
                        : theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected
                        ? 'Connected to ${resolved.displayName} · ${resolved.protocol}'
                        : 'Device traffic uses your selected server.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Server Selector Card
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: widget.onOpenServers,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CountryFlagBadge(
                              countryCode: selected.countryCode,
                              size: 46,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current server',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selected.isAutomatic
                                        ? 'Automatic server'
                                        : selected.city,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    selected.isAutomatic
                                        ? '${resolved.city} · ${resolved.country}'
                                        : '${selected.country} · ${Formatters.routes(selected.routeCount)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (vm.preferences.showServerLatency) ...[
                              LatencyBadge(
                                latencyMs: isConnected && stats.latencyMs > 0
                                    ? stats.latencyMs
                                    : resolved.latencyMs,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Connection Statistics Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Connection statistics',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isConnected)
                                Text(
                                  resolved.protocol,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _StatTile(
                                  icon: Icons.south_rounded,
                                  label: 'Download',
                                  value: isConnected
                                      ? Formatters.speed(stats.downloadSpeedBps)
                                      : '0 B/s',
                                  subValue: Formatters.bytes(
                                      stats.downloadedBytes),
                                  accent: AppTheme.brandEmerald,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatTile(
                                  icon: Icons.north_rounded,
                                  label: 'Upload',
                                  value: isConnected
                                      ? Formatters.speed(stats.uploadSpeedBps)
                                      : '0 B/s',
                                  subValue:
                                      Formatters.bytes(stats.uploadedBytes),
                                  accent: colors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Split-tunneling / Bypass Notice
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alt_route_rounded,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            vm.preferences.proxyAllApps
                                ? 'Some traffic stays direct: RU sites/IPs and recognized torrents bypass the VPN.'
                                : 'App routing active: ${vm.preferences.proxiedAppIds.length} selected apps use the VPN.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Opt-in Rewarded Ad Card (Apple App Store Guideline compliant)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: vm.adService.isAdFreeActive
                          ? null
                          : () async {
                              final earned = await vm.watchRewardedForAdFree();
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              vm.adService.isAdFreeActive
                                  ? Icons.verified_rounded
                                  : Icons.card_giftcard_rounded,
                              color: colors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vm.adService.isAdFreeActive
                                        ? 'Ad-free mode active'
                                        : 'Go ad-free for 2 hours',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    vm.adService.isAdFreeActive
                                        ? 'Thanks for supporting HappyVPN+'
                                        : 'Optional: watch a short rewarded ad',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!vm.adService.isAdFreeActive)
                              Icon(
                                Icons.play_circle_outline_rounded,
                                color: colors.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subValue,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subValue;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Total $subValue',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
