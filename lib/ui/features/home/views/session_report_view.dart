import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/country_flag_badge.dart';
import '../../../../domain/models/vpn_connection.dart';

class SessionReportView extends StatelessWidget {
  const SessionReportView({
    super.key,
    required this.report,
    required this.onBackHome,
    required this.onReconnect,
    required this.onRateApp,
    required this.onSendFeedback,
  });

  final VpnSessionReport report;
  final VoidCallback onBackHome;
  final VoidCallback onReconnect;
  final VoidCallback onRateApp;
  final VoidCallback onSendFeedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session report'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: onBackHome,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CountryFlagBadge(
                        countryCode: report.server.countryCode,
                        size: 56,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Disconnected',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.server.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const Divider(height: 28),
                      _ReportRow(
                        label: 'Session duration',
                        value: Formatters.duration(report.duration),
                      ),
                      const SizedBox(height: 12),
                      _ReportRow(
                        label: 'Downloaded',
                        value: Formatters.bytes(report.downloadedBytes),
                      ),
                      const SizedBox(height: 12),
                      _ReportRow(
                        label: 'Uploaded',
                        value: Formatters.bytes(report.uploadedBytes),
                      ),
                      const SizedBox(height: 12),
                      _ReportRow(
                        label: 'Latency',
                        value: Formatters.latency(report.latencyMs),
                      ),
                      const SizedBox(height: 12),
                      _ReportRow(
                        label: 'Ended by',
                        value: report.endedBy,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // App Store–compliant rating card (triggers native SKStoreReviewController
              // without sentiment gating or custom star filtering).
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Enjoying HappyVPN+?',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Share your review on the App Store to help others discover HappyVPN+.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: onRateApp,
                        icon: const Icon(Icons.star_rounded, color: Colors.amber),
                        label: const Text('Rate HappyVPN+'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: onReconnect,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reconnect'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onBackHome,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Back to home'),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: onSendFeedback,
                icon: const Icon(Icons.feedback_outlined, size: 18),
                label: const Text('Send feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
