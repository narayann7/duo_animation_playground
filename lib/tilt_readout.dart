import 'package:duo_animation/duo_animation.dart';
import 'package:flutter/material.dart';

/// Live tilt readout with a recalibrate button.
///
/// The numbers come from the filtered output rather than the raw sensor, so a
/// value pinned at zero while the phone is moving means samples are not
/// arriving at all, which is a different problem from the effect looking wrong.
class TiltReadout extends StatelessWidget {
  /// Creates a readout for [controller].
  const TiltReadout({
    super.key,
    required this.controller,
    this.compact = false,
  });

  /// The controller being read.
  final DuoFoldController controller;

  /// True drops the sensor warning and tightens the layout for an app bar.
  final bool compact;

  /// Names the hinge nearest the current lift direction, for display only.
  /// Ties, meaning an exactly diagonal lift, favour the horizontal label.
  static String _hingeLabel(double liftDirX, double liftDirY) {
    if (liftDirX.abs() >= liftDirY.abs()) {
      return liftDirX < 0 ? 'right' : 'left';
    }
    return liftDirY > 0 ? 'top' : 'bottom';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final tilt = controller.tiltDegrees;
        final hinge = _hingeLabel(controller.liftDirX, controller.liftDirY);
        final line = 'tilt ${tilt.toStringAsFixed(1)} deg, hinge $hinge';
        if (compact) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(line, style: theme.textTheme.labelMedium),
              IconButton(
                onPressed: controller.recalibrate,
                icon: const Icon(Icons.center_focus_strong_outlined),
                tooltip: 'Recalibrate',
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line, style: theme.textTheme.bodyMedium),
                  if (!controller.hasSensor)
                    Text(
                      'no rotation sensor found, use manual tilt below',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: controller.recalibrate,
              child: const Text('Recalibrate'),
            ),
          ],
        );
      },
    );
  }
}
