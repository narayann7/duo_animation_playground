import 'package:duo_animation/duo_animation.dart';
import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

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
    final colors = context.fossTheme.colors;
    return Scaffold(
      // The Material app bar stays for its back button, dressed in fossui
      // colours by the app theme. fossui ships no app bar of its own.
      appBar: AppBar(title: const Text('Demos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          FossText.caption(
            'Constraint ${config.constraintOption.label.toLowerCase()}, '
            'blur ${config.parameters.blurSpread.toStringAsFixed(3)}, '
            'darkening ${config.parameters.darkening.toStringAsFixed(4)}'
            '${config.enabled ? '' : ', effect off'}',
            color: FossTextColor.mutedForeground,
          ),
          const SizedBox(height: 16),
          for (final entry in demoCatalog)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FossListTile(
                title: Text(entry.title),
                subtitle: Text(entry.subtitle),
                leading: FossAvatar(
                  size: FossAvatarSize.xl,
                  fallback: Icon(entry.icon, color: colors.primary, size: 20),
                ),
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
