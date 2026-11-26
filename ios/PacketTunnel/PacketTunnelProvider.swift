import NetworkExtension

/// Template Packet Tunnel Provider for HappyVPN+ (`happy.vpn.PacketTunnel`).
///
/// Xcode setup required (Organization Apple Developer Account — Guideline 5.4):
/// 1. In Xcode, open `ios/Runner.xcworkspace` -> File -> New -> Target -> Network Extension (Packet Tunnel).
/// 2. Set Product Name: `PacketTunnel`, Bundle Identifier: `happy.vpn.PacketTunnel`, Deployment Target: iOS 15.0.
/// 3. Add the `Network Extensions` (Packet Tunnel) and `App Groups` (`group.happy.vpn`) capabilities
///    to both the `Runner` target and the `PacketTunnel` target.
/// 4. Replace the generated `PacketTunnelProvider.swift` with this file and link your tunnel core
///    (e.g., `Libbox.xcframework` for sing-box VLESS/Hysteria2, or WireGuardKit).
final class PacketTunnelProvider: NEPacketTunnelProvider {
  override func startTunnel(
    options: [String: NSObject]?,
    completionHandler: @escaping (Error?) -> Void
  ) {
    let protoConfig = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration
    let serverId =
      (options?["serverId"] as? String)
      ?? (protoConfig?["serverId"] as? String)
      ?? "nl-ams"

    // Configure the virtual TUN interface settings for iOS.
    let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
    settings.mtu = 1400

    let ipv4 = NEIPv4Settings(addresses: ["172.19.0.1"], subnetMasks: ["255.255.255.252"])
    ipv4.includedRoutes = [NEIPv4Route.default()]
    settings.ipv4Settings = ipv4

    let dns = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
    dns.matchDomains = [""]
    settings.dnsSettings = dns

    setTunnelNetworkSettings(settings) { error in
      if let error = error {
        completionHandler(error)
        return
      }

      // TODO: Start your real VPN tunnel engine here using `serverId` and `self.packetFlow`
      // (for example, initializing sing-box `Libbox` with your server profile).
      _ = serverId
      completionHandler(nil)
    }
  }

  override func stopTunnel(
    with reason: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    // TODO: Stop your VPN tunnel engine cleanly before calling completionHandler().
    completionHandler()
  }
}
