import 'package:duo_animation/duo_animation.dart';
import 'package:duo_animation_playground/config/config_screen.dart';
import 'package:duo_animation_playground/config/demo_config.dart';
import 'package:duo_animation_playground/demos/tilt_slider.dart';
import 'package:duo_animation_playground/foss_material_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

/// The config has to reach a demo that is already open.
///
/// Everything the playground shows over a demo reads from the config, and the
/// config lives at the app root, two pushed routes above. That gap is not
/// exercised by testing either screen on its own: both are correct in
/// isolation and the value still fails to arrive.
void main() {
  testWidgets('a drag on the slider moves the slider', (tester) async {
    final controller = DuoFoldController(source: FakeMotionSource());
    addTearDown(controller.dispose);

    // Stands in for the app root: holds the config, hands it down, takes the
    // edits back. Same shape as main.dart.
    await tester.pumpWidget(
      _Harness(controller: controller),
    );

    await tester.tap(find.text('Show demos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your photo'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(TiltSlider), const Offset(120, 0));
    await tester.pumpAndSettle();

    // The root took the edit: it is the way back down, through two pushed
    // routes, that used to drop it.
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(state._config.value.manualTiltDegrees, greaterThan(0));

    // The thumb is drawn from the config, so a config that never came back
    // down leaves it parked at zero however far it was dragged.
    expect(tester.widget<TiltSlider>(find.byType(TiltSlider)).value,
        greaterThan(0));
  });
}

class _Harness extends StatefulWidget {
  const _Harness({required this.controller});

  final DuoFoldController controller;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final ValueNotifier<DemoConfig> _config =
      ValueNotifier<DemoConfig>(const DemoConfig(enableSlider: true));

  @override
  void dispose() {
    _config.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: fossMaterialTheme(FossThemeData.light, Brightness.light),
      home: ConfigScreen(
        controller: widget.controller,
        config: _config,
        onChanged: (config) => _config.value = config,
      ),
    );
  }
}
