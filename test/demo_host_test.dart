import 'package:duo_animation/duo_animation.dart';
import 'package:duo_animation_playground/config/demo_config.dart';
import 'package:duo_animation_playground/demos/demo_catalog.dart';
import 'package:duo_animation_playground/demos/demo_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every demo has to at least lay out. The fold itself passes content through
/// untouched at rest, so this exercises the hosting and the content, not the
/// shader, which no Skia-backed test can reach.
void main() {
  for (final entry in demoCatalog) {
    testWidgets('${entry.title} lays out inside the host', (tester) async {
      final controller = DuoFoldController(source: FakeMotionSource());
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: DemoHost(
            controller: controller,
            config: const DemoConfig(),
            entry: entry,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
