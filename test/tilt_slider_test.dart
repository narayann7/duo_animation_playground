import 'package:duo_animation_playground/demos/tilt_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The control that stands in for the rotation sensors.
///
/// Worth pinning because it is the one widget in the playground that turns a
/// gesture into a number: everything else passes a value along. The geometry is
/// fixed to a 300 pixel wide box so the arithmetic in these expectations is the
/// arithmetic the widget does.
void main() {
  /// Pumps a slider of exactly [width] and collects what it reports.
  Future<List<double>> pump(
    WidgetTester tester, {
    double value = 0,
    double width = 300,
  }) async {
    final reported = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: TiltSlider(value: value, onChanged: reported.add),
            ),
          ),
        ),
      ),
    );
    return reported;
  }

  testWidgets('reports nothing until it is touched', (tester) async {
    final reported = await pump(tester, value: 12);

    expect(reported, isEmpty);
  });

  testWidgets('it draws the knob and nothing else', (tester) async {
    await pump(tester);

    // No track behind it and no detent under it: the knob is the whole
    // control. It still takes a touch anywhere along the band it sits in, the
    // band just is not drawn.
    expect(
      find.descendant(
        of: find.byType(TiltSlider),
        matching: find.byType(Container),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a drag to the right reports a positive angle', (tester) async {
    final reported = await pump(tester);

    await tester.drag(find.byType(TiltSlider), const Offset(68, 0));
    await tester.pump(kDoubleTapTimeout);

    expect(reported.last, greaterThan(0));
  });

  testWidgets('a drag to the left reports a negative angle', (tester) async {
    final reported = await pump(tester);

    await tester.drag(find.byType(TiltSlider), const Offset(-68, 0));
    await tester.pump(kDoubleTapTimeout);

    expect(reported.last, lessThan(0));
  });

  testWidgets('the centre of the track is flat', (tester) async {
    final reported = await pump(tester, value: tiltSliderRangeDegrees);

    // Starting the gesture at the widget's centre and going nowhere: the
    // reported value is the position touched, not an offset from where the
    // thumb happened to be.
    await tester.drag(find.byType(TiltSlider), Offset.zero);
    await tester.pump(kDoubleTapTimeout);

    expect(reported.last, closeTo(0, 0.001));
  });

  testWidgets('a drag past the end clamps to the range', (tester) async {
    final reported = await pump(tester);

    await tester.drag(find.byType(TiltSlider), const Offset(4000, 0));
    await tester.pump(kDoubleTapTimeout);
    expect(reported.last, tiltSliderRangeDegrees);

    await tester.drag(find.byType(TiltSlider), const Offset(-4000, 0));
    await tester.pump(kDoubleTapTimeout);
    expect(reported.last, -tiltSliderRangeDegrees);
  });

  /// Two taps at [point], close enough together to read as a double tap.
  Future<void> doubleTapAt(WidgetTester tester, Offset point) async {
    await tester.tapAt(point);
    await tester.pump(kDoubleTapMinTime);
    await tester.tapAt(point);
    await tester.pump(kDoubleTapTimeout);
  }

  testWidgets('a double tap on the thumb puts it back to flat', (tester) async {
    final reported = await pump(tester, value: tiltSliderRangeDegrees);
    final box = tester.getRect(find.byType(TiltSlider));

    // The thumb is parked against the right end at a full lean, which is where
    // it has to be tapped.
    await doubleTapAt(tester, Offset(box.right - 14, box.center.dy));

    expect(reported.last, 0);
  });

  testWidgets('a double tap away from the thumb does not recentre', (
    tester,
  ) async {
    final reported = await pump(tester);
    final box = tester.getRect(find.byType(TiltSlider));

    // The thumb is at the centre, so the far left is nowhere near it: the taps
    // land as taps and the last of them is what is left standing.
    await doubleTapAt(tester, Offset(box.left + 14, box.center.dy));

    expect(reported.last, -tiltSliderRangeDegrees);
  });

  testWidgets('a tap lands on the very next frame', (tester) async {
    final reported = await pump(tester);
    final box = tester.getRect(find.byType(TiltSlider));

    await tester.tapAt(Offset(box.right - 20, box.center.dy));
    await tester.pump();

    // One frame, not one double-tap timeout. A control whose whole job is to
    // follow your finger cannot spend a third of a second deciding whether the
    // finger is coming back.
    expect(reported, isNotEmpty);

    await tester.pump(kDoubleTapTimeout);
  });

  testWidgets('a single tap on the thumb leaves it where it is', (
    tester,
  ) async {
    final reported = await pump(tester);

    // The thumb is already here. Tapping it is a reach for it, not a request
    // to move it a few degrees to wherever inside it the finger landed.
    await tester.tapAt(tester.getCenter(find.byType(TiltSlider)));
    await tester.pump();

    expect(reported, isEmpty);

    await tester.pump(kDoubleTapTimeout);
  });

  testWidgets('a tap jumps the thumb to where it landed', (tester) async {
    final reported = await pump(tester);
    final box = tester.getRect(find.byType(TiltSlider));

    await tester.tapAt(Offset(box.right - 20, box.center.dy));
    await tester.pump(kDoubleTapTimeout);

    expect(reported.last, greaterThan(0));
  });
}
