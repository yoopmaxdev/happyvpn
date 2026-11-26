import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import '../../domain/models/vpn_connection.dart';
import '../../domain/models/vpn_server.dart';

/// Abstraction over the VPN tunnel engine.
///
/// The original Android APK runs `sing-box` (`libbox.so`/`libsingbox.so`) +
/// `ByeDPI` (`libbyedpi.so`) inside `LiteVpnService`. This service exposes a
/// platform-channel bridge (`con.supervpn.premium.vpn.proxy/vpn`) with a
/// realistic local simulation fallback so the Flutter app runs smoothly on
/// Android, iOS, macOS, and Web without requiring native binaries yet.
abstract class VpnEngineService {
  Stream<VpnConnectionStatus> get statusStream;
  Stream<VpnSessionStats> get statsStream;

  VpnConnectionStatus get currentStatus;
  VpnSessionStats get currentStats;

  Future<void> connect(VpnServer server);
  Future<VpnSessionReport?> disconnect({String endedBy = 'You or the system'});
  void dispose();
}

class SimulatedVpnEngineService implements VpnEngineService {
  SimulatedVpnEngineService({
    this.stepDelay = const Duration(milliseconds: 550),
    this.usePlatformChannel = false,
  });

  static const MethodChannel _channel =
      MethodChannel('con.supervpn.premium.vpn.proxy/vpn');

  final Duration stepDelay;
  final bool usePlatformChannel;
  final Random _random = Random();

  final _statusController = StreamController<VpnConnectionStatus>.broadcast();
  final _statsController = StreamController<VpnSessionStats>.broadcast();

  VpnConnectionStatus _status = VpnConnectionStatus.disconnected;
  VpnSessionStats _stats = VpnSessionStats.empty;
  VpnServer? _activeServer;
  Timer? _tickTimer;
  int _connectToken = 0;

  @override
  Stream<VpnConnectionStatus> get statusStream => _statusController.stream;

  @override
  Stream<VpnSessionStats> get statsStream => _statsController.stream;

  @override
  VpnConnectionStatus get currentStatus => _status;

  @override
  VpnSessionStats get currentStats => _stats;

  void _emitStatus(VpnConnectionStatus next) {
    _status = next;
    if (!_statusController.isClosed) {
      _statusController.add(next);
    }
  }

  void _emitStats(VpnSessionStats next) {
    _stats = next;
    if (!_statsController.isClosed) {
      _statsController.add(next);
    }
  }

  @override
  Future<void> connect(VpnServer server) async {
    final token = ++_connectToken;
    _tickTimer?.cancel();
    _activeServer = server;
    _emitStats(VpnSessionStats.empty);
    _emitStatus(VpnConnectionStatus.preparing);

    // Attempt native platform call when a host implementation is enabled.
    if (usePlatformChannel) {
      try {
        await _channel.invokeMethod<void>('connect', {'serverId': server.id});
      } on MissingPluginException {
        // Expected when native sing-box plugin is not registered.
      }
    }

    await Future<void>.delayed(stepDelay);
    if (token != _connectToken) return;

    _emitStatus(VpnConnectionStatus.connecting);
    await Future<void>.delayed(stepDelay);
    if (token != _connectToken) return;

    _emitStatus(VpnConnectionStatus.connected);
    _emitStats(
      VpnSessionStats(
        duration: Duration.zero,
        downloadedBytes: 12480,
        uploadedBytes: 4120,
        downloadSpeedBps: 420 * 1024,
        uploadSpeedBps: 115 * 1024,
        latencyMs: server.latencyMs,
      ),
    );

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_status != VpnConnectionStatus.connected) return;
      final dlSpeed = (180 + _random.nextInt(1850)) * 1024;
      final ulSpeed = (45 + _random.nextInt(480)) * 1024;
      final jitter = _random.nextInt(7) - 3;
      final baseLatency = _activeServer?.latencyMs ?? 35;

      _emitStats(
        _stats.copyWith(
          duration: _stats.duration + const Duration(seconds: 1),
          downloadedBytes: _stats.downloadedBytes + dlSpeed,
          uploadedBytes: _stats.uploadedBytes + ulSpeed,
          downloadSpeedBps: dlSpeed,
          uploadSpeedBps: ulSpeed,
          latencyMs: (baseLatency + jitter).clamp(12, 400),
        ),
      );
    });
  }

  @override
  Future<VpnSessionReport?> disconnect({
    String endedBy = 'You or the system',
  }) async {
    _connectToken++;
    _tickTimer?.cancel();
    _tickTimer = null;

    final wasConnected = _status == VpnConnectionStatus.connected;
    final server = _activeServer;
    final finalStats = _stats;

    if (usePlatformChannel) {
      try {
        await _channel.invokeMethod<void>('disconnect');
      } on MissingPluginException {
        // Expected when native sing-box plugin is not registered.
      }
    }

    _emitStatus(VpnConnectionStatus.disconnected);
    _emitStats(VpnSessionStats.empty);

    if (wasConnected && server != null) {
      return VpnSessionReport(
        server: server,
        duration: finalStats.duration,
        downloadedBytes: finalStats.downloadedBytes,
        uploadedBytes: finalStats.uploadedBytes,
        endedBy: endedBy,
        completedAt: DateTime.now(),
        latencyMs: finalStats.latencyMs,
      );
    }
    return null;
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _statusController.close();
    _statsController.close();
  }
}
