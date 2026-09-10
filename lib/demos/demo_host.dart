import 'package:duo_animation/duo_animation.dart';
import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

import '../config/demo_config.dart';
import 'demo_catalog.dart';

/// Wraps one demo screen in the fold.
///
/// No chrome at all: no app bar, no back button, no readout. The whole screen
/// is the effect. Leave with the system back gesture.
///
/// Whether the folded subtree gets a background painted behind it is
/// [DemoConfig.paintBackground], and it changes the character of the effect
/// more than any slider does. See that field for the trade.
class DemoHost extends StatelessWidget {
  /// Creates a host for [entry].
  const DemoHost({
    super.key,
    required this.controller,
    required this.config,
    required this.entry,
  });

  /// Supplies tilt and display density.
  final DuoFoldController controller;

  /// The configuration collected on the config screen.
  final DemoConfig config;

  /// The demo being shown.
  final DemoEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.fossTheme.colors;
    return Scaffold(
      // StackFit.expand is load-bearing: a Stack sizes itself to its largest
      // non-positioned child, and the overlay would otherwise decide how much
      // room the fold gets.
      body: Stack(
        fit: StackFit.expand,
        children: [
          DuoFoldMotion(
            controller: controller,
            parameters: config.parameters.copyWith(
              surroundColor: config.surroundTint.resolve(colors),
              hazeColor: config.hazeTint.resolve(colors),
            ),
            enabled: config.enabled,
            child: _background(colors, Builder(builder: entry.builder)),
          ),
          if (entry.overlayBuilder != null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Builder(builder: entry.overlayBuilder!),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _background(FossColors colors, Widget child) {
    if (!config.paintBackground) {
      return child;
    }
    return Material(color: colors.background, child: child);
  }
}
