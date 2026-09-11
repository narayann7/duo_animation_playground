import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';
import 'package:image_picker/image_picker.dart';

import '../playground_store.dart';

/// How many photographs can be held off the device at once.
///
/// Five is enough to line up a set worth comparing and still leaves the strip a
/// strip: with the bundled three and the add button that is nine tiles, which
/// is already wider than a phone and scrolls.
const int maxImportedPhotos = 5;

/// A photograph to fold: either one of the bundled ones or a file off the
/// device.
@immutable
class PhotoChoice {
  /// A bundled photograph, addressed by asset key.
  const PhotoChoice.asset(this.assetKey) : file = null;

  /// A photograph picked off the device.
  const PhotoChoice.file(File this.file) : assetKey = null;

  /// Set when the choice is a bundled photograph.
  final String? assetKey;

  /// Set when the choice came from the picker.
  final File? file;

  /// Builds the image at [width] pixels wide when a width is worth pinning,
  /// which is what keeps a 48pt thumbnail from decoding at full resolution.
  Widget build({BoxFit fit = BoxFit.cover, int? cacheWidth}) {
    final key = assetKey;
    if (key != null) {
      return Image.asset(key, fit: fit, cacheWidth: cacheWidth);
    }
    return Image.file(file!, fit: fit, cacheWidth: cacheWidth);
  }

  @override
  bool operator ==(Object other) {
    return other is PhotoChoice &&
        other.assetKey == assetKey &&
        other.file?.path == file?.path;
  }

  @override
  int get hashCode => Object.hash(assetKey, file?.path);
}

const PhotoChoice _fairground =
    PhotoChoice.asset('assets/photos/fairground.jpg');

/// The bundled photographs, chosen to cover different kinds of detail: faces
/// and motion blur, a horizon of hard architectural edges, and a wide view
/// with foliage and cloud.
const List<PhotoChoice> bundledPhotos = <PhotoChoice>[
  _fairground,
  PhotoChoice.asset('assets/photos/skyline.jpg'),
  PhotoChoice.asset('assets/photos/riverfront.jpg'),
];

/// What the photo demo has to show and which of it is on screen.
///
/// One value rather than two notifiers: the strip draws from both halves, and
/// deleting the picture being folded has to move the selection in the same
/// breath, which is a single edit here and a two-step with a visible gap in
/// between if the two are kept apart.
@immutable
class PhotoLibrary {
  /// Creates a library.
  const PhotoLibrary({
    this.imported = const <PhotoChoice>[],
    this.selected = _fairground,
  });

  /// Reads a library back out of [json], dropping anything that has gone
  /// stale.
  ///
  /// Both halves can rot between runs: an asset can be dropped from the bundle
  /// by a later build, and an imported file can be deleted from under the app.
  /// Whatever survives is kept and the rest is forgotten quietly, because the
  /// worst case is opening on the first bundled photograph, which is where the
  /// demo starts anyway.
  factory PhotoLibrary.fromJson(Map<String, Object?> json) {
    final imported = <PhotoChoice>[];
    final paths = json['imported'];
    if (paths is List) {
      for (final path in paths) {
        if (path is String && File(path).existsSync()) {
          imported.add(PhotoChoice.file(File(path)));
        }
        if (imported.length == maxImportedPhotos) {
          break;
        }
      }
    }
    final selected = json['selected'];
    return PhotoLibrary(
      imported: imported,
      selected: _selectedFrom(selected, imported) ?? _fairground,
    );
  }

  /// Photographs picked off the device, oldest first, never more than
  /// [maxImportedPhotos] of them.
  final List<PhotoChoice> imported;

  /// The one being folded.
  final PhotoChoice selected;

  /// Everything the strip offers, in the order it draws them.
  List<PhotoChoice> get all => <PhotoChoice>[...bundledPhotos, ...imported];

  /// Whether there is room for another import.
  bool get isFull => imported.length >= maxImportedPhotos;

  /// Returns a copy with the given fields replaced.
  PhotoLibrary copyWith({
    List<PhotoChoice>? imported,
    PhotoChoice? selected,
  }) {
    return PhotoLibrary(
      imported: imported ?? this.imported,
      selected: selected ?? this.selected,
    );
  }

  /// The library as plain JSON types, ready for the store.
  ///
  /// Imports travel as paths and the selection as the kind of thing it is,
  /// since an asset key and a file path are only told apart by the key they
  /// arrive under.
  Map<String, Object?> toJson() {
    final assetKey = selected.assetKey;
    return <String, Object?>{
      'imported': <String>[
        for (final photo in imported) photo.file!.path,
      ],
      'selected': assetKey != null
          ? <String, Object?>{'asset': assetKey}
          : <String, Object?>{'file': selected.file!.path},
    };
  }

  /// The saved selection, if it still points at something on offer.
  static PhotoChoice? _selectedFrom(Object? json, List<PhotoChoice> imported) {
    if (json is! Map<String, Object?>) {
      return null;
    }
    final assetKey = json['asset'];
    if (assetKey is String) {
      for (final photo in bundledPhotos) {
        if (photo.assetKey == assetKey) {
          return photo;
        }
      }
      return null;
    }
    final path = json['file'];
    for (final photo in imported) {
      if (photo.file!.path == path) {
        return photo;
      }
    }
    return null;
  }
}

/// What the photo demo is showing, and everything it could show.
///
/// One notifier for the life of the app, because the picker strip is drawn
/// outside the fold and the picture inside it. They are in different subtrees
/// on purpose: a control inside the filter still responds where it would have
/// been un-tilted, so the strip would drift away from its own hit target as
/// soon as you tilted the phone.
final ValueNotifier<PhotoLibrary> photoLibrary =
    ValueNotifier<PhotoLibrary>(const PhotoLibrary());

bool _watchingLibrary = false;

/// Puts the demo back to the photographs it had last time, and mirrors every
/// change from here on.
///
/// Called once, before the first frame. Awaiting it costs a file read on a
/// launch that is already waiting on the framework, and the alternative is the
/// demo opening on the bundled photograph and swapping under you a moment
/// later.
Future<void> restorePhotoLibrary() async {
  final json = await PlaygroundStore.readJson(PlaygroundStore.photoFile);
  if (json != null) {
    photoLibrary.value = PhotoLibrary.fromJson(json);
  }
  await PlaygroundStore.pruneImports(<String>{
    for (final photo in photoLibrary.value.imported) photo.file!.path,
  });
  if (_watchingLibrary) {
    return;
  }
  _watchingLibrary = true;
  photoLibrary.addListener(() {
    PlaygroundStore.writeJson(
      PlaygroundStore.photoFile,
      photoLibrary.value.toJson(),
    );
  });
}

/// Folds a photograph, edge to edge.
///
/// Photographs are the one thing the painted demos cannot stand in for: real
/// grain, real depth of field and edges that were never drawn by a rasteriser.
class PhotoDemo extends StatelessWidget {
  /// Creates the photo demo.
  const PhotoDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PhotoLibrary>(
      valueListenable: photoLibrary,
      builder: (context, library, _) {
        return SizedBox.expand(child: library.selected.build());
      },
    );
  }
}

/// The strip of photographs over the photo demo.
///
/// Drawn over the fold rather than inside it, so it stays where you tap it.
///
/// Runs along the bottom normally and down the right edge when [axis] is
/// vertical, which is where it goes once the tilt slider has claimed the
/// bottom of the screen.
class PhotoPickerBar extends StatefulWidget {
  /// Creates the strip.
  const PhotoPickerBar({
    super.key,
    this.axis = Axis.horizontal,
    this.onSelectionChanged,
  });

  /// Which way the tiles run.
  final Axis axis;

  /// Called when the photograph on screen changes.
  ///
  /// Fired off the library rather than off the tap handlers, so it covers
  /// every way the picture can change: tapping a tile, importing one, which
  /// selects it, and removing the one being shown, which falls back to the
  /// first bundled photograph.
  final VoidCallback? onSelectionChanged;

  @override
  State<PhotoPickerBar> createState() => _PhotoPickerBarState();
}

class _PhotoPickerBarState extends State<PhotoPickerBar> {
  final ImagePicker _picker = ImagePicker();

  bool _picking = false;

  /// Whether the photographs are on show.
  ///
  /// Closed to start with. The strip sits on top of the very thing it is
  /// choosing, edge to edge and full bleed, so leaving it open by default
  /// would mean the demo always opens with a bar across the picture.
  bool _open = false;

  /// What was on screen last time the library moved, so a change to the
  /// imports alone is not mistaken for a change of picture.
  ///
  /// Assigned in initState rather than at the declaration: a late initialiser
  /// runs on first read, which would be inside the listener below, by which
  /// point the library already holds the new selection and every change reads
  /// as no change at all.
  late PhotoChoice _selected;

  @override
  void initState() {
    super.initState();
    _selected = photoLibrary.value.selected;
    photoLibrary.addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    photoLibrary.removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    final selected = photoLibrary.value.selected;
    if (selected == _selected) {
      return;
    }
    _selected = selected;
    widget.onSelectionChanged?.call();
  }

  Future<void> _pick() async {
    if (_picking) {
      return;
    }
    if (photoLibrary.value.isFull) {
      _say('Holding $maxImportedPhotos photographs already. Remove one first.');
      return;
    }
    setState(() => _picking = true);
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      // Copied into the playground's own directory before the library is
      // pointed at it: the picker hands back a file in a temporary directory
      // that the system is free to empty, so the path it returns outlives the
      // pick by no promise at all.
      final kept = picked == null
          ? null
          : await PlaygroundStore.importPhoto(File(picked.path));
      if (!mounted) {
        return;
      }
      setState(() => _picking = false);
      if (kept == null) {
        return;
      }
      final photo = PhotoChoice.file(kept);
      final library = photoLibrary.value;
      photoLibrary.value = library.copyWith(
        imported: <PhotoChoice>[...library.imported, photo],
        selected: photo,
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _picking = false);
      _say('Could not open the picker: $error');
    }
  }

  /// Drops [photo] from the library and from the disk.
  ///
  /// The library moves first and the file goes afterwards, so nothing is ever
  /// drawing an image out of a file that has already been unlinked. Removing
  /// the picture currently being folded falls back to the first bundled one
  /// rather than to a neighbour, which would depend on where in the strip you
  /// happened to tap.
  Future<void> _remove(PhotoChoice photo) async {
    final library = photoLibrary.value;
    photoLibrary.value = library.copyWith(
      imported: <PhotoChoice>[
        for (final kept in library.imported)
          if (kept != photo) kept,
      ],
      selected: library.selected == photo ? bundledPhotos.first : null,
    );
    // The demo drew this one at full resolution, and that decoded copy is
    // worth handing back rather than leaving in the image cache under a path
    // that no longer resolves. The strip's thumbnail is keyed on a resize
    // around the same file and ages out on its own.
    await FileImage(photo.file!).evict();
    await PlaygroundStore.deletePhoto(photo.file!);
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// The dark lozenge everything in the strip sits on.
  ///
  /// Colours are pinned rather than taken from the theme: this floats over a
  /// full-bleed photograph, and whatever picture is behind it, the controls
  /// have to stay visible. Corner radii still come from the token scale, which
  /// nothing behind the strip can argue with.
  Widget _pill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0x8A000000),
        borderRadius: BorderRadius.all(Radius.circular(FossRadii.full)),
      ),
      child: child,
    );
  }

  /// One square carrying [icon], built like a photograph tile so the controls
  /// and the pictures line up at the same size.
  Widget _iconTile(IconData icon, VoidCallback onTap) {
    return _PhotoTile(
      axis: widget.axis,
      selected: false,
      onTap: onTap,
      child: ColoredBox(
        color: const Color(0x33FFFFFF),
        child: Center(child: Icon(icon, color: Colors.white, size: 22)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_open) {
      // Nothing is read off the library while it is shut, so there is no
      // reason to listen to it either.
      return _pill(
        child: _iconTile(
          Icons.photo_library_outlined,
          () => setState(() => _open = true),
        ),
      );
    }
    return ValueListenableBuilder<PhotoLibrary>(
      valueListenable: photoLibrary,
      builder: (context, library, _) {
        final vertical = widget.axis == Axis.vertical;
        final size = MediaQuery.sizeOf(context);
        return _pill(
          // A full library is nine tiles, which is longer than a phone either
          // way round. The constraint is what gives the scroll view something
          // to scroll inside: the strip is aligned to an edge in a stack, so
          // the measurement across it is pinned but the one along it arrives
          // loose. Lying down, the room left is the screen less the slider's
          // band at the bottom and the notch at the top.
          child: ConstrainedBox(
            constraints: vertical
                ? BoxConstraints(maxHeight: size.height - 220)
                : BoxConstraints(maxWidth: size.width - 48),
            child: SingleChildScrollView(
              scrollDirection: widget.axis,
              child: Flex(
                direction: widget.axis,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // First, so it is under the same finger that opened it.
                  _iconTile(
                    Icons.close,
                    () => setState(() => _open = false),
                  ),
                  for (final photo in library.all)
                    _PhotoTile(
                      axis: widget.axis,
                      selected: photo == library.selected,
                      onTap: () => photoLibrary.value =
                          library.copyWith(selected: photo),
                      onDelete:
                          photo.file == null ? null : () => _remove(photo),
                      child: photo.build(cacheWidth: 160),
                    ),
                  _PhotoTile(
                    axis: widget.axis,
                    selected: false,
                    onTap: _pick,
                    child: ColoredBox(
                      color: const Color(0x33FFFFFF),
                      child: Center(
                        child: _picking
                            ? const FossSpinner(size: 18, color: Colors.white)
                            : Icon(
                                Icons.add_photo_alternate_outlined,
                                // Dimmed rather than dropped when the library
                                // is full: a tile that vanishes at five and
                                // reappears at four reads as a bug, and the
                                // tap explains itself.
                                color: library.isFull
                                    ? const Color(0x66FFFFFF)
                                    : Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One 52pt square in the strip, ringed when it is the one being shown and
/// badged when it is one you can remove.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.axis,
    required this.selected,
    required this.onTap,
    required this.child,
    this.onDelete,
  });

  /// Which way the strip runs, so the gap between tiles falls along it.
  final Axis axis;

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  /// Set on imported photographs, which are the only ones that can go.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final onDelete = this.onDelete;
    return Padding(
      padding: axis == Axis.vertical
          ? const EdgeInsets.symmetric(vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.fossTheme.radii.xl),
            border: Border.all(
              color: selected ? Colors.white : const Color(0x55FFFFFF),
              width: selected ? 2.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (onDelete != null)
                Positioned(
                  top: 0,
                  right: 0,
                  // Inside the tile rather than hanging off its corner: the
                  // tile clips, and the strip has no room to spare besides.
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xCC000000),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
