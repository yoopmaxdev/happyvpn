import 'package:flutter/material.dart';
import '../../app/app_view_model.dart';

class AppRoutingView extends StatefulWidget {
  const AppRoutingView({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<AppRoutingView> createState() => _AppRoutingViewState();
}

class _AppRoutingViewState extends State<AppRoutingView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final prefs = vm.preferences;
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        final apps = vm.installedApps.where((app) {
          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          return app.name.toLowerCase().contains(q) ||
              app.packageName.toLowerCase().contains(q);
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('App routing')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Proxy all apps',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Choose which apps use the VPN. Changes apply when you reconnect.',
                  ),
                  value: prefs.proxyAllApps,
                  onChanged: vm.setProxyAllApps,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'RU sites/IPs and recognized torrents bypass the VPN and can see your normal IP. If no apps are selected, default routing applies.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search apps',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (int i = 0; i < apps.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 16),
                      CheckboxListTile(
                        title: Text(apps[i].name),
                        subtitle: Text(
                          apps[i].alwaysDirect
                              ? 'Always uses direct connection'
                              : apps[i].packageName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        value: apps[i].alwaysDirect
                            ? false
                            : prefs.proxyAllApps
                                ? true
                                : prefs.proxiedAppIds.contains(apps[i].id),
                        onChanged: apps[i].alwaysDirect || prefs.proxyAllApps
                            ? null
                            : (_) => vm.toggleAppProxied(apps[i].id),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
