import 'package:flutter/material.dart';

/// The photographs the demos draw from.
///
/// Every picture in the social and video feeds is a real photograph rather than
/// a generated placeholder. That matters here more than it would in an ordinary
/// mock: the fold is judged on grain, edge detail and depth of field, none of
/// which a gradient has, so a painted stand-in flatters the effect and tells you
/// nothing about how it behaves on real content.
///
/// The lists below are addressed by index and wrap, so a feed can ask for as
/// many pictures as it likes without running out.
abstract final class DemoImages {
  /// Wide photographs, used where a 16:9 frame is wanted.
  static const List<String> wide = <String>[
    'assets/photos/skyline.jpg',
    'assets/photos/riverfront.jpg',
    'assets/photos/fairground.jpg',
  ];

  /// Photographs that hold up in a tall or square crop.
  static const List<String> tall = <String>[
    'assets/photos/fairground.jpg',
    'assets/photos/riverfront.jpg',
    'assets/photos/skyline.jpg',
  ];

  /// Photographs that read well shrunk to a circle.
  static const List<String> portrait = <String>[
    'assets/photos/fairground.jpg',
    'assets/photos/skyline.jpg',
    'assets/photos/riverfront.jpg',
  ];

  /// The wide photograph at [index], wrapping.
  static String wideAt(int index) => wide[index % wide.length];

  /// The tall photograph at [index], wrapping.
  static String tallAt(int index) => tall[index % tall.length];

  /// The portrait photograph at [index], wrapping.
  static String portraitAt(int index) => portrait[index % portrait.length];
}

/// A photograph in a frame, cropped to fill.
class DemoImage extends StatelessWidget {
  /// Creates a framed photograph.
  const DemoImage({
    super.key,
    required this.assetKey,
    this.borderRadius,
    this.cacheWidth,
    this.alignment = Alignment.center,
  });

  /// Which photograph to draw.
  final String assetKey;

  /// Corner rounding, square by default.
  final BorderRadius? borderRadius;

  /// Decode width in pixels. Worth setting for anything thumbnail sized, since
  /// these are full resolution photographs.
  final int? cacheWidth;

  /// Which part of the photograph survives the crop.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetKey,
      fit: BoxFit.cover,
      alignment: alignment,
      cacheWidth: cacheWidth,
    );
    if (borderRadius == null) {
      return image;
    }
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

/// A circular photographic avatar.
class DemoAvatar extends StatelessWidget {
  /// Creates an avatar.
  const DemoAvatar({
    super.key,
    required this.seed,
    this.size = 40,
    this.ring = false,
  });

  /// Picks which photograph is used, wrapping.
  final int seed;

  /// Diameter in logical pixels, any ring excluded.
  final double size;

  /// True draws the unread story ring around it.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final circle = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          DemoImages.portraitAt(seed),
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
        ),
      ),
    );
    if (!ring) {
      return circle;
    }
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFF9CE34), Color(0xFFEE2A7B), Color(0xFF6228D7)],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: circle,
      ),
    );
  }
}
