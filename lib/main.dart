import 'package:flutter/material.dart';

import 'data/repositories/preferences_repository.dart';
import 'data/repositories/server_repository.dart';
import 'data/services/ad_service.dart';
import 'data/services/preferences_storage_service.dart';
import 'data/services/review_service.dart';
import 'data/services/vpn_engine_service.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/features/app/app_view_model.dart';
import 'ui/features/app/views/main_shell_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final viewModel = AppViewModel(
    preferencesRepository: PreferencesRepository(
      storage: PreferencesStorageService(),
    ),
    serverRepository: ServerRepository(),
    vpnEngine: SimulatedVpnEngineService(),
    adService: YandexAdService(),
    reviewService: StoreReviewService(),
  )..initialize();

  runApp(SuperVpnApp(viewModel: viewModel));
}

class SuperVpnApp extends StatelessWidget {
  const SuperVpnApp({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return MaterialApp(
          title: AppViewModel.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: viewModel.preferences.themePreference.themeMode,
          home: MainShellView(viewModel: viewModel),
        );
      },
    );
  }
}
