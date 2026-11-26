import 'package:flutter/material.dart';

class LicensesView extends StatelessWidget {
  const LicensesView({super.key});

  static const _components = [
    (
      name: 'sing-box (libbox)',
      license: 'GNU General Public License v3.0',
      description: 'Universal proxy platform and core tunnel engine.',
    ),
    (
      name: 'ByeDPI',
      license: 'MIT License',
      description: 'DPI circumvention transport layer.',
    ),
    (
      name: 'hev-socks5-tunnel',
      license: 'MIT License',
      description: 'Lightweight TUN-to-SOCKS5 packet tunnel.',
    ),
    (
      name: 'sing-geoip & sing-geosite',
      license: 'CC-BY-SA / GPL-3.0',
      description: 'Regional IP and domain routing rule databases.',
    ),
    (
      name: 'Go Standard Library & Runtime',
      license: 'BSD-3-Clause License',
      description: 'Native engine runtime and networking packages.',
    ),
    (
      name: 'Flutter & Dart SDK',
      license: 'BSD-3-Clause License',
      description: 'Cross-platform UI framework and runtime.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Open-source licenses')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _components.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _components.length) {
            return OutlinedButton.icon(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'HappyVPN+ (Хэппи ВПН)',
                applicationVersion: '1.0.11',
              ),
              icon: const Icon(Icons.article_outlined),
              label: const Text('View Flutter package licenses'),
            );
          }

          final item = _components[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.license,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
