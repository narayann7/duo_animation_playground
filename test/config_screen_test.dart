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

  DuoFoldController newController() {
    final controller = DuoFoldController(source: FakeMotionSource());
    addTearDown(controller.dispose);
    return controller;
  }

  group('ConfigScreen', () {
    testWidgets('lays out in both themes', (tester) async {
      for (final dark in <bool>[false, true]) {
        await tester.pumpWidget(
          wrap(
            ConfigScreen(
              controller: newController(),
              config: DemoConfig(darkMode: dark),
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
            config: const DemoConfig(),
            onChanged: (config) => reported = config,
          ),
        ),
      );

      await tester.tap(find.text(DemoConstraintOption.vertical.label));
      await tester.pump();

      expect(reported?.constraintOption, DemoConstraintOption.vertical);
    });

    testWidgets('the reset button hands back the defaults', (tester) async {
      DemoConfig? reported;
      await tester.pumpWidget(
        wrap(
          ConfigScreen(
            controller: newController(),
            config: const DemoConfig(
              enabled: false,
              constraintOption: DemoConstraintOption.free,
            ),
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
    testWidgets('lists every demo in the catalog', (tester) async {
      await tester.pumpWidget(
        wrap(
          DemoGalleryScreen(
            controller: newController(),
            config: const DemoConfig(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Social feed'), findsOneWidget);
      expect(find.text('Video feed'), findsOneWidget);
      expect(find.text('Your photo'), findsOneWidget);
    });
  });
}
