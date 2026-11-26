import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/widgets/yandex_banner_slot.dart';
import '../../feedback/views/feedback_view.dart';
import '../../home/views/home_view.dart';
import '../../licenses/views/licenses_view.dart';
import '../../privacy/views/privacy_consent_view.dart';
import '../../routing/views/app_routing_view.dart';
import '../../servers/views/servers_view.dart';
import '../../settings/views/settings_view.dart';
import '../app_view_model.dart';

class MainShellView extends StatefulWidget {
  const MainShellView({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.viewModel.onAppResumed());
    }
  }

  void _openAppRouting() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppRoutingView(viewModel: widget.viewModel),
      ),
    );
  }

  void _openFeedback() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeedbackView(viewModel: widget.viewModel),
      ),
    );
  }

  void _openLicenses() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LicensesView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (!widget.viewModel.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!widget.viewModel.preferences.privacyConsentCompleted) {
          return PrivacyConsentView(viewModel: widget.viewModel);
        }

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              HomeView(
                viewModel: widget.viewModel,
                onOpenServers: () => setState(() => _selectedIndex = 1),
                onOpenFeedback: _openFeedback,
              ),
              ServersView(
                viewModel: widget.viewModel,
                onServerChosen: () => setState(() => _selectedIndex = 0),
              ),
              SettingsView(
                viewModel: widget.viewModel,
                onOpenAppRouting: _openAppRouting,
                onOpenFeedback: _openFeedback,
                onOpenLicenses: _openLicenses,
              ),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              YandexBannerSlot(adService: widget.viewModel.adService),
              NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.shield_outlined),
                    selectedIcon: Icon(Icons.shield_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.public_outlined),
                    selectedIcon: Icon(Icons.public_rounded),
                    label: 'Servers',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
