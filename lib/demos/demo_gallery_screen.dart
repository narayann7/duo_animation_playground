import 'package:duo_animation/duo_animation.dart';
import 'package:flutter/foundation.dart';
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
    required this.onChanged,
  });

  /// The shared controller, handed on to each demo.
  final DuoFoldController controller;

  /// The live configuration, passed on to whichever demo is opened.
  final ValueListenable<DemoConfig> config;

  /// Called with the edited configuration when a demo's tilt slider moves.
  final ValueChanged<DemoConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DemoConfig>(
      valueListenable: config,
      builder: (context, value, _) => _body(context, value),
    );
  }

  /// The gallery proper, against one reading of the config.
  Widget _body(BuildContext context, DemoConfig config) {
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
            if (entry.fitsOn(MediaQuery.sizeOf(context).shortestSide))
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
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      // this.config, not the local reading of it: the demo
                      // has to follow the config, not be handed a photograph
                      // of it taken when you tapped the row.
                      builder: (context) => DemoHost(
                        controller: controller,
                        config: this.config,
                        entry: entry,
                        onChanged: onChanged,
                      ),
                    ),
                  );
                  // Coming back out of a demo puts the fold flat again. The
                  // slider was chrome on the screen you just closed, and the
                  // angle it was holding has nothing left to hold it up.
                  //
                  // Only what the slider set: with it off, a manual tilt is an
                  // angle chosen on the config screen, and opening a demo and
                  // closing it again is no reason to lose it.
                  final config = this.config.value;
                  if (config.enableSlider && config.manualTiltDegrees != 0) {
                    onChanged(config.copyWith(manualTiltDegrees: 0));
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
