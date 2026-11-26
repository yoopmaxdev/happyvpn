import 'package:flutter/foundation.dart';
import 'vpn_server.dart';

enum VpnConnectionStatus {
  disconnected,
  preparing,
  connecting,
  connected,
  error;

  bool get isActive =>
      this == VpnConnectionStatus.preparing ||
      this == VpnConnectionStatus.connecting ||
      this == VpnConnectionStatus.connected;

  String get label => switch (this) {
        VpnConnectionStatus.disconnected => 'Not connected',
        VpnConnectionStatus.preparing => 'Preparing',
        VpnConnectionStatus.connecting => 'Connecting',
        VpnConnectionStatus.connected => 'Connected',
        VpnConnectionStatus.error => 'Could not connect',
      };
}

@immutable
class VpnSessionStats {
  const VpnSessionStats({
    this.duration = Duration.zero,
    this.downloadedBytes = 0,
    this.uploadedBytes = 0,
    this.downloadSpeedBps = 0,
    this.uploadSpeedBps = 0,
    this.latencyMs = 0,
  });

  final Duration duration;
  final int downloadedBytes;
  final int uploadedBytes;
  final int downloadSpeedBps;
  final int uploadSpeedBps;
  final int latencyMs;

  static const empty = VpnSessionStats();

  VpnSessionStats copyWith({
    Duration? duration,
    int? downloadedBytes,
    int? uploadedBytes,
    int? downloadSpeedBps,
    int? uploadSpeedBps,
    int? latencyMs,
  }) {
    return VpnSessionStats(
      duration: duration ?? this.duration,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      downloadSpeedBps: downloadSpeedBps ?? this.downloadSpeedBps,
      uploadSpeedBps: uploadSpeedBps ?? this.uploadSpeedBps,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }
}

@immutable
class VpnSessionReport {
  const VpnSessionReport({
    required this.server,
    required this.duration,
    required this.downloadedBytes,
    required this.uploadedBytes,
    required this.endedBy,
    required this.completedAt,
    required this.latencyMs,
  });

  final VpnServer server;
  final Duration duration;
  final int downloadedBytes;
  final int uploadedBytes;
  final String endedBy;
  final DateTime completedAt;
  final int latencyMs;
}
