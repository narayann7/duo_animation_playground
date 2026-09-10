import 'dart:io';

import 'package:duo_animation/duo_animation.dart';
import 'package:duo_animation_playground/config/demo_config.dart';
import 'package:duo_animation_playground/demos/photo_demo.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the playground writes to disk and reads back on the next launch.
///
/// The store itself is a thin wrapper over a directory and needs a platform
/// channel to say where that directory is, so what is worth pinning here is the
/// part that has decisions in it: the two values that serialise themselves, and
/// what they do with a file written by a build that no longer matches.
void main() {
  group('DemoConfig', () {
    test('survives a round trip', () {
      const config = DemoConfig(
        constraintOption: DemoConstraintOption.vertical,
        parameters: DuoFoldParameters(
          eyeDistanceMillimeters: 320,
          pixelsPerMillimeter: 12,
          blurSpread: 0.2,
          darkening: 0.02,
          baseBlurMillimeters: 0.3,
          stretchEdges: false,
          tiltResponse: 3,
        ),
        enabled: false,
        autoRecenter: false,
        useSensor: false,
        manualTiltDegrees: 17,
        darkMode: true,
        paintBackground: false,
        hazeTint: DemoTint.teal,
        surroundTint: DemoTint.rose,
      );

      final restored = DemoConfig.fromJson(config.toJson());

      expect(restored.constraintOption, config.constraintOption);
      expect(restored.parameters, config.parameters);
      expect(restored.enabled, isFalse);
      expect(restored.autoRecenter, isFalse);
      expect(restored.useSensor, isFalse);
      expect(restored.manualTiltDegrees, 17);
      expect(restored.darkMode, isTrue);
      expect(restored.paintBackground, isFalse);
      expect(restored.hazeTint, DemoTint.teal);
      expect(restored.surroundTint, DemoTint.rose);
    });

    test('falls back to the defaults field by field', () {
      const defaults = DemoConfig();

      final restored = DemoConfig.fromJson(<String, Object?>{
        'constraintOption': 'diagonal',
        'parameters': <String, Object?>{'blurSpread': 0.5, 'darkening': 'lots'},
        'darkMode': true,
        'enabled': 'yes',
      });

      // The one value that was both present and the right shape is kept, and
      // everything around it, including a knob whose name has moved on, comes
      // back at its default rather than taking the whole file down with it.
      expect(restored.parameters.blurSpread, 0.5);
      expect(restored.darkMode, isTrue);
      expect(restored.constraintOption, defaults.constraintOption);
      expect(restored.parameters.darkening, defaults.parameters.darkening);
      expect(restored.enabled, defaults.enabled);
    });
  });

  group('PhotoLibrary', () {
    late Directory directory;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('photo_library_test');
    });

    tearDown(() => directory.deleteSync(recursive: true));

    File photoFile(String name) =>
        File('${directory.path}/$name')..writeAsBytesSync(const <int>[0]);

    test('survives a round trip', () {
      final first = PhotoChoice.file(photoFile('one'));
      final second = PhotoChoice.file(photoFile('two'));
      final library = PhotoLibrary(
        imported: <PhotoChoice>[first, second],
        selected: second,
      );

      final restored = PhotoLibrary.fromJson(library.toJson());

      expect(restored.imported, <PhotoChoice>[first, second]);
      expect(restored.selected, second);
    });

    test('drops imports whose file has gone', () {
      final kept = PhotoChoice.file(photoFile('kept'));
      final deleted = PhotoChoice.file(photoFile('deleted'));
      final json = PhotoLibrary(
        imported: <PhotoChoice>[kept, deleted],
        selected: deleted,
      ).toJson();
      deleted.file!.deleteSync();

      final restored = PhotoLibrary.fromJson(json);

      expect(restored.imported, <PhotoChoice>[kept]);
      // The selection went with the file, so it lands back on the bundled
      // photograph the demo opens on rather than on nothing.
      expect(restored.selected, bundledPhotos.first);
    });

    test('holds no more than the ceiling', () {
      final photos = <PhotoChoice>[
        for (var index = 0; index <= maxImportedPhotos; index++)
          PhotoChoice.file(photoFile('photo$index')),
      ];

      final restored = PhotoLibrary.fromJson(
        PhotoLibrary(imported: photos, selected: photos.first).toJson(),
      );

      expect(restored.imported, hasLength(maxImportedPhotos));
      expect(restored.isFull, isTrue);
    });
  });
}
