import 'package:flutter/foundation.dart';

enum VpnRegion {
  all('All'),
  favorites('Favorites'),
  europe('Europe'),
  americas('Americas'),
  asiaPacific('Asia Pacific');

  const VpnRegion(this.label);
  final String label;
}

@immutable
class VpnServer {
  const VpnServer({
    required this.id,
    required this.country,
    required this.city,
    required this.countryCode,
    required this.region,
    required this.latencyMs,
    required this.routeCount,
    this.protocol = 'VLESS · Reality',
    this.isAutomatic = false,
  });

  final String id;
  final String country;
  final String city;
  final String countryCode;
  final VpnRegion region;
  final int latencyMs;
  final int routeCount;
  final String protocol;
  final bool isAutomatic;

  static const VpnServer automatic = VpnServer(
    id: 'auto',
    country: 'Automatic server',
    city: 'Best available location',
    countryCode: 'AUTO',
    region: VpnRegion.all,
    latencyMs: 28,
    routeCount: 18,
    protocol: 'Auto · sing-box',
    isAutomatic: true,
  );

  String get displayName => isAutomatic ? country : '$city · $country';

  String get flagEmoji {
    if (isAutomatic || countryCode.length != 2) return '🌐';
    final upper = countryCode.toUpperCase();
    return String.fromCharCodes([
      0x1F1E6 + upper.codeUnitAt(0) - 0x41,
      0x1F1E6 + upper.codeUnitAt(1) - 0x41,
    ]);
  }

  VpnServer copyWith({
    int? latencyMs,
    int? routeCount,
  }) {
    return VpnServer(
      id: id,
      country: country,
      city: city,
      countryCode: countryCode,
      region: region,
      latencyMs: latencyMs ?? this.latencyMs,
      routeCount: routeCount ?? this.routeCount,
      protocol: protocol,
      isAutomatic: isAutomatic,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VpnServer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
