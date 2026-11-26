import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_vpn/data/repositories/preferences_repository.dart';
import 'package:super_vpn/data/repositories/server_repository.dart';
import 'package:super_vpn/data/services/ad_service.dart';
import 'package:super_vpn/data/services/preferences_storage_service.dart';
import 'package:super_vpn/data/services/review_service.dart';
import 'package:super_vpn/data/services/vpn_engine_service.dart';
import 'package:super_vpn/domain/models/app_preferences.dart';
import 'package:super_vpn/domain/models/vpn_connection.dart';
import 'package:super_vpn/main.dart';
import 'package:super_vpn/ui/features/app/app_view_model.dart';

class _DeviceSpec {
  const _DeviceSpec({
    required this.folder,
    required this.widthPx,
    required this.heightPx,
    required this.dpr,
  });

  final String folder;
  final int widthPx;
  final int heightPx;
  final double dpr;

  Size get physicalSize => Size(widthPx.toDouble(), heightPx.toDouble());
}

const _devices = [
  _DeviceSpec(folder: 'iphone_6.1', widthPx: 1179, heightPx: 2556, dpr: 3.0),
  _DeviceSpec(folder: 'ipad_12.9', widthPx: 2048, heightPx: 2732, dpr: 2.0),
  _DeviceSpec(folder: 'iphone_duo', widthPx: 2007, heightPx: 2853, dpr: 3.0),
];

const _runScreenshotGenerator =
    bool.fromEnvironment('GENERATE_SCREENSHOTS');

Future<void> _loadRealFonts() async {
  const flutterFonts =
      '/Users/macbookpro/Development/flutter/bin/cache/artifacts/material_fonts';
  final iconsFile = File('$flutterFonts/MaterialIcons-Regular.otf');
  if (!iconsFile.existsSync()) return;

  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.sublistView(iconsFile.readAsBytesSync()),
      ),
    );
  await materialIcons.load();

  final roboto = FontLoader('Roboto')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File('$flutterFonts/Roboto-Regular.ttf').readAsBytesSync(),
        ),
      ),
    )
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File('$flutterFonts/Roboto-Medium.ttf').readAsBytesSync(),
        ),
      ),
    )
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File('$flutterFonts/Roboto-Bold.ttf').readAsBytesSync(),
        ),
      ),
    );
  await roboto.load();

  final sfFile = File('/System/Library/Fonts/SFNS.ttf');
  if (sfFile.existsSync()) {
    final sfBytes = ByteData.sublistView(sfFile.readAsBytesSync());
    for (final family in [
      '.SF UI Text',
      '.SF UI Display',
      'CupertinoSystemText',
      'CupertinoSystemDisplay',
    ]) {
      final loader = FontLoader(family)..addFont(Future.value(sfBytes));
      await loader.load();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (_runScreenshotGenerator) {
      await _loadRealFonts();
    }
  });

  for (final device in _devices) {
    testWidgets('Generate screenshots for ${device.folder}', (tester) async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': AppThemePreference.dark.index,
        'selected_server_id': 'nl-ams',
        'favorite_server_ids': ['nl-ams', 'de-fra'],
        'show_server_latency': true,
        'haptic_feedback': true,
        'vpn_notifications': true,
        'usage_analytics': true,
        'privacy_consent_completed': true,
        'proxy_all_apps': true,
        'vpn_permission_granted': true,
      });

      tester.view.physicalSize = device.physicalSize;
      tester.view.devicePixelRatio = device.dpr;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final engine = SimulatedVpnEngineService(
        stepDelay: const Duration(milliseconds: 10),
      );
      final vm = AppViewModel(
        preferencesRepository: PreferencesRepository(
          storage: PreferencesStorageService(),
        ),
        serverRepository: ServerRepository(),
        vpnEngine: engine,
        adService: NoopAdService(),
        reviewService: NoopReviewService(),
      );
      await vm.initialize();
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: Size(
              device.widthPx / device.dpr,
              device.heightPx / device.dpr,
            ),
            devicePixelRatio: device.dpr,
            padding: const EdgeInsets.only(top: 44, bottom: 24),
          ),
          child: SuperVpnApp(viewModel: vm),
        ),
      );
      await tester.runAsync(() async {
        final ctx = tester.element(find.byType(SuperVpnApp));
        await precacheImage(const AssetImage('assets/images/logo.png'), ctx);
      });
      await tester.pumpAndSettle();

      // 1. Connect and advance timer so Home shows live connected state + traffic
      unawaited(vm.connect());
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(seconds: 5));
      expect(vm.connectionStatus, VpnConnectionStatus.connected);

      await expectLater(
        find.byType(SuperVpnApp),
        matchesGoldenFile('../screenshots/${device.folder}/01_home_connected.png'),
      );

      // 2. Servers screen
      await tester.tap(find.text('Servers'));
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(SuperVpnApp),
        matchesGoldenFile('../screenshots/${device.folder}/02_servers.png'),
      );

      // 3. Settings screen
      await tester.tap(find.text('Settings'));
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(SuperVpnApp),
        matchesGoldenFile('../screenshots/${device.folder}/03_settings.png'),
      );

      // 4. Disconnect -> Session report screen
      await tester.tap(find.text('Home'));
      await tester.pump(const Duration(milliseconds: 200));
      unawaited(vm.disconnect());
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SuperVpnApp),
        matchesGoldenFile('../screenshots/${device.folder}/04_session_report.png'),
      );
    },
    skip: !_runScreenshotGenerator,
    timeout: const Timeout(Duration(seconds: 60)));
  }
}
