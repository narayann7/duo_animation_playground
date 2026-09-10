import 'package:duo_animation/duo_animation.dart';
import 'package:flutter/material.dart';

/// The constraint presets the config screen can pick between.
enum DemoConstraintOption {
  free('Free'),
  horizontal('Horizontal'),
  vertical('Vertical'),
  leftOnly('Left only'),
  rightOnly('Right only'),
  topOnly('Top only'),
  bottomOnly('Bottom only');

  const DemoConstraintOption(this.label);

  /// Text shown on the chip.
  final String label;

  /// The value handed to [DuoFoldController.constraints].
  DuoFoldConstraints get constraints {
    switch (this) {
      case DemoConstraintOption.free:
        return const DuoFoldConstraints.free();
      case DemoConstraintOption.horizontal:
        return const DuoFoldConstraints.horizontal();
      case DemoConstraintOption.vertical:
        return const DuoFoldConstraints.vertical();
      case DemoConstraintOption.leftOnly:
        return const DuoFoldConstraints.only(DuoFoldHinge.left);
      case DemoConstraintOption.rightOnly:
        return const DuoFoldConstraints.only(DuoFoldHinge.right);
      case DemoConstraintOption.topOnly:
        return const DuoFoldConstraints.only(DuoFoldHinge.top);
      case DemoConstraintOption.bottomOnly:
        return const DuoFoldConstraints.only(DuoFoldHinge.bottom);
    }
  }
}

/// The colour choices offered for the haze and the surround.
///
/// [surface] follows the active theme. The rest are fixed so a tint can be
/// judged against both themes without moving under you.
enum DemoTint {
  black('Black', Color(0xFF000000)),
  surface('Surface', null),
  white('White', Color(0xFFFFFFFF)),
  indigo('Indigo', Color(0xFF4F46E5)),
  teal('Teal', Color(0xFF0D9488)),
  amber('Amber', Color(0xFFF59E0B)),
  rose('Rose', Color(0xFFE11D48));

  const DemoTint(this.label, this._color);

  /// Name shown beside the swatch row.
  final String label;

  final Color? _color;

  /// The colour to hand the fold, resolved against [scheme] for [surface].
  Color resolve(ColorScheme scheme) => _color ?? scheme.surface;
}

/// Everything the config screen collects, in one immutable value.
///
/// The demo screens never read this directly: the app root applies the motion
/// half of it to the controller and passes the optical half to the fold widget,
/// so a demo stays a plain widget tree with no knowledge of the effect.
@immutable
class DemoConfig {
  /// Creates a config.
  ///
  /// Defaults match the package apart from the base blur, which the demo starts
  /// at 0.6 mm so the frost is visible across the whole screen from the first
  /// tilt rather than only at the lifted edge.
  const DemoConfig({
    this.constraintOption = DemoConstraintOption.horizontal,
    this.parameters = const DuoFoldParameters(baseBlurMillimeters: 0.6),
    this.enabled = true,
    this.autoRecenter = true,
    this.useSensor = true,
    this.manualTiltDegrees = 0,
    this.darkMode = false,
    this.paintBackground = true,
    this.hazeTint = DemoTint.black,
    this.surroundTint = DemoTint.surface,
  });

  /// Which fold directions the demos respond to.
  final DemoConstraintOption constraintOption;

  /// Optical tuning passed straight to the fold widget.
  final DuoFoldParameters parameters;

  /// False bypasses the effect, which is the way to compare against plain
  /// content without leaving the demo.
  final bool enabled;

  /// Whether the slow drift washout runs.
  final bool autoRecenter;

  /// False drives tilt from [manualTiltDegrees] instead of the sensors.
  final bool useSensor;

  /// Hand-driven tilt, used on hardware with no rotation sensor.
  final double manualTiltDegrees;

  /// Dark theme for the demo screens and the config screen alike.
  final bool darkMode;

  /// Whether the folded content gets an opaque background painted behind it.
  ///
  /// This is the single biggest switch in the demo. On, the content sits on the
  /// theme's surface and reads like an ordinary app: the fold then shows on
  /// type, icons and photographs, and flat areas barely move, because a blurred
  /// flat colour is the same flat colour. Off, the content is transparent, the
  /// shader reads every untouched pixel as empty and writes the surround colour
  /// there, so the whole screen darkens under tilt and the frost reads
  /// everywhere at the cost of the background going with it.
  final bool paintBackground;

  /// What the frost fades toward as the blur widens. Black is pure absorption,
  /// which is the package default and what the effect was tuned against.
  final DemoTint hazeTint;

  /// What fills the pixels where the tilted glass looks past the edge of the
  /// content. Black leaves that region as a void, which is how it reads with
  /// nothing painted behind the content.
  final DemoTint surroundTint;

  /// Returns a copy with the given fields replaced.
  DemoConfig copyWith({
    DemoConstraintOption? constraintOption,
    DuoFoldParameters? parameters,
    bool? enabled,
    bool? autoRecenter,
    bool? useSensor,
    double? manualTiltDegrees,
    bool? darkMode,
    bool? paintBackground,
    DemoTint? hazeTint,
    DemoTint? surroundTint,
  }) {
    return DemoConfig(
      constraintOption: constraintOption ?? this.constraintOption,
      parameters: parameters ?? this.parameters,
      enabled: enabled ?? this.enabled,
      autoRecenter: autoRecenter ?? this.autoRecenter,
      useSensor: useSensor ?? this.useSensor,
      manualTiltDegrees: manualTiltDegrees ?? this.manualTiltDegrees,
      darkMode: darkMode ?? this.darkMode,
      paintBackground: paintBackground ?? this.paintBackground,
      hazeTint: hazeTint ?? this.hazeTint,
      surroundTint: surroundTint ?? this.surroundTint,
    );
  }
}
