import 'package:flutter/material.dart';

/// The photographs the demos draw from.
///
/// Every picture in the social and video feeds is a real photograph rather than
/// a generated placeholder. That matters here more than it would in an ordinary
/// mock: the fold is judged on grain, edge detail and depth of field, none of
/// which a gradient has, so a painted stand-in flatters the effect and tells you
/// nothing about how it behaves on real content.
///
/// Named rather than indexed, so a caption can be written about the picture it
/// actually sits under. Credits are in `assets/CREDITS.md`.
abstract final class DemoImages {
  static const _feed = 'assets/feed';

  /// Wide frames, cropped 16:9, for video thumbnails.
  static const String concert = '$_feed/wide_concert.jpg';
  static const String bridge = '$_feed/wide_bridge.jpg';
  static const String cityNight = '$_feed/wide_city_night.jpg';
  static const String traffic = '$_feed/wide_traffic.jpg';
  static const String cliffside = '$_feed/wide_cliffside.jpg';
  static const String palms = '$_feed/wide_palms.jpg';
  static const String table = '$_feed/wide_table.jpg';
  static const String drone = '$_feed/wide_drone.jpg';

  /// Tall frames, cropped 4:5, for feed posts and shorts.
  static const String portraitField = '$_feed/tall_portrait_field.jpg';
  static const String goldenHour = '$_feed/tall_golden_hour.jpg';
  static const String meadow = '$_feed/tall_meadow.jpg';
  static const String berries = '$_feed/tall_berries.jpg';
  static const String blossom = '$_feed/tall_blossom.jpg';
  static const String pier = '$_feed/tall_pier.jpg';
  static const String harbour = '$_feed/tall_harbour.jpg';
  static const String coast = '$_feed/tall_coast.jpg';

  /// Square crops for avatars. Not all of them are faces, which is how profile
  /// pictures actually look.
  static const List<String> avatars = <String>[
    '$_feed/a_photographer.jpg',
    '$_feed/a_field.jpg',
    '$_feed/a_golden.jpg',
    '$_feed/a_cat.jpg',
    '$_feed/a_coffee.jpg',
    '$_feed/a_car.jpg',
    '$_feed/a_berries.jpg',
    '$_feed/a_cactus.jpg',
  ];

  /// The avatar at [index], wrapping.
  static String avatarAt(int index) => avatars[index % avatars.length];
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

  /// Decode width in pixels. Worth setting for anything thumbnail sized.
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
          DemoImages.avatarAt(seed),
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
