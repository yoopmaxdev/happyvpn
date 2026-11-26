import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_vpn/data/repositories/preferences_repository.dart';
import 'package:super_vpn/data/repositories/server_repository.dart';
import 'package:super_vpn/data/services/ad_service.dart';
import 'package:super_vpn/data/services/preferences_storage_service.dart';
import 'package:super_vpn/data/services/review_service.dart';
import 'package:super_vpn/data/services/vpn_engine_service.dart';
import 'package:super_vpn/domain/models/vpn_connection.dart';
import 'package:super_vpn/main.dart';
import 'package:super_vpn/ui/features/app/app_view_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppViewModel> createViewModel() async {
    final vm = AppViewModel(
      preferencesRepository: PreferencesRepository(
        storage: PreferencesStorageService(),
      ),
      serverRepository: ServerRepository(),
      vpnEngine: SimulatedVpnEngineService(
        stepDelay: const Duration(milliseconds: 20),
      ),
    );
    await vm.initialize();
    return vm;
  }

  testWidgets('Full Super VPN flow: consent -> servers -> connect -> report',
      (WidgetTester tester) async {
    final vm = await createViewModel();
    addTearDown(vm.dispose);

    await tester.pumpWidget(SuperVpnApp(viewModel: vm));
    await tester.pump();

    // 1. Privacy consent screen appears on first launch
    expect(find.text('Your privacy'), findsOneWidget);
    await tester.tap(find.text('Agree and continue'));
    await tester.pumpAndSettle();

    // 2. Home screen appears with HappyVPN+ branding & Connect button
    expect(find.text('HappyVPN+'), findsOneWidget);
    expect(find.text('Хэппи ВПН'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);

    // 3. Navigate to Servers tab, favorite Amsterdam, filter Asia Pacific, and select Tokyo
    await tester.tap(find.text('Servers'));
    await tester.pumpAndSettle();
    expect(find.text('Amsterdam'), findsOneWidget);

    await tester.tap(find.byTooltip('Add Amsterdam to favorites'));
    await tester.pumpAndSettle();
    expect(vm.preferences.favoriteServerIds, contains('nl-ams'));

    await tester.tap(find.text('Asia Pacific'));
    await tester.pumpAndSettle();
    expect(find.text('Tokyo'), findsOneWidget);

    await tester.tap(find.text('Tokyo'));
    await tester.pumpAndSettle();
    expect(vm.selectedServer.city, 'Tokyo');

    // 4. Connect from Home -> grant permissions -> connected
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.text('Connection permissions'), findsOneWidget);

    await tester.tap(find.text('Allow VPN & notifications'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(vm.preferences.vpnPermissionGranted, isTrue);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(vm.connectionStatus, VpnConnectionStatus.connected);

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Disconnect'), findsOneWidget);

    // 5. Disconnect -> confirm dialog -> Session report
    await tester.tap(find.text('Disconnect'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Disconnect from Tokyo?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Disconnect'));
    await tester.pumpAndSettle();
    expect(find.text('Session report'), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);

    await tester.ensureVisible(find.text('Back to home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();

    // 6. Navigate to Settings and verify sub-screens
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('App routing'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Version 2.0.0'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Version 2.0.0'), findsOneWidget);
  });

  test('YandexAdConfig and ReviewService store configured IDs', () {
    expect(YandexAdConfig.appId, '20506101');
    expect(YandexAdConfig.bannerAdUnitId, 'R-M-20506101-1');
    expect(YandexAdConfig.interstitialAdUnitId, 'R-M-20506101-2');
    expect(YandexAdConfig.rewardedAdUnitId, 'R-M-20506101-3');
    expect(YandexAdConfig.nativeAdUnitId, 'R-M-20506101-4');
    expect(YandexAdConfig.appOpenAdUnitId, 'R-M-20506101-5');
    expect(YandexAdConfig.feedAdUnitId, 'R-M-20506101-6');
    expect(ReviewService.iosAppStoreId, '6839425968');
  });

  testWidgets(
    'iOS hides Android App routing and uses iOS VPN copy',
    (WidgetTester tester) async {
      final vm = await createViewModel();
      addTearDown(vm.dispose);

      await tester.pumpWidget(SuperVpnApp(viewModel: vm));
      await tester.pump();

      await tester.tap(find.text('Agree and continue'));
      await tester.pumpAndSettle();

      // Permissions sheet uses iOS wording (not Android)
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();
      expect(find.textContaining('iOS needs your approval'), findsOneWidget);
      expect(find.textContaining('Android'), findsNothing);

      await tester.tap(find.text('Continue without notifications'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Settings hides Android-only App routing on iOS
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('App routing'), findsNothing);
      expect(
        vm.buildDiagnosticsPreview(),
        contains('Routing: All device traffic'),
      );

      await vm.disconnect();
      await tester.pump();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
