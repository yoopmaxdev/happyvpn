import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/country_flag_badge.dart';
import '../../../core/widgets/latency_badge.dart';
import '../../../../domain/models/vpn_server.dart';
import '../../app/app_view_model.dart';

class ServersView extends StatefulWidget {
  const ServersView({
    super.key,
    required this.viewModel,
    required this.onServerChosen,
  });

  final AppViewModel viewModel;
  final VoidCallback onServerChosen;

  @override
  State<ServersView> createState() => _ServersViewState();
}

class _ServersViewState extends State<ServersView> {
  final TextEditingController _searchController = TextEditingController();
  VpnRegion _selectedRegion = VpnRegion.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VpnServer> _filterServers(
    List<VpnServer> all,
    Set<String> favorites,
  ) {
    return all.where((s) {
      if (_selectedRegion == VpnRegion.favorites) {
        if (!favorites.contains(s.id)) return false;
      } else if (_selectedRegion != VpnRegion.all && s.region != _selectedRegion) {
        return false;
      }

      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return s.country.toLowerCase().contains(q) ||
          s.city.toLowerCase().contains(q) ||
          s.countryCode.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final favorites = vm.preferences.favoriteServerIds;
        final selectedId = vm.preferences.selectedServerId;
        final showLatency = vm.preferences.showServerLatency;
        final filtered = _filterServers(vm.servers, favorites);
        final favoriteServers =
            filtered.where((s) => favorites.contains(s.id)).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Servers'),
            actions: [
              IconButton(
                onPressed: vm.isRefreshingServers ? null : vm.refreshServers,
                tooltip: 'Refresh servers',
                icon: vm.isRefreshingServers
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: vm.refreshServers,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search country or city',
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
                const SizedBox(height: 12),

                // Region Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: VpnRegion.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final region = VpnRegion.values[index];
                      final isSelected = region == _selectedRegion;
                      return ChoiceChip(
                        label: Text(region.label),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedRegion = region),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                if (_query.isEmpty && _selectedRegion == VpnRegion.all) ...[
                  _ServerCardTile(
                    server: VpnServer.automatic,
                    subtitle:
                        'Fastest route · ${vm.activeResolvedServer.city}',
                    isSelected: selectedId == VpnServer.automatic.id,
                    isFavorite: false,
                    showLatency: showLatency,
                    showFavoriteButton: false,
                    onTap: () async {
                      await vm.selectServer(VpnServer.automatic);
                      widget.onServerChosen();
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (vm.serverError != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(vm.serverError!),
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: vm.refreshServers,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          _selectedRegion == VpnRegion.favorites
                              ? Icons.star_outline_rounded
                              : Icons.public_off_rounded,
                          size: 48,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedRegion == VpnRegion.favorites
                              ? 'No favorites yet'
                              : 'No servers found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (_query.isEmpty &&
                      _selectedRegion == VpnRegion.all &&
                      favoriteServers.isNotEmpty) ...[
                    _SectionHeader(title: 'Favorite locations'),
                    const SizedBox(height: 8),
                    ...favoriteServers.map(
                      (server) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ServerCardTile(
                          server: server,
                          isSelected: selectedId == server.id,
                          isFavorite: true,
                          showLatency: showLatency,
                          onTap: () async {
                            await vm.selectServer(server);
                            widget.onServerChosen();
                          },
                          onToggleFavorite: () => vm.toggleFavorite(server.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _SectionHeader(
                    title: _query.isNotEmpty
                        ? 'Search results'
                        : _selectedRegion == VpnRegion.favorites
                            ? 'Favorite locations'
                            : 'Available locations',
                  ),
                  const SizedBox(height: 8),
                  ...filtered.map(
                    (server) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ServerCardTile(
                        server: server,
                        isSelected: selectedId == server.id,
                        isFavorite: favorites.contains(server.id),
                        showLatency: showLatency,
                        onTap: () async {
                          await vm.selectServer(server);
                          widget.onServerChosen();
                        },
                        onToggleFavorite: () => vm.toggleFavorite(server.id),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ServerCardTile extends StatelessWidget {
  const _ServerCardTile({
    required this.server,
    required this.isSelected,
    required this.isFavorite,
    required this.showLatency,
    required this.onTap,
    this.subtitle,
    this.showFavoriteButton = true,
    this.onToggleFavorite,
  });

  final VpnServer server;
  final String? subtitle;
  final bool isSelected;
  final bool isFavorite;
  final bool showLatency;
  final bool showFavoriteButton;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected
              ? colors.primary
              : colors.outlineVariant.withValues(alpha: 0.4),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CountryFlagBadge(
                countryCode: server.countryCode,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.isAutomatic ? server.country : server.city,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle ??
                          '${server.country} · ${Formatters.routes(server.routeCount)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (showLatency) LatencyBadge(latencyMs: server.latencyMs),
              if (showFavoriteButton)
                IconButton(
                  tooltip: isFavorite
                      ? 'Remove ${server.city} from favorites'
                      : 'Add ${server.city} to favorites',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: isFavorite ? Colors.amber : colors.onSurfaceVariant,
                  ),
                ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: colors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
