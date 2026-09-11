import 'dart:async';

import 'package:duo_animation/duo_animation.dart';
import 'package:duo_animation_playground/config/demo_config.dart';
import 'package:duo_animation_playground/demos/demo_catalog.dart';
import 'package:duo_animation_playground/demos/demo_gallery_screen.dart';
import 'package:duo_animation_playground/demos/tube_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The video demo is the densest screen in the playground and the only one
/// with no phone layout, so what is worth pinning is that it lays out at every
/// tablet size, that the gallery keeps it away from phones, and that the two
/// views it has can be moved between.
///
/// `flutter_test` treats an overflow as an exception, so
/// [WidgetTester.takeException] catches a broken layout without a golden.
void main() {
  /// The title of the first video in the grid.
  const firstVideo = 'Four days on the fjord rim with everything on my back';

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TubeDemo())),
    );
  }

  /// Opens the watch page by tapping the first tile in the grid.
  Future<void> openFirst(WidgetTester tester) async {
    await tester.tap(find.text(firstVideo));
    await tester.pumpAndSettle();
  }

  const sizes = <(String, Size)>[
    ('an 11 inch tablet upright', Size(768, 1024)),
    ('an 11 inch tablet on its side', Size(1024, 768)),
    ('a 13 inch tablet', Size(1366, 1024)),
  ];

  group('the grid', () {
    for (final (name, size) in sizes) {
      testWidgets('lays out on $name', (tester) async {
        await pumpAt(tester, size);

        expect(tester.takeException(), isNull);
        // The masthead, the rail, the chip strip and the grid, one of each.
        expect(find.text('Playhouse'), findsOneWidget);
        expect(find.text('Subscriptions'), findsWidgets);
        expect(find.text('All'), findsOneWidget);
        expect(find.text(firstVideo), findsOneWidget);
      });
    }

    testWidgets('a filter chip takes the selection', (tester) async {
      await pumpAt(tester, const Size(1024, 768));

      await tester.tap(find.text('Cooking'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the rail collapses to icons and comes back', (tester) async {
      await pumpAt(tester, const Size(1024, 768));

      // 'Playlists' only exists on the full rail, and sits high enough in it
      // to be built: the rail is a lazy list.
      expect(find.text('Playlists'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Playlists'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Playlists'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the watch page', () {
    for (final (name, size) in sizes) {
      testWidgets('lays out on $name', (tester) async {
        await pumpAt(tester, size);
        await openFirst(tester);

        expect(tester.takeException(), isNull);
        expect(find.text('Subscribe'), findsOneWidget);
        expect(find.text('Up next'), findsOneWidget);
        expect(find.textContaining('views'), findsWidgets);
      });
    }

    testWidgets('the comment thread is down the page', (tester) async {
      // The page is a lazy list, so the thread is not built until it is
      // scrolled to. Getting there without an exception is the assertion.
      await pumpAt(tester, const Size(1024, 768));
      await openFirst(tester);

      // The rail is the first scrollable on the page, so name the one the
      // description sits in rather than taking whichever comes first.
      await tester.scrollUntilVisible(
        find.text('1,284 Comments'),
        400,
        scrollable: find
            .ancestor(
              of: find.text('Show more'),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.text('1,284 Comments'), findsOneWidget);
      expect(find.textContaining('Pinned by'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the up-next column only sits beside a wide player',
        (tester) async {
      // Upright there is no room for a 372 pixel column beside the player, so
      // up next drops under the description instead.
      await pumpAt(tester, const Size(768, 1024));
      await openFirst(tester);
      final upright = tester.getTopLeft(find.text('Up next'));

      await pumpAt(tester, const Size(1366, 1024));
      await openFirst(tester);
      final wide = tester.getTopLeft(find.text('Up next'));

      expect(wide.dx, greaterThan(upright.dx));
      expect(wide.dy, lessThan(upright.dy));
    });

    testWidgets('the back arrow returns to the grid', (tester) async {
      await pumpAt(tester, const Size(1024, 768));
      await openFirst(tester);
      expect(find.text('Subscribe'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back to the grid'));
      await tester.pumpAndSettle();

      expect(find.text('Subscribe'), findsNothing);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('the system back gesture goes to the grid, not out of the demo',
        (tester) async {
      // The watch page is a view rather than a route, so back has to be
      // intercepted: without it the gesture pops the host and leaves the demo
      // from inside a video. Pushed onto a real navigator, since that is the
      // thing that must not be popped.
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(1024, 768);
      addTearDown(tester.view.reset);

      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Center(child: Text('the gallery'))),
        ),
      );
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (context) => const Scaffold(body: TubeDemo()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await openFirst(tester);
      expect(find.text('Subscribe'), findsOneWidget);

      // First back lands on the grid and the demo is still on the navigator.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Subscribe'), findsNothing);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('the gallery'), findsNothing);

      // Second one is allowed through and leaves the demo.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('the gallery'), findsOneWidget);
      expect(find.byType(TubeDemo), findsNothing);
    });

    testWidgets('subscribe and the vote both toggle', (tester) async {
      await pumpAt(tester, const Size(1366, 1024));
      await openFirst(tester);

      await tester.tap(find.text('Subscribe'));
      await tester.pumpAndSettle();
      expect(find.text('Subscribed'), findsOneWidget);

      // The like half carries its count in its label, so match on the front
      // of it rather than the whole string.
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Like')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.thumb_up), findsOneWidget);

      // Tapping the same half again clears the vote rather than sticking.
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Like')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.thumb_up), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an up-next row opens that video', (tester) async {
      await pumpAt(tester, const Size(1366, 1024));
      await openFirst(tester);

      // The video being watched is kept out of its own up-next column.
      expect(find.text(firstVideo), findsOneWidget);

      const next = 'The red rock loop that everybody starts from the wrong end';
      await tester.tap(find.text(next).last);
      await tester.pumpAndSettle();

      expect(find.text(next), findsOneWidget);
      expect(find.text(firstVideo), findsWidgets);
      // A fresh video arrives unsubscribed, the way a page load would.
      expect(find.text('Subscribe'), findsOneWidget);
    });
  });

  group('the gallery gate', () {
    final entry =
        demoCatalog.firstWhere((entry) => entry.title == 'Video site');

    test('the entry asks for a tablet', () {
      expect(entry.minShortestSide, TubeDemo.minShortestSide);
      expect(entry.fitsOn(390), isFalse);
      expect(entry.fitsOn(768), isTrue);
    });

    Widget gallery() {
      final controller = DuoFoldController(source: FakeMotionSource());
      addTearDown(controller.dispose);
      final config = ValueNotifier<DemoConfig>(const DemoConfig());
      addTearDown(config.dispose);
      return MaterialApp(
        home: DemoGalleryScreen(
          controller: controller,
          config: config,
          onChanged: (_) {},
        ),
      );
    }

    testWidgets('a phone is not offered the row', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(gallery());

      expect(find.text('Video site'), findsNothing);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('a tablet is', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(1024, 768);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(gallery());

      expect(find.text('Video site'), findsOneWidget);
    });
  });
}
