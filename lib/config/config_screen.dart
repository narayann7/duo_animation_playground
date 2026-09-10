import 'package:duo_animation/duo_animation.dart';
import 'package:flutter/material.dart';

import '../demos/demo_gallery_screen.dart';
import '../tilt_readout.dart';
import 'demo_config.dart';

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

  /// Current configuration.
  final DemoConfig config;

  /// Called with the edited configuration.
  final ValueChanged<DemoConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parameters = config.parameters;
    return Scaffold(
      appBar: AppBar(title: const Text('Fold configuration')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: TiltReadout(controller: controller),
            ),
          ),
          const SizedBox(height: 16),
          _SectionLabel('Hinge constraint'),
          Text(
            'Which fold directions the effect responds to. A constrained fold '
            'keeps only the pose along the chosen axis, so it falls off as the '
            'device rotates off that axis rather than snapping.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in DemoConstraintOption.values)
                ChoiceChip(
                  label: Text(option.label),
                  selected: config.constraintOption == option,
                  onSelected: (_) =>
                      onChanged(config.copyWith(constraintOption: option)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('Optics'),
          _ParameterSlider(
            label: 'Blur spread',
            value: parameters.blurSpread,
            min: 0,
            max: 0.4,
            fractionDigits: 3,
            help:
                'Blur radius gained per pixel of separation between the '
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
            help: 'Frost carried across the whole screen once the fold leaves '
                'rest. Zero leaves the hinge side sharp, which is what the '
                'optics alone give.',
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
            help:
                'Light lost per pixel of blur radius. Frostier glass reads '
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
            help: 'How tilt maps onto the fold. One is linear. Higher holds the '
                'small tilts back and leaves the widest tilt where it is, which '
                'is what a large screen usually wants.',
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
            help:
                'Distance from the viewer to the untilted screen. Larger '
                'values flatten the perspective and crop less at wide tilts.',
            onChanged: (value) => onChanged(
              config.copyWith(
                parameters: parameters.copyWith(eyeDistanceMillimeters: value),
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
            help:
                'Zero resolves the density from the display metrics, which '
                'is the right answer on real hardware.',
            onChanged: (value) => onChanged(
              config.copyWith(
                parameters: parameters.copyWith(pixelsPerMillimeter: value),
              ),
            ),
          ),
          _TintPicker(
            title: 'Haze colour',
            help: 'What the frost fades toward as the blur widens. Black is '
                'pure absorption. White veils the way real frosted glass does. '
                'Anything else tints it. Raise darkening to see any of this.',
            selected: config.hazeTint,
            onSelected: (tint) => onChanged(config.copyWith(hazeTint: tint)),
          ),
          const SizedBox(height: 16),
          _TintPicker(
            title: 'Surround colour',
            help: 'Fills the pixels where the tilted glass looks past the edge '
                'of the content. Black reads as a void, surface hides the edge.',
            selected: config.surroundTint,
            onSelected: (tint) =>
                onChanged(config.copyWith(surroundTint: tint)),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Motion'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Stretch the edges'),
            subtitle: const Text('On, the content smears out to fill the space '
                'the tilt opens up, so the frost runs to the screen edge with '
                'no boundary in it. Off, that space shows the surround colour.'),
            value: parameters.stretchEdges,
            onChanged: (value) => onChanged(
              config.copyWith(
                parameters: parameters.copyWith(stretchEdges: value),
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Paint a background behind the content'),
            subtitle: const Text('On, the demos look like ordinary apps and the '
                'fold shows on type and photos. Off, every unpainted pixel '
                'takes the surround colour, so the whole screen carries the '
                'frost and the background goes with it.'),
            value: config.paintBackground,
            onChanged: (value) =>
                onChanged(config.copyWith(paintBackground: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Effect enabled'),
            subtitle: const Text(
              'Off passes the content through untouched, '
              'for a side by side against plain widgets.',
            ),
            value: config.enabled,
            onChanged: (value) => onChanged(config.copyWith(enabled: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto recenter'),
            subtitle: const Text(
              'Washes out slow drift while the device is '
              'held still.',
            ),
            value: config.autoRecenter,
            onChanged: (value) =>
                onChanged(config.copyWith(autoRecenter: value)),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final hasSensor = controller.hasSensor;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Drive from sensors'),
                    subtitle: Text(
                      hasSensor
                          ? 'Off hands tilt to the slider below.'
                          : 'No rotation sensor on this device, so tilt comes '
                                'from the slider below.',
                    ),
                    value: config.useSensor && hasSensor,
                    onChanged: hasSensor
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
                    enabled: !(config.useSensor && hasSensor),
                    help:
                        'Manual tilt hinges horizontally only, so a vertical '
                        'constraint reads flat while this drives the effect.',
                    onChanged: (value) =>
                        onChanged(config.copyWith(manualTiltDegrees: value)),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          _SectionLabel('Appearance'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark theme'),
            subtitle: const Text(
              'Darkening reads differently on a dark '
              'background, so it is worth checking both.',
            ),
            value: config.darkMode,
            onChanged: (value) => onChanged(config.copyWith(darkMode: value)),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => onChanged(const DemoConfig()),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset to package defaults'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) =>
                    DemoGalleryScreen(controller: controller, config: config),
              ),
            );
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Show demos'),
        ),
      ),
    );
  }
}

/// A small caps heading between config groups.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            Text(selected.label, style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final tint in DemoTint.values)
              GestureDetector(
                onTap: () => onSelected(tint),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tint.resolve(scheme),
                    border: Border.all(
                      color: tint == selected
                          ? scheme.primary
                          : scheme.outlineVariant,
                      width: tint == selected ? 3 : 1,
                    ),
                  ),
                  child: tint == DemoTint.surface
                      ? Icon(
                          Icons.palette_outlined,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        )
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          help,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
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
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
              Text(_valueLabel, style: theme.textTheme.labelLarge),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: enabled ? onChanged : null,
          ),
          Text(help, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        ],
      ),
    );
  }
}
