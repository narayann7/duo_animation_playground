import 'package:duo_animation_playground/demos/dashboard_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

/// The dashboard is the one demo with two layouts in it, so the thing worth
/// testing is that the right one turns up at the right size and that neither
/// overflows. `flutter_test` treats an overflow as an exception, so
/// [WidgetTester.takeException] catches it without a golden.
void main() {
  /// Pumps the dashboard on a surface [size] logical pixels across.
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DashboardDemo())),
    );
  }

  /// A string that appears in the side rail and nowhere else.
  final railOnly = find.text('Inventory');

  testWidgets('a phone gets the single column, no rail', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    expect(tester.takeException(), isNull);
    expect(railOnly, findsNothing);
    expect(find.text('Overview'), findsOneWidget);
  });

  testWidgets('a phone on its side still gets the single column',
      (tester) async {
    // The breakpoint reads the shortest side, so turning the device does not
    // swap the layout out from under a tilt.
    await pumpAt(tester, const Size(844, 390));

    expect(tester.takeException(), isNull);
    expect(railOnly, findsNothing);
  });

  for (final (name, size) in <(String, Size)>[
    ('portrait', Size(768, 1024)),
    ('landscape', Size(1024, 768)),
  ]) {
    testWidgets('a tablet in $name gets the rail and the grid', (tester) async {
      await pumpAt(tester, size);

      expect(tester.takeException(), isNull);
      expect(railOnly, findsOneWidget);
      // Once in the rail as the current page, once as the heading.
      expect(find.text('Overview'), findsNWidgets(2));
    });
  }

  testWidgets('no tile on a tablet runs away with the screen', (tester) async {
    // The wide layout deals its panels into columns instead of stretching a
    // row of them to a shared height, so a shallow card stops where its
    // content stops. Half the viewport is the ceiling a stretched card used to
    // sail past.
    await pumpAt(tester, const Size(1024, 768));

    final cards = find.byType(FossCard);
    expect(cards, findsWidgets);
    for (final card in cards.evaluate()) {
      final size = tester.getSize(find.byWidget(card.widget));
      expect(
        size.height,
        lessThan(768 / 2),
        reason: 'a panel is ${size.height} tall on a 768 tall screen',
      );
    }
  });

  testWidgets('the tablet grid puts up more than one row of panels',
      (tester) async {
    await pumpAt(tester, const Size(1024, 768));

    for (final title in <String>[
      'Takings',
      'Channels',
      'In progress',
      'Top lines',
      'Dispatch',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  testWidgets('the period tabs redraw the chart and the subtitle',
      (tester) async {
    await pumpAt(tester, const Size(1024, 768));

    expect(find.text('£48.2k'), findsOneWidget);
    expect(find.textContaining('week to 14 March'), findsOneWidget);

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();

    expect(find.text('£2.41m'), findsOneWidget);
    expect(find.textContaining('year to date'), findsOneWidget);
    expect(find.text('£48.2k'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a filter chip toggles off and on', (tester) async {
    await pumpAt(tester, const Size(1024, 768));

    FossChip chipFor(String label) => tester.widget<FossChip>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(FossChip),
          ),
        );

    expect(chipFor('This week').selected, isTrue);

    await tester.tap(find.text('This week'));
    await tester.pumpAndSettle();
    expect(chipFor('This week').selected, isFalse);

    await tester.tap(find.text('This week'));
    await tester.pumpAndSettle();
    expect(chipFor('This week').selected, isTrue);
  });

  testWidgets('a button raises a toast inside the fold', (tester) async {
    // The toaster is mounted inside the demo, so the toast is folded with
    // everything else rather than floating crisp above it.
    await pumpAt(tester, const Size(1024, 768));

    await tester.tap(find.text('New report'));
    await tester.pumpAndSettle();

    expect(find.text('Report queued'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the dashboard still scrolls', (tester) async {
    // A drag is measured on its delta, so it does not care that the fold has
    // moved the pixels under the finger. Scrolling has to keep working.
    await pumpAt(tester, const Size(390, 844));

    final before = tester.getTopLeft(find.text('Takings')).dy;
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pump();

    expect(tester.getTopLeft(find.text('Takings')).dy, lessThan(before));
    expect(tester.takeException(), isNull);
  });
}
