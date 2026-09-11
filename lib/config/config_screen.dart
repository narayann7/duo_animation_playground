import 'package:duo_animation/duo_animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

import '../demos/demo_gallery_screen.dart';
import '../tilt_readout.dart';
import 'demo_config.dart';

/// Title of the row that turns the on-screen tilt slider on.
///
/// Named rather than inlined because it is the switch's semantic label too, so
/// it is how a screen reader and a test both find the row.
const String sliderSwitchTitle = 'Tilt slider in the demos';

/// Title of the row that hands tilt to the rotation sensors.
const String sensorSwitchTitle = 'Drive from sensors';

/// The screen the app opens on: every knob in one place, then a button through
/// to the demo gallery.
///
/// The readout at the top runs off the live controller, so sensor trouble shows
/// up here rather than being mistaken for a broken shader once a demo is open.
class ConfigScreen extends StatelessWidget {
  /// Creates the config screen.
  const ConfigScreen({
    super.key,
    required this.controller,
    required this.config,
    required this.onChanged,
  });

  /// The single controller shared by the whole app.
  final DuoFoldController controller;

  /// The live configuration.
  ///
  /// A listenable rather than a value because of what this screen pushes. A
  /// route builds its page once and keeps it: the closure below captures
  /// whatever is handed to it at the moment you open a demo, and an open demo
  /// that edits the config, which is what the tilt slider does, would be
  /// reading its own stale copy forever.
  final ValueListenable<DemoConfig> config;

  /// Called with the edited configuration.
  final ValueChanged<DemoConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DemoConfig>(
      valueListenable: config,
      builder: (context, value, _) => _body(context, value),
    );
  }

  /// The screen proper, against one reading of the config.
  Widget _body(BuildContext context, DemoConfig config) {
    final parameters = config.parameters;
    return Scaffold(
      // No app bar. This screen is the root, so there is nothing to go back to,
      // and a heading in the list keeps the whole surface on fossui tokens.
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const FossText.heading('Fold configuration'),
            const SizedBox(height: 16),
            FossCard(content: TiltReadout(controller: controller)),
            const SizedBox(height: 24),
            const _SectionLabel('Hinge constraint'),
            const _SectionHelp(
              'Which fold directions the effect responds to. A constrained '
              'fold keeps only the pose along the chosen axis, so it falls off '
              'as the device rotates off that axis rather than snapping.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in DemoConstraintOption.values)
                  FossChip(
                    label: Text(option.label),
                    selected: config.constraintOption == option,
                    onSelected: (_) =>
                        onChanged(config.copyWith(constraintOption: option)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Optics'),
            const SizedBox(height: 12),
            _ParameterSlider(
              label: 'Blur spread',
              value: parameters.blurSpread,
              min: 0,
              max: 0.4,
              fractionDigits: 3,
              help: 'Blur radius gained per pixel of separation between the '
                  'glass and the content plane.',
              onChanged: (value) => onChanged(
                config.copyWith(
                  parameters: parameters.copyWith(blurSpread: value),
                ),
              ),
            ),
            _ParameterSlider(
              label: 'Base blur',
              value: parameters.baseBlurMillimeters,
              min: 0,
              max: 3,
              fractionDigits: 2,
              unit: ' mm',
              help: 'Frost carried across the whole screen once the fold '
                  'leaves rest. Zero leaves the hinge side sharp, which is '
                  'what the optics alone give.',
              onChanged: (value) => onChanged(
                config.copyWith(
                  parameters: parameters.copyWith(baseBlurMillimeters: value),
                ),
              ),
            ),
            _ParameterSlider(
              label: 'Darkening',
              value: parameters.darkening,
              min: 0,
              max: 0.06,
              fractionDigits: 4,
              help: 'Light lost per pixel of blur radius. Frostier glass reads '
                  'darker.',
              onChanged: (value) => onChanged(
                config.copyWith(
                  parameters: parameters.copyWith(darkening: value),
                ),
              ),
            ),
            _ParameterSlider(
              label: 'Tilt response',
              value: parameters.tiltResponse,
              min: 1,
              max: 4,
              fractionDigits: 2,
              help: 'How tilt maps onto the fold. One is linear. Higher holds '
                  'the small tilts back and leaves the widest tilt where it '
                  'is, which is what a large screen usually wants.',
              onChanged: (value) => onChanged(
                config.copyWith(
                  parameters: parameters.copyWith(tiltResponse: value),
                ),
              ),
            ),
            _ParameterSlider(
              label: 'Eye distance',
              value: parameters.eyeDistanceMillimeters,
              min: 200,
              max: 800,
              fractionDigits: 0,
              unit: ' mm',
              help: 'Distance from the viewer to the untilted screen. Larger '
                  'values flatten the perspective and crop less at wide tilts.',
              onChanged: (value) => onChanged(
                config.copyWith(
                  parameters: parameters.copyWith(
                    eyeDistanceMillimeters: value,
                  ),
                ),
              ),
            ),
            _ParameterSlider(
              label: 'Pixel density override',
              value: parameters.pixelsPerMillimeter,
              min: 0,
              max: 16,
              fractionDigits: 1,
              unit: ' px/mm',
              zeroLabel: 'auto',
              help: 'Zero resolves the density from the display metrics, which '
                  'is the right answer on real hardware.',
              onChanged: (value) => onChanged(
                config.copyWith(
                  parameters: parameters.copyWith(pixelsPerMillimeter: value),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _TintPicker(
              title: 'Haze colour',
              help: 'What the frost fades toward as the blur widens. Black is '
                  'pure absorption. White veils the way real frosted glass '
                  'does. Anything else tints it. Raise darkening to see any '
                  'of this.',
              selected: config.hazeTint,
              onSelected: (tint) => onChanged(config.copyWith(hazeTint: tint)),
            ),
            const SizedBox(height: 20),
            _TintPicker(
              title: 'Surround colour',
              help:
                  'Fills the pixels where the tilted glass looks past the edge '
                  'of the content. Black reads as a void, surface hides the '
                  'edge.',
              selected: config.surroundTint,
              onSelected: (tint) =>
                  onChanged(config.copyWith(surroundTint: tint)),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Motion'),
            const SizedBox(height: 12),
            _SwitchRow(
              title: 'Stretch the edges',
              help: 'On, the content smears out to fill the space the tilt '
                  'opens up, so the frost runs to the screen edge with no '
                  'boundary in it. Off, that space shows the surround colour.',
              value: parameters.stretchEdges,
              onChanged: (value) => onChanged(
                config.copyWith(
                  parameters: parameters.copyWith(stretchEdges: value),
                ),
              ),
            ),
            _SwitchRow(
              title: 'Paint a background behind the content',
              help: 'On, the demos look like ordinary apps and the fold shows '
                  'on type and photos. Off, every unpainted pixel takes the '
                  'surround colour, so the whole screen carries the frost and '
                  'the background goes with it.',
              value: config.paintBackground,
              onChanged: (value) =>
                  onChanged(config.copyWith(paintBackground: value)),
            ),
            _SwitchRow(
              title: 'Effect enabled',
              help: 'Off passes the content through untouched, for a side by '
                  'side against plain widgets.',
              value: config.enabled,
              onChanged: (value) => onChanged(config.copyWith(enabled: value)),
            ),
            _SwitchRow(
              title: 'Auto recenter',
              help: 'Washes out slow drift while the device is held still.',
              value: config.autoRecenter,
              onChanged: (value) =>
                  onChanged(config.copyWith(autoRecenter: value)),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final hasSensor = controller.hasSensor;
                // The slider wins over the sensors wherever the two disagree.
                // config.useSensor is left alone underneath, so turning the
                // slider back off restores the choice that was made here.
                final sliderDriving = config.enableSlider;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SwitchRow(
                      title: sliderSwitchTitle,
                      help: 'On draws a tilt slider over every demo and takes '
                          'the sensors out of the loop. The thumb stays where '
                          'you leave it, so a fold can be held open and looked '
                          'at rather than balanced by hand. Double tap the '
                          'thumb to drop back to flat.',
                      value: config.enableSlider,
                      onChanged: (value) =>
                          onChanged(config.copyWith(enableSlider: value)),
                    ),
                    _SwitchRow(
                      title: sensorSwitchTitle,
                      help: sliderDriving
                          ? 'The slider is driving. Turn it off to hand tilt '
                              'back to the sensors.'
                          : hasSensor
                              ? 'Off hands tilt to the slider below.'
                              : 'No rotation sensor on this device, so tilt '
                                  'comes from the slider below.',
                      value: config.useSensor && hasSensor && !sliderDriving,
                      onChanged: hasSensor && !sliderDriving
                          ? (value) =>
                              onChanged(config.copyWith(useSensor: value))
                          : null,
                    ),
                    _ParameterSlider(
                      label: 'Manual tilt',
                      value: config.manualTiltDegrees,
                      min: -45,
                      max: 45,
                      fractionDigits: 0,
                      unit: ' deg',
                      enabled:
                          !sliderDriving && !(config.useSensor && hasSensor),
                      help: sliderDriving
                          // Greyed but still live: this is the same number the
                          // on-screen slider writes, and reading it back here
                          // is how you find out what angle a fold you liked
                          // was at.
                          ? 'Set by the slider in the demos. Shown here so the '
                              'angle you settled on has a number on it.'
                          : 'Manual tilt hinges horizontally only, so a '
                              'vertical constraint reads flat while this '
                              'drives the effect.',
                      onChanged: (value) =>
                          onChanged(config.copyWith(manualTiltDegrees: value)),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            const _SectionLabel('Appearance'),
            const SizedBox(height: 12),
            _SwitchRow(
              title: 'Dark theme',
              help: 'Darkening reads differently on a dark background, so it '
                  'is worth checking both.',
              value: config.darkMode,
              onChanged: (value) => onChanged(config.copyWith(darkMode: value)),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FossButton(
                variant: FossButtonVariant.ghost,
                leading: const Icon(Icons.restart_alt),
                onPressed: () => onChanged(const DemoConfig()),
                child: const Text('Reset to package defaults'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        // IntrinsicHeight, not a bare SizedBox: fossui centres a button's
        // surface inside its tap target without a height factor, so a loose
        // maxHeight, which is what a bottom bar hands down, stretches the
        // button over the whole screen and squeezes the list to nothing.
        child: IntrinsicHeight(
          child: SizedBox(
            width: double.infinity,
            child: FossButton(
              size: FossButtonSize.lg,
              trailing: const Icon(Icons.play_arrow),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    // this.config, not the local reading of it: the gallery
                    // and the demo under it have to follow the config, not be
                    // handed a photograph of it.
                    builder: (context) => DemoGalleryScreen(
                      controller: controller,
                      config: this.config,
                      onChanged: onChanged,
                    ),
                  ),
                );
              },
              child: const Text('Show demos'),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small caps heading between config groups, over a rule.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FossText.label(
          text.toUpperCase(),
          color: FossTextColor.primary,
          style: const TextStyle(letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        const FossSeparator(),
      ],
    );
  }
}

/// The paragraph under a section heading.
class _SectionHelp extends StatelessWidget {
  const _SectionHelp(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FossText.caption(text, color: FossTextColor.mutedForeground);
  }
}

/// A row of colour swatches with the selected one ringed.
class _TintPicker extends StatelessWidget {
  const _TintPicker({
    required this.title,
    required this.help,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final String help;
  final DemoTint selected;
  final ValueChanged<DemoTint> onSelected;

  @override
  Widget build(BuildContext context) {
    // The swatches are the one control with no fossui equivalent: they show a
    // colour rather than name it. Reading the same tokens keeps their ring and
    // their border on theme with everything around them.
    final theme = context.fossTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: FossText.label(title)),
            FossText.label(selected.label,
                color: FossTextColor.mutedForeground),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final tint in DemoTint.values)
              Semantics(
                label: tint.label,
                selected: tint == selected,
                button: true,
                child: GestureDetector(
                  onTap: () => onSelected(tint),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tint.resolve(theme.colors),
                      border: Border.all(
                        color: tint == selected
                            ? theme.colors.ring
                            : theme.colors.border,
                        width: tint == selected ? 3 : 1,
                      ),
                    ),
                    child: tint == DemoTint.surface
                        ? Icon(
                            Icons.palette_outlined,
                            size: 18,
                            color: theme.colors.mutedForeground,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _SectionHelp(help),
      ],
    );
  }
}

/// A named switch with a line of explanation under it.
///
/// Laid out by hand rather than dropped into a `FossListTile`: the tile clamps
/// its subtitle to two lines, and every one of these explanations runs longer
/// than that. fossui's switch carries no label of its own, so the row around it
/// is the caller's job either way.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.help,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String help;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: FossText.label(title)),
                const SizedBox(width: 12),
                FossSwitch(
                  value: value,
                  semanticLabel: title,
                  onChanged: onChanged,
                ),
              ],
            ),
            const SizedBox(height: 4),
            _SectionHelp(help),
          ],
        ),
      ),
    );
  }
}

/// A labelled slider with its current value and a line of explanation.
class _ParameterSlider extends StatelessWidget {
  const _ParameterSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.fractionDigits,
    required this.help,
    required this.onChanged,
    this.unit = '',
    this.zeroLabel,
    this.enabled = true,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int fractionDigits;
  final String help;
  final ValueChanged<double> onChanged;
  final String unit;
  final String? zeroLabel;
  final bool enabled;

  String get _valueLabel {
    if (zeroLabel != null && value == 0) {
      return zeroLabel!;
    }
    return '${value.toStringAsFixed(fractionDigits)}$unit';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: FossText.label(label)),
              FossText.label(
                _valueLabel,
                color: FossTextColor.mutedForeground,
              ),
            ],
          ),
          const SizedBox(height: 4),
          FossSlider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            enabled: enabled,
            semanticLabel: label,
            onChanged: onChanged,
          ),
          const SizedBox(height: 4),
          _SectionHelp(help),
        ],
      ),
    );
  }
}
