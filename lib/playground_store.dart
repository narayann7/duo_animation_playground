import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// The playground's corner of the disk.
///
/// Settings and the picked photographs are held in memory while the app runs;
/// this mirrors them to a file so a relaunch comes back to the setup you were
/// in the middle of judging rather than to the defaults. Tuning the fold is
/// slow work, and losing a set of slider positions to a hot restart costs more
/// than the write does.
///
/// Deliberately dumb: it knows about directories, JSON and file copies, and
/// nothing about what the playground puts in them. Each type serialises itself,
/// which is what keeps this from importing half the app.
///
/// The support directory rather than the cache directory, even though what is
/// kept here is a cache in spirit: the system is free to empty the cache
/// directory whenever it wants the space back, and a picked photograph
/// disappearing between launches would read as a bug rather than as
/// housekeeping. Nothing here is precious, but it should not evaporate on its
/// own.
abstract final class PlaygroundStore {
  /// The file the config screen's settings are written to.
  static const String configFile = 'config.json';

  /// The file the photo demo's library and selection are written to.
  static const String photoFile = 'photo.json';

  static Directory? _directory;

  static final Map<String, Timer> _pendingWrites = <String, Timer>{};

  /// The directory everything is kept in, created on first use.
  static Future<Directory> directory() async {
    final existing = _directory;
    if (existing != null) {
      return existing;
    }
    final base = await getApplicationSupportDirectory();
    final directory = Directory('${base.path}/playground');
    await directory.create(recursive: true);
    return _directory = directory;
  }

  /// Reads [name] back, or null when it is missing or unreadable.
  ///
  /// Unreadable counts as missing on purpose. The only thing on the other end
  /// of this is a file the playground wrote itself, so a decode failure means
  /// the format moved under a build that was already installed, and the answer
  /// to that is the defaults rather than a crash on launch.
  static Future<Map<String, Object?>?> readJson(String name) async {
    try {
      final file = File('${(await directory()).path}/$name');
      if (!file.existsSync()) {
        return null;
      }
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map<String, Object?> ? decoded : null;
    } on Object catch (error) {
      debugPrint('Could not read $name: $error');
      return null;
    }
  }

  /// Writes [value] to [name] a short while after the last call for that name.
  ///
  /// Fire and forget, and coalescing by design: dragging one slider produces a
  /// value per frame, and the only one worth keeping is the one your finger
  /// stopped on. [delay] is long enough to swallow a drag and short enough that
  /// letting go and killing the app keeps what you let go of.
  static void writeJson(
    String name,
    Map<String, Object?> value, {
    Duration delay = const Duration(milliseconds: 400),
  }) {
    _pendingWrites[name]?.cancel();
    _pendingWrites[name] = Timer(delay, () {
      _pendingWrites.remove(name);
      unawaited(_write(name, value));
    });
  }

  static Future<void> _write(String name, Map<String, Object?> value) async {
    try {
      final file = File('${(await directory()).path}/$name');
      await file.writeAsString(jsonEncode(value));
    } on Object catch (error) {
      debugPrint('Could not write $name: $error');
    }
  }

  /// Copies [source] in and hands back the copy.
  ///
  /// The picker hands out a file in a temporary directory that the system
  /// empties on its own schedule, so the path it returns is worth remembering
  /// only until the app closes. Copying makes the choice outlive the run.
  ///
  /// Every copy gets a fresh name rather than a slot that gets reused, because
  /// Flutter's image cache keys a file image on its path alone: reuse a path
  /// and the picture you replaced is the one that gets drawn.
  static Future<File> importPhoto(File source) async {
    final directory = await photoDirectory();
    // No extension: the decoder reads the bytes, not the name, and the picker
    // is under no obligation to hand back a file that has one.
    final copy = '${directory.path}/'
        '${DateTime.now().microsecondsSinceEpoch}.photo';
    return source.copy(copy);
  }

  /// Deletes an imported photograph. Missing is as good as deleted.
  static Future<void> deletePhoto(File photo) async {
    try {
      if (photo.existsSync()) {
        await photo.delete();
      }
    } on Object catch (error) {
      debugPrint('Could not delete ${photo.path}: $error');
    }
  }

  /// Deletes every imported photograph whose path is not in [keep].
  ///
  /// Housekeeping for the gap between copying a file in and writing down that
  /// it exists: a launch that never got as far as the write leaves a file
  /// nothing points at, and nothing else would ever clear it.
  static Future<void> pruneImports(Set<String> keep) async {
    try {
      for (final entity in (await photoDirectory()).listSync()) {
        if (!keep.contains(entity.path)) {
          entity.deleteSync(recursive: true);
        }
      }
    } on Object catch (error) {
      debugPrint('Could not prune imported photos: $error');
    }
  }

  /// Where imported photographs are kept, created on first use.
  static Future<Directory> photoDirectory() async {
    final directory = Directory('${(await PlaygroundStore.directory()).path}/'
        'photos');
    await directory.create(recursive: true);
    return directory;
  }
}
