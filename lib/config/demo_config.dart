import 'package:duo_animation/duo_animation.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/fossui.dart';

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
///
/// Two families and nothing in between, because that is what the two settings
/// they feed actually want. The haze is what the frost fades toward as the
/// blur widens: the darks absorb, which is the package default and what the
/// optics were tuned against, and the pale tints veil, which is how real
/// frosted glass behaves. A saturated accent does neither. It stains the
/// picture, and at the blur widths worth looking at there is nothing left of
/// the photograph to judge.
///
/// Ordered dark to light, so the row reads as a ramp rather than a set.
enum DemoTint {
  black('Black', Color(0xFF000000)),
  charcoal('Charcoal', Color(0xFF1C1C1E)),
  graphite('Graphite', Color(0xFF3A3A3C)),
  surface('Surface', null),
  white('White', Color(0xFFFFFFFF)),
  ivory('Ivory', Color(0xFFFAF6EC)),
  sand('Sand', Color(0xFFEDE0CB)),
  blush('Blush', Color(0xFFF6DCE0)),
  mist('Mist', Color(0xFFDBE6F3)),
  sage('Sage', Color(0xFFDCE8DA)),
  lilac('Lilac', Color(0xFFE5DEF2));

  const DemoTint(this.label, this._color);

  /// Name shown beside the swatch row.
  final String label;

  final Color? _color;

  /// The colour to hand the fold, resolved against [colors] for [surface].
  Color resolve(FossColors colors) => _color ?? colors.background;
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
  /// Defaults match the package apart from the tilt response, which starts at 2
  /// here. The playground gets run on tablets, where a linear response spends
  /// most of the fold in the first few degrees because the hinge sits so far
  /// from the opposite edge.
  const DemoConfig({
    this.constraintOption = DemoConstraintOption.horizontal,
    this.parameters = const DuoFoldParameters(tiltResponse: 2),
    this.enabled = true,
    this.autoRecenter = true,
    this.useSensor = true,
    this.manualTiltDegrees = 0,
    this.enableSlider = false,
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

  /// True puts a tilt slider on top of every demo and takes the sensors out of
  /// the loop.
  ///
  /// The two cannot both drive the fold, so this wins: the host forces the
  /// controller onto manual tilt while it is set, and [useSensor] keeps
  /// whatever it was so turning the slider back off restores the choice rather
  /// than a default.
  final bool enableSlider;

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
    bool? enableSlider,
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
      enableSlider: enableSlider ?? this.enableSlider,
      darkMode: darkMode ?? this.darkMode,
      paintBackground: paintBackground ?? this.paintBackground,
      hazeTint: hazeTint ?? this.hazeTint,
      surroundTint: surroundTint ?? this.surroundTint,
    );
  }

  /// Reads a config back out of [json], falling back to the default for any
  /// field that is missing or the wrong shape.
  ///
  /// Tolerant on purpose: the file this comes from was written by an older
  /// build of the playground, and a knob that has since been renamed should
  /// cost you that one knob rather than the whole saved setup.
  factory DemoConfig.fromJson(Map<String, Object?> json) {
    const defaults = DemoConfig();
    final parameters = json['parameters'];
    final parameterJson = parameters is Map<String, Object?>
        ? parameters
        : const <String, Object?>{};
    final defaultParameters = defaults.parameters;
    return DemoConfig(
      constraintOption: _enumFrom(
        DemoConstraintOption.values,
        json['constraintOption'],
        defaults.constraintOption,
      ),
      // Only the values the config screen exposes. The two colours on
      // DuoFoldParameters are not among them: the host overwrites both from
      // the tints every build, so writing them down would be recording an
      // answer that is computed anyway.
      parameters: DuoFoldParameters(
        eyeDistanceMillimeters: _doubleFrom(
          parameterJson,
          'eyeDistanceMillimeters',
          defaultParameters.eyeDistanceMillimeters,
        ),
        pixelsPerMillimeter: _doubleFrom(
          parameterJson,
          'pixelsPerMillimeter',
          defaultParameters.pixelsPerMillimeter,
        ),
        blurSpread: _doubleFrom(
          parameterJson,
          'blurSpread',
          defaultParameters.blurSpread,
        ),
        darkening: _doubleFrom(
          parameterJson,
          'darkening',
          defaultParameters.darkening,
        ),
        baseBlurMillimeters: _doubleFrom(
          parameterJson,
          'baseBlurMillimeters',
          defaultParameters.baseBlurMillimeters,
        ),
        stretchEdges: _boolFrom(
          parameterJson,
          'stretchEdges',
          defaultParameters.stretchEdges,
        ),
        tiltResponse: _doubleFrom(
          parameterJson,
          'tiltResponse',
          defaultParameters.tiltResponse,
        ),
      ),
      enabled: _boolFrom(json, 'enabled', defaults.enabled),
      autoRecenter: _boolFrom(json, 'autoRecenter', defaults.autoRecenter),
      useSensor: _boolFrom(json, 'useSensor', defaults.useSensor),
      manualTiltDegrees: _doubleFrom(
        json,
        'manualTiltDegrees',
        defaults.manualTiltDegrees,
      ),
      enableSlider: _boolFrom(json, 'enableSlider', defaults.enableSlider),
      darkMode: _boolFrom(json, 'darkMode', defaults.darkMode),
      paintBackground:
          _boolFrom(json, 'paintBackground', defaults.paintBackground),
      hazeTint: _enumFrom(DemoTint.values, json['hazeTint'], defaults.hazeTint),
      surroundTint: _enumFrom(
        DemoTint.values,
        json['surroundTint'],
        defaults.surroundTint,
      ),
    );
  }

  /// The config as plain JSON types, ready for the store.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'constraintOption': constraintOption.name,
      'parameters': <String, Object?>{
        'eyeDistanceMillimeters': parameters.eyeDistanceMillimeters,
        'pixelsPerMillimeter': parameters.pixelsPerMillimeter,
        'blurSpread': parameters.blurSpread,
        'darkening': parameters.darkening,
        'baseBlurMillimeters': parameters.baseBlurMillimeters,
        'stretchEdges': parameters.stretchEdges,
        'tiltResponse': parameters.tiltResponse,
      },
      'enabled': enabled,
      'autoRecenter': autoRecenter,
      'useSensor': useSensor,
      'manualTiltDegrees': manualTiltDegrees,
      'enableSlider': enableSlider,
      'darkMode': darkMode,
      'paintBackground': paintBackground,
      'hazeTint': hazeTint.name,
      'surroundTint': surroundTint.name,
    };
  }
}

/// The number at [key], or [fallback] when there is not one there.
double _doubleFrom(Map<String, Object?> json, String key, double fallback) {
  final value = json[key];
  return value is num ? value.toDouble() : fallback;
}

/// The flag at [key], or [fallback] when there is not one there.
bool _boolFrom(Map<String, Object?> json, String key, bool fallback) {
  final value = json[key];
  return value is bool ? value : fallback;
}

/// The member of [values] named [name], or [fallback] when no member is.
T _enumFrom<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}
