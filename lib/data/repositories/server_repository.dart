import 'dart:math';

import '../../domain/models/routed_app.dart';
import '../../domain/models/vpn_server.dart';

class ServerRepository {
  final Random _random = Random();

  /// Exact locations bundled in Super VPN (v1.0.11).
  List<VpnServer> _servers = const [
    VpnServer(
      id: 'nl-ams',
      country: 'Netherlands',
      city: 'Amsterdam',
      countryCode: 'NL',
      region: VpnRegion.europe,
      latencyMs: 28,
      routeCount: 4,
      protocol: 'VLESS · Reality',
    ),
    VpnServer(
      id: 'de-fra',
      country: 'Germany',
      city: 'Frankfurt',
      countryCode: 'DE',
      region: VpnRegion.europe,
      latencyMs: 32,
      routeCount: 3,
      protocol: 'VLESS · Reality',
    ),
    VpnServer(
      id: 'fi-hel',
      country: 'Finland',
      city: 'Helsinki',
      countryCode: 'FI',
      region: VpnRegion.europe,
      latencyMs: 39,
      routeCount: 3,
      protocol: 'VLESS · ByeDPI',
    ),
    VpnServer(
      id: 'gb-lon',
      country: 'United Kingdom',
      city: 'London',
      countryCode: 'GB',
      region: VpnRegion.europe,
      latencyMs: 44,
      routeCount: 2,
      protocol: 'VLESS · Reality',
    ),
    VpnServer(
      id: 'us-lax',
      country: 'United States',
      city: 'Los Angeles',
      countryCode: 'US',
      region: VpnRegion.americas,
      latencyMs: 138,
      routeCount: 3,
      protocol: 'Hysteria2',
    ),
    VpnServer(
      id: 'sg-sin',
      country: 'Singapore',
      city: 'Singapore',
      countryCode: 'SG',
      region: VpnRegion.asiaPacific,
      latencyMs: 162,
      routeCount: 2,
      protocol: 'VLESS · Reality',
    ),
    VpnServer(
      id: 'jp-tyo',
      country: 'Japan',
      city: 'Tokyo',
      countryCode: 'JP',
      region: VpnRegion.asiaPacific,
      latencyMs: 184,
      routeCount: 1,
      protocol: 'Hysteria2',
    ),
  ];

  List<VpnServer> getServers() => List.unmodifiable(_servers);

  VpnServer resolveServer(String serverId) {
    if (serverId == VpnServer.automatic.id) {
      return VpnServer.automatic;
    }
    return _servers.firstWhere(
      (s) => s.id == serverId,
      orElse: () => VpnServer.automatic,
    );
  }

  VpnServer getBestServer() {
    final sorted = [..._servers]..sort((a, b) => a.latencyMs.compareTo(b.latencyMs));
    return sorted.first;
  }

  Future<List<VpnServer>> refreshServers() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _servers = _servers
        .map(
          (s) => s.copyWith(
            latencyMs: (s.latencyMs + _random.nextInt(11) - 5).clamp(15, 290),
          ),
        )
        .toList();
    return getServers();
  }

  List<RoutedApp> getInstalledApps() => const [
        RoutedApp(
          id: 'com.android.chrome',
          name: 'Chrome',
          packageName: 'com.android.chrome',
          category: 'Browser',
        ),
        RoutedApp(
          id: 'org.telegram.messenger',
          name: 'Telegram',
          packageName: 'org.telegram.messenger',
          category: 'Messaging',
        ),
        RoutedApp(
          id: 'com.google.android.youtube',
          name: 'YouTube',
          packageName: 'com.google.android.youtube',
          category: 'Media',
        ),
        RoutedApp(
          id: 'com.instagram.android',
          name: 'Instagram',
          packageName: 'com.instagram.android',
          category: 'Social',
        ),
        RoutedApp(
          id: 'com.whatsapp',
          name: 'WhatsApp',
          packageName: 'com.whatsapp',
          category: 'Messaging',
        ),
        RoutedApp(
          id: 'com.spotify.music',
          name: 'Spotify',
          packageName: 'com.spotify.music',
          category: 'Music',
        ),
        RoutedApp(
          id: 'com.discord',
          name: 'Discord',
          packageName: 'com.discord',
          category: 'Social',
        ),
        RoutedApp(
          id: 'com.twitter.android',
          name: 'X',
          packageName: 'com.twitter.android',
          category: 'Social',
        ),
        RoutedApp(
          id: 'happy.vpn',
          name: 'HappyVPN+',
          packageName: 'happy.vpn',
          category: 'System',
          alwaysDirect: true,
        ),
      ];
}
