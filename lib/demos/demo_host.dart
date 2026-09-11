import 'package:duo_animation/duo_animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

import '../config/demo_config.dart';
import 'demo_catalog.dart';
import 'tilt_slider.dart';

/// Wraps one demo screen in the fold.
///
/// No chrome at all: no app bar, no back button, no readout. The whole screen
/// is the effect. Leave with the system back gesture.
///
/// Whether the folded subtree gets a background painted behind it is
/// [DemoConfig.paintBackground], and it changes the character of the effect
/// more than any slider does. See that field for the trade.
///
/// The one piece of chrome is the tilt slider, and only when
/// [DemoConfig.enableSlider] is set. It takes the bottom of the screen, so a
/// demo's own controls move to the right edge and turn on their side to make
/// room.
class DemoHost extends StatelessWidget {
  /// Creates a host for [entry].
  const DemoHost({
    super.key,
    required this.controller,
    required this.config,
    required this.entry,
    required this.onChanged,
  });

  /// Supplies tilt and display density.
  final DuoFoldController controller;

  /// The live configuration.
  ///
  /// Listened to rather than read once: this screen is two pushed routes below
  /// the one that owns the config, and a route keeps the page it first built.
  /// The tilt slider edits the config from in here, so a snapshot would leave
  /// the thumb parked wherever it was when the demo opened.
  final ValueListenable<DemoConfig> config;

  /// The demo being shown.
  final DemoEntry entry;

  /// Called with the edited configuration when the tilt slider moves.
  ///
  /// The angle goes back to the app root rather than being held here, which is
  /// what carries it to the config screen and on to disk: come back to a demo
  /// and the fold is where you left it.
  final ValueChanged<DemoConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DemoConfig>(
      valueListenable: config,
      builder: (context, value, _) => _body(context, value),
    );
  }

  /// The host proper, against one reading of the config.
  Widget _body(BuildContext context, DemoConfig config) {
    final colors = context.fossTheme.colors;
    final overlayBuilder = entry.overlayBuilder;
    final sliderDriving = config.enableSlider;
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
            child: _background(
              config,
              colors,
              Builder(builder: entry.builder),
            ),
          ),
          if (overlayBuilder != null)
            SafeArea(
              child: Align(
                alignment: sliderDriving
                    ? Alignment.centerRight
                    : Alignment.bottomCenter,
                child: Padding(
                  padding: sliderDriving
                      ? const EdgeInsets.only(right: 12)
                      : const EdgeInsets.only(bottom: 20),
                  child: Builder(
                    builder: (context) => overlayBuilder(
                      context,
                      axis: sliderDriving ? Axis.vertical : Axis.horizontal,
                      // Only while the slider is driving. A manual tilt set on
                      // the config screen is an angle someone chose, and
                      // changing the picture is no reason to throw it away.
                      onContentChanged: sliderDriving
                          ? () => onChanged(
                              config.copyWith(manualTiltDegrees: 0))
                          : () {},
                    ),
                  ),
                ),
              ),
            ),
          if (sliderDriving)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  // Widened by hand: Align hands its child loose constraints,
                  // and the slider has to know how far the thumb can travel
                  // before it can turn a touch into an angle.
                  child: SizedBox(
                    width: double.infinity,
                    child: TiltSlider(
                      value: config.manualTiltDegrees,
                      onChanged: (degrees) => onChanged(
                        config.copyWith(manualTiltDegrees: degrees),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _background(DemoConfig config, FossColors colors, Widget child) {
    if (!config.paintBackground) {
      return child;
    }
    return Material(color: colors.background, child: child);
  }
}
