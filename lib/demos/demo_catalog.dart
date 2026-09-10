import 'package:flutter/material.dart';

import 'photo_demo.dart';
import 'social_feed_demo.dart';
import 'youtube_demo.dart';

/// One entry in the gallery.
@immutable
class DemoEntry {
  /// Creates an entry.
  const DemoEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
    this.overlayBuilder,
  });

  /// Shown on the gallery card and in the demo's app bar.
  final String title;

  /// One line on why this screen is worth folding.
  final String subtitle;

  /// Leading icon on the gallery card.
  final IconData icon;

  /// Builds the content that goes behind the glass.
  final WidgetBuilder builder;


  /// Optional controls drawn over the fold, at the bottom of the screen.
  ///
  /// Anything interactive belongs here rather than in [builder]. The filter
  /// moves pixels and not hit boxes, so a button inside the fold still responds
  /// where it would have been un-tilted, which reads as broken the moment the
  /// phone leans.
  final WidgetBuilder? overlayBuilder;
}

/// Every demo the gallery offers.
const List<DemoEntry> demoCatalog = <DemoEntry>[
  DemoEntry(
    title: 'Social feed',
    subtitle: 'Stories, photo posts and captions.',
    icon: Icons.photo_library_outlined,
    builder: _buildSocialFeed,
  ),
  DemoEntry(
    title: 'Video feed',
    subtitle: 'Thumbnails, a shorts row and channel rows.',
    icon: Icons.smart_display_outlined,
    builder: _buildYouTube,
  ),
  DemoEntry(
    title: 'Your photo',
    subtitle: 'Three photographs to fold, or one off the device.',
    icon: Icons.add_photo_alternate_outlined,
    builder: _buildPhoto,
    overlayBuilder: _buildPhotoPicker,
  ),
];

Widget _buildSocialFeed(BuildContext context) => const SocialFeedDemo();

Widget _buildYouTube(BuildContext context) => const YouTubeDemo();

Widget _buildPhoto(BuildContext context) => const PhotoDemo();

Widget _buildPhotoPicker(BuildContext context) => const PhotoPickerBar();
