import 'package:duo_animation_playground/demos/photo_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The strip floats over the photograph it is choosing, so most of the time it
/// is in the way of the thing you came to look at. It opens only when asked.
void main() {
  Future<void> pump(WidgetTester tester, {Axis axis = Axis.horizontal}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: PhotoPickerBar(axis: axis)),
        ),
      ),
    );
  }

  /// The photographs on offer, which are only built when the strip is open.
  Finder tiles() => find.byType(Image);

  testWidgets('starts closed, showing one icon and no photographs', (
    tester,
  ) async {
    await pump(tester);

    expect(tiles(), findsNothing);
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
  });

  testWidgets('the icon opens the strip', (tester) async {
    await pump(tester);

    await tester.tap(find.byIcon(Icons.photo_library_outlined));
    await tester.pump();

    expect(tiles(), findsNWidgets(bundledPhotos.length));
    // The add button comes with it, so a photograph off the device is one tap
    // further rather than hidden behind a second control.
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
  });

  testWidgets('the strip closes again', (tester) async {
    await pump(tester);

    await tester.tap(find.byIcon(Icons.photo_library_outlined));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(tiles(), findsNothing);
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
  });

  testWidgets('it opens on its side too', (tester) async {
    await pump(tester, axis: Axis.vertical);

    await tester.tap(find.byIcon(Icons.photo_library_outlined));
    await tester.pump();

    expect(tiles(), findsNWidgets(bundledPhotos.length));
  });
}
