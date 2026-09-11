import 'package:duo_animation/duo_animation.dart';
import 'package:duo_animation_playground/config/demo_config.dart';
import 'package:duo_animation_playground/demos/demo_catalog.dart';
import 'package:duo_animation_playground/demos/demo_host.dart';
import 'package:duo_animation_playground/demos/photo_demo.dart';
import 'package:duo_animation_playground/demos/tilt_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every demo has to at least lay out. The fold itself passes content through
/// untouched at rest, so this exercises the hosting and the content, not the
/// shader, which no Skia-backed test can reach.
void main() {
  /// The entry whose overlay is the photo strip, which is the one demo where
  /// the slider has something to get out of the way of.
  final photoEntry =
      demoCatalog.firstWhere((entry) => entry.title == 'Your photo');

  /// Wraps [config] in the notifier these screens take, since they follow the
  /// config rather than being handed one.
  ValueNotifier<DemoConfig> live(DemoConfig config) {
    final notifier = ValueNotifier<DemoConfig>(config);
    addTearDown(notifier.dispose);
    return notifier;
  }

  Future<DemoConfig?> pumpHost(
    WidgetTester tester, {
    required DemoEntry entry,
    required ValueListenable<DemoConfig> config,
  }) async {
    DemoConfig? reported;
    final controller = DuoFoldController(source: FakeMotionSource());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: DemoHost(
          controller: controller,
          config: config,
          entry: entry,
          onChanged: (value) => reported = value,
        ),
      ),
    );
    return reported;
  }

  for (final entry in demoCatalog) {
    for (final enableSlider in <bool>[false, true]) {
      testWidgets(
        '${entry.title} lays out inside the host '
        '${enableSlider ? 'with' : 'without'} the slider',
        (tester) async {
          await pumpHost(
            tester,
            entry: entry,
            config: live(DemoConfig(enableSlider: enableSlider)),
          );

          expect(tester.takeException(), isNull);
          // Every demo gets the slider, not just the one with photographs in
          // it: the setting takes the sensors away app-wide, so a screen
          // without a slider would be a screen that cannot fold at all.
          expect(
            find.byType(TiltSlider),
            enableSlider ? findsOneWidget : findsNothing,
          );
        },
      );
    }
  }

  testWidgets('the photo strip sits at the bottom without the slider', (
    tester,
  ) async {
    await pumpHost(
      tester,
      entry: photoEntry,
      config: live(const DemoConfig()),
    );

    final screen = tester.getRect(find.byType(MaterialApp));
    final strip = tester.getCenter(find.byType(PhotoPickerBar));

    expect(strip.dx, closeTo(screen.center.dx, 1));
    expect(strip.dy, greaterThan(screen.center.dy));
    expect(
      tester.widget<PhotoPickerBar>(find.byType(PhotoPickerBar)).axis,
      Axis.horizontal,
    );
  });

  testWidgets('the slider takes the bottom and the strip moves to the right', (
    tester,
  ) async {
    await pumpHost(
      tester,
      entry: photoEntry,
      config: live(const DemoConfig(enableSlider: true)),
    );

    final screen = tester.getRect(find.byType(MaterialApp));
    final strip = tester.getCenter(find.byType(PhotoPickerBar));
    final slider = tester.getCenter(find.byType(TiltSlider));

    // The strip turns on its side and hugs the right edge, clear of the
    // slider's full width.
    expect(strip.dx, greaterThan(screen.center.dx));
    expect(strip.dy, closeTo(screen.center.dy, 1));
    expect(
      tester.widget<PhotoPickerBar>(find.byType(PhotoPickerBar)).axis,
      Axis.vertical,
    );

    expect(slider.dx, closeTo(screen.center.dx, 1));
    expect(slider.dy, greaterThan(screen.center.dy));
  });

  testWidgets('choosing another photograph drops the tilt back to flat', (
    tester,
  ) async {
    // Global for the life of the app, so it has to go back as it was or the
    // next test opens on whatever this one picked.
    final before = photoLibrary.value;
    addTearDown(() => photoLibrary.value = before);

    DemoConfig? reported;
    final controller = DuoFoldController(source: FakeMotionSource());
    addTearDown(controller.dispose);
    final config = ValueNotifier<DemoConfig>(
      const DemoConfig(enableSlider: true, manualTiltDegrees: 30),
    );
    addTearDown(config.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: DemoHost(
          controller: controller,
          config: config,
          entry: photoEntry,
          onChanged: (value) => reported = value,
        ),
      ),
    );

    photoLibrary.value = photoLibrary.value.copyWith(
      selected: bundledPhotos.last,
    );
    await tester.pump();

    // A new picture is a fresh look at the effect, so it starts unfolded
    // rather than at whatever angle the last one was left leaning.
    expect(reported, isNotNull);
    expect(reported!.manualTiltDegrees, 0);
  });

  testWidgets('a photograph change leaves the tilt alone with no slider', (
    tester,
  ) async {
    final before = photoLibrary.value;
    addTearDown(() => photoLibrary.value = before);

    DemoConfig? reported;
    final controller = DuoFoldController(source: FakeMotionSource());
    addTearDown(controller.dispose);
    final config = ValueNotifier<DemoConfig>(
      const DemoConfig(manualTiltDegrees: 30),
    );
    addTearDown(config.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: DemoHost(
          controller: controller,
          config: config,
          entry: photoEntry,
          onChanged: (value) => reported = value,
        ),
      ),
    );

    photoLibrary.value = photoLibrary.value.copyWith(
      selected: bundledPhotos.last,
    );
    await tester.pump();

    // Nothing reported at all: a manual tilt set on the config screen is a
    // deliberate angle, not the slider's leftovers.
    expect(reported, isNull);
  });

  testWidgets('dragging the slider reports a new tilt', (tester) async {
    DemoConfig? reported;
    final controller = DuoFoldController(source: FakeMotionSource());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: DemoHost(
          controller: controller,
          config: live(const DemoConfig(enableSlider: true)),
          entry: photoEntry,
          onChanged: (value) => reported = value,
        ),
      ),
    );

    await tester.drag(find.byType(TiltSlider), const Offset(120, 0));
    await tester.pump(kDoubleTapTimeout);

    // Reported rather than held: the angle lives in the config, which is what
    // carries it back to the config screen and on to disk.
    expect(reported, isNotNull);
    expect(reported!.manualTiltDegrees, greaterThan(0));
    expect(reported!.enableSlider, isTrue);
  });
}
