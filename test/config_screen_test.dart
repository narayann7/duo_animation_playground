import 'package:duo_animation/duo_animation.dart';
import 'package:duo_animation_playground/config/config_screen.dart';
import 'package:duo_animation_playground/config/demo_config.dart';
import 'package:duo_animation_playground/demos/demo_gallery_screen.dart';
import 'package:duo_animation_playground/foss_material_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

/// The two screens the playground drives itself from.
///
/// Neither one folds anything, so unlike the demos they are fully testable off
/// a real device. What is worth pinning is that they lay out at all: both are
/// tall scrolling columns of controls, and the last time one of them collapsed
/// it did so silently, into a 36 pixel wide strip.
void main() {
  Widget wrap(Widget child, {bool dark = false}) {
    return MaterialApp(
      theme: fossMaterialTheme(
        dark ? FossThemeData.dark : FossThemeData.light,
        dark ? Brightness.dark : Brightness.light,
      ),
      home: child,
    );
  }

  /// Wraps [config] in the notifier these screens take, since they follow the
  /// config rather than being handed one.
  ValueNotifier<DemoConfig> live(DemoConfig config) {
    final notifier = ValueNotifier<DemoConfig>(config);
    addTearDown(notifier.dispose);
    return notifier;
  }

  DuoFoldController newController() {
    final controller = DuoFoldController(source: FakeMotionSource());
    addTearDown(controller.dispose);
    return controller;
  }

  /// A controller that has read metrics claiming a rotation sensor, which is
  /// what makes the sensor switch live. Without one it is disabled anyway and
  /// a test of what disables it proves nothing.
  Future<DuoFoldController> startedSensorController() async {
    final controller = DuoFoldController(
      source: FakeMotionSource(
        metrics: const DuoFoldDisplayMetrics(
          pixelsPerMillimeter: 6,
          hasRotationSensor: true,
        ),
      ),
    );
    addTearDown(controller.dispose);
    await controller.start();
    return controller;
  }

  /// The fossui switch carrying [label], which is the title of its row.
  Finder switchLabelled(String label) => find.byWidgetPredicate(
        (widget) => widget is FossSwitch && widget.semanticLabel == label,
      );

  group('ConfigScreen', () {
    testWidgets('lays out in both themes', (tester) async {
      for (final dark in <bool>[false, true]) {
        await tester.pumpWidget(
          wrap(
            ConfigScreen(
              controller: newController(),
              config: live(DemoConfig(darkMode: dark)),
              onChanged: (_) {},
            ),
            dark: dark,
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Fold configuration'), findsOneWidget);
        expect(find.text('Show demos'), findsOneWidget);
      }
    });

    testWidgets('reports the constraint the tapped chip stands for', (
      tester,
    ) async {
      DemoConfig? reported;
      await tester.pumpWidget(
        wrap(
          ConfigScreen(
            controller: newController(),
            config: live(const DemoConfig()),
            onChanged: (config) => reported = config,
          ),
        ),
      );

      await tester.tap(find.text(DemoConstraintOption.vertical.label));
      await tester.pump();

      expect(reported?.constraintOption, DemoConstraintOption.vertical);
    });

    testWidgets('the slider switch reports itself', (tester) async {
      DemoConfig? reported;
      await tester.pumpWidget(
        wrap(
          ConfigScreen(
            controller: await startedSensorController(),
            config: live(const DemoConfig()),
            onChanged: (config) => reported = config,
          ),
        ),
      );

      await tester.scrollUntilVisible(switchLabelled(sliderSwitchTitle), 200);
      await tester.tap(switchLabelled(sliderSwitchTitle));
      await tester.pump();

      expect(reported?.enableSlider, isTrue);
    });

    testWidgets('the slider takes the sensor switch out of the loop', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ConfigScreen(
            controller: await startedSensorController(),
            config: live(const DemoConfig(enableSlider: true)),
            onChanged: (_) {},
          ),
        ),
      );

      await tester.scrollUntilVisible(switchLabelled(sensorSwitchTitle), 200);
      final sensor = tester.widget<FossSwitch>(switchLabelled(sensorSwitchTitle));

      // Off and untappable: the slider is driving, and the stored preference is
      // deliberately not what the row shows while that is true.
      expect(sensor.value, isFalse);
      expect(sensor.onChanged, isNull);
    });

    testWidgets('the sensor switch is live again once the slider is off', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ConfigScreen(
            controller: await startedSensorController(),
            config: live(const DemoConfig()),
            onChanged: (_) {},
          ),
        ),
      );

      await tester.scrollUntilVisible(switchLabelled(sensorSwitchTitle), 200);
      final sensor = tester.widget<FossSwitch>(switchLabelled(sensorSwitchTitle));

      expect(sensor.value, isTrue);
      expect(sensor.onChanged, isNotNull);
    });

    testWidgets('the reset button hands back the defaults', (tester) async {
      DemoConfig? reported;
      await tester.pumpWidget(
        wrap(
          ConfigScreen(
            controller: newController(),
            config: live(const DemoConfig(
              enabled: false,
              constraintOption: DemoConstraintOption.free,
            )),
            onChanged: (config) => reported = config,
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Reset to package defaults'),
        200,
      );
      await tester.tap(find.text('Reset to package defaults'));
      await tester.pump();

      expect(reported, isNotNull);
      expect(reported!.enabled, const DemoConfig().enabled);
      expect(reported!.constraintOption, const DemoConfig().constraintOption);
    });
  });

  group('DemoGalleryScreen', () {
    /// Opens the first demo and comes back out of it the way the system back
    /// gesture does, reporting whatever the gallery hands up on the way.
    Future<DemoConfig?> openAndLeave(
      WidgetTester tester,
      DemoConfig start,
    ) async {
      DemoConfig? reported;
      await tester.pumpWidget(
        wrap(
          DemoGalleryScreen(
            controller: newController(),
            config: live(start),
            onChanged: (config) => reported = config,
          ),
        ),
      );

      await tester.tap(find.text('Your photo'));
      await tester.pumpAndSettle();
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      return reported;
    }

    testWidgets('leaving a demo puts the tilt back to flat', (tester) async {
      final reported = await openAndLeave(
        tester,
        const DemoConfig(enableSlider: true, manualTiltDegrees: 30),
      );

      // The slider is chrome on a screen you have just closed, so the angle it
      // was holding goes with it rather than waiting for the next demo.
      expect(reported, isNotNull);
      expect(reported!.manualTiltDegrees, 0);
    });

    testWidgets('leaving a demo leaves a manual tilt alone', (tester) async {
      final reported = await openAndLeave(
        tester,
        const DemoConfig(manualTiltDegrees: 30),
      );

      // No slider was ever on screen, so there is nothing here that the demo
      // set and nothing for it to take back.
      expect(reported, isNull);
    });

    testWidgets('lists every demo in the catalog', (tester) async {
      await tester.pumpWidget(
        wrap(
          DemoGalleryScreen(
            controller: newController(),
            config: live(const DemoConfig()),
            onChanged: (_) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Your photo'), findsOneWidget);
    });
  });
}
