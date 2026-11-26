import Flutter
import NetworkExtension
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var supportChannel: FlutterMethodChannel?
  private var vpnChannel: FlutterMethodChannel?
  private let packetTunnelBundleId = "happy.vpn.PacketTunnel"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()

    // Support email channel (used by Send Feedback)
    supportChannel = FlutterMethodChannel(
      name: "happy.vpn/support",
      binaryMessenger: messenger
    )
    supportChannel?.setMethodCallHandler { [weak self] call, result in
      guard call.method == "openMailto",
            let args = call.arguments as? [String: Any],
            let to = args["to"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      let subject = args["subject"] as? String ?? ""
      let body = args["body"] as? String ?? ""
      self?.openMailto(to: to, subject: subject, body: body, result: result)
    }

    // Native iOS NetworkExtension (NETunnelProviderManager) bridge
    vpnChannel = FlutterMethodChannel(
      name: "con.supervpn.premium.vpn.proxy/vpn",
      binaryMessenger: messenger
    )
    vpnChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "connect":
        let args = call.arguments as? [String: Any] ?? [:]
        let serverId = args["serverId"] as? String ?? "auto"
        self?.startPacketTunnel(serverId: serverId, result: result)
      case "disconnect":
        self?.stopPacketTunnel(result: result)
      case "status":
        self?.getTunnelStatus(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func openMailto(
    to: String,
    subject: String,
    body: String,
    result: @escaping FlutterResult
  ) {
    var components = URLComponents()
    components.scheme = "mailto"
    components.path = to
    components.queryItems = [
      URLQueryItem(name: "subject", value: subject),
      URLQueryItem(name: "body", value: body),
    ]
    guard let url = components.url else {
      result(false)
      return
    }
    DispatchQueue.main.async {
      guard UIApplication.shared.canOpenURL(url) else {
        result(false)
        return
      }
      UIApplication.shared.open(url, options: [:]) { success in
        result(success)
      }
    }
  }

  private func startPacketTunnel(serverId: String, result: @escaping FlutterResult) {
    NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
      if let error = error {
        result(
          FlutterError(
            code: "VPN_LOAD_FAILED",
            message: error.localizedDescription,
            details: nil
          )
        )
        return
      }

      guard let self = self else { return }
      let manager = managers?.first ?? NETunnelProviderManager()
      let proto = (manager.protocolConfiguration as? NETunnelProviderProtocol)
        ?? NETunnelProviderProtocol()
      proto.providerBundleIdentifier = self.packetTunnelBundleId
      proto.serverAddress = "HappyVPN+ (\(serverId))"
      proto.providerConfiguration = ["serverId": serverId]

      manager.protocolConfiguration = proto
      manager.localizedDescription = "HappyVPN+"
      manager.isEnabled = true

      manager.saveToPreferences { saveError in
        if let saveError = saveError {
          result(
            FlutterError(
              code: "VPN_SAVE_FAILED",
              message: saveError.localizedDescription,
              details: nil
            )
          )
          return
        }
        manager.loadFromPreferences { reloadError in
          if let reloadError = reloadError {
            result(
              FlutterError(
                code: "VPN_RELOAD_FAILED",
                message: reloadError.localizedDescription,
                details: nil
              )
            )
            return
          }
          do {
            try manager.connection.startVPNTunnel(options: [
              "serverId": serverId as NSString
            ])
            result(true)
          } catch {
            result(
              FlutterError(
                code: "VPN_START_FAILED",
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        }
      }
    }
  }

  private func stopPacketTunnel(result: @escaping FlutterResult) {
    NETunnelProviderManager.loadAllFromPreferences { managers, error in
      if let error = error {
        result(
          FlutterError(
            code: "VPN_STOP_FAILED",
            message: error.localizedDescription,
            details: nil
          )
        )
        return
      }
      managers?.first?.connection.stopVPNTunnel()
      result(true)
    }
  }

  private func getTunnelStatus(result: @escaping FlutterResult) {
    NETunnelProviderManager.loadAllFromPreferences { managers, error in
      if let error = error {
        result(
          FlutterError(
            code: "VPN_STATUS_FAILED",
            message: error.localizedDescription,
            details: nil
          )
        )
        return
      }
      let status = managers?.first?.connection.status ?? .disconnected
      switch status {
      case .connected:
        result("connected")
      case .connecting, .reasserting:
        result("connecting")
      case .disconnecting:
        result("disconnecting")
      default:
        result("disconnected")
      }
    }
  }
}
