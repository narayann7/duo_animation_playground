import 'package:duo_animation/duo_animation.dart';
import 'package:flutter/material.dart';

import '../config/demo_config.dart';
import 'demo_catalog.dart';
import 'demo_host.dart';

/// Screen B: pick a screen to fold. Config is already fixed by this point, so
/// switching between demos changes only the content behind the glass.
class DemoGalleryScreen extends StatelessWidget {
  /// Creates the gallery.
  const DemoGalleryScreen({
    super.key,
    required this.controller,
    required this.config,
  });

  /// The shared controller, handed on to each demo.
  final DuoFoldController controller;

  /// The configuration collected on the config screen.
  final DemoConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Demos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Constraint ${config.constraintOption.label.toLowerCase()}, '
            'blur ${config.parameters.blurSpread.toStringAsFixed(3)}, '
            'darkening ${config.parameters.darkening.toStringAsFixed(4)}'
            '${config.enabled ? '' : ', effect off'}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (final entry in demoCatalog)
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    entry.icon,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(entry.title),
                subtitle: Text(entry.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => DemoHost(
                        controller: controller,
                        config: config,
                        entry: entry,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
