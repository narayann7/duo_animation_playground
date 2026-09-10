import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';
import 'package:image_picker/image_picker.dart';

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

/// The bundled photographs, chosen to cover different kinds of detail: faces
/// and motion blur, a horizon of hard architectural edges, and a wide view
/// with foliage and cloud.
const List<PhotoChoice> bundledPhotos = <PhotoChoice>[
  PhotoChoice.asset('assets/photos/fairground.jpg'),
  PhotoChoice.asset('assets/photos/skyline.jpg'),
  PhotoChoice.asset('assets/photos/riverfront.jpg'),
];

/// The photo the demo is currently showing.
///
/// One notifier for the life of the app, because the picker strip is drawn
/// outside the fold and the picture inside it. They are in different subtrees
/// on purpose: a control inside the filter still responds where it would have
/// been un-tilted, so the strip would drift away from its own hit target as
/// soon as you tilted the phone.
final ValueNotifier<PhotoChoice> photoSelection =
    ValueNotifier<PhotoChoice>(bundledPhotos.first);

/// Folds a photograph, edge to edge.
///
/// Photographs are the one thing the painted demos cannot stand in for: real
/// grain, real depth of field and edges that were never drawn by a rasteriser.
class PhotoDemo extends StatelessWidget {
  /// Creates the photo demo.
  const PhotoDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PhotoChoice>(
      valueListenable: photoSelection,
      builder: (context, choice, _) {
        return SizedBox.expand(child: choice.build());
      },
    );
  }
}

/// The strip of photographs at the bottom of the photo demo.
///
/// Drawn over the fold rather than inside it, so it stays where you tap it.
class PhotoPickerBar extends StatefulWidget {
  /// Creates the strip.
  const PhotoPickerBar({super.key});

  @override
  State<PhotoPickerBar> createState() => _PhotoPickerBarState();
}

class _PhotoPickerBarState extends State<PhotoPickerBar> {
  final ImagePicker _picker = ImagePicker();

  bool _picking = false;

  Future<void> _pick() async {
    if (_picking) {
      return;
    }
    setState(() => _picking = true);
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (!mounted) {
        return;
      }
      setState(() => _picking = false);
      if (picked != null) {
        photoSelection.value = PhotoChoice.file(File(picked.path));
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _picking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the picker: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PhotoChoice>(
      valueListenable: photoSelection,
      builder: (context, choice, _) {
        final picked = choice.file == null ? null : choice;
        // The strip floats over a full-bleed photograph, so its colours are
        // pinned rather than taken from the theme: whatever picture is behind
        // it, the tiles have to stay visible. Corner radii still come from the
        // token scale, which nothing behind the strip can argue with.
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0x8A000000),
            borderRadius: BorderRadius.all(Radius.circular(FossRadii.full)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final photo in bundledPhotos)
                _PhotoTile(
                  selected: photo == choice,
                  onTap: () => photoSelection.value = photo,
                  child: photo.build(cacheWidth: 160),
                ),
              if (picked != null)
                _PhotoTile(
                  selected: true,
                  onTap: _pick,
                  child: picked.build(cacheWidth: 160),
                ),
              _PhotoTile(
                selected: false,
                onTap: _pick,
                child: ColoredBox(
                  color: const Color(0x33FFFFFF),
                  child: Center(
                    child: _picking
                        ? const FossSpinner(size: 18, color: Colors.white)
                        : const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One 52pt square in the strip, ringed when it is the one being shown.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
          child: child,
        ),
      ),
    );
  }
}
