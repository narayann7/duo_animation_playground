import 'package:flutter/material.dart';

import 'dashboard_demo.dart';
import 'photo_demo.dart';
import 'tube_demo.dart';

/// Builds a demo's controls, laid out along [axis].
///
/// Horizontal when the overlay has the bottom of the screen to itself, and
/// vertical once the tilt slider has taken it.
///
/// [onContentChanged] is how a demo says the thing under the glass is now a
/// different thing. The host uses it to put the fold back to flat, so a new
/// subject is seen straight on before it is leaned.
typedef DemoOverlayBuilder = Widget Function(
  BuildContext context, {
  required Axis axis,
  required VoidCallback onContentChanged,
});

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
    this.minShortestSide = 0,
  });

  /// Shown on the gallery card and in the demo's app bar.
  final String title;

  /// One line on why this screen is worth folding.
  final String subtitle;

  /// Leading icon on the gallery card.
  final IconData icon;

  /// Builds the content that goes behind the glass.
  final WidgetBuilder builder;

  /// Optional controls drawn over the fold, at the edge of the screen the
  /// tilt slider is not using.
  ///
  /// Anything interactive belongs here rather than in [builder]. The filter
  /// moves pixels and not hit boxes, so a button inside the fold still responds
  /// where it would have been un-tilted, which reads as broken the moment the
  /// phone leans.
  final DemoOverlayBuilder? overlayBuilder;

  /// The smallest shortest side, in logical pixels, this demo is worth opening
  /// at. Zero means any screen.
  ///
  /// The gallery leaves an entry out rather than offering a row that opens on
  /// something squeezed to nothing. A screen designed around a rail and three
  /// columns has no phone layout to fall back to, and inventing one would be
  /// inventing a second demo.
  final double minShortestSide;

  /// Whether a screen [shortestSide] logical pixels across is big enough.
  bool fitsOn(double shortestSide) => shortestSide >= minShortestSide;
}

/// Every demo the gallery offers.
const List<DemoEntry> demoCatalog = <DemoEntry>[
  DemoEntry(
    title: 'Dashboard',
    subtitle: 'Cards, figures and rules. Phone and tablet layouts.',
    icon: Icons.grid_view_outlined,
    builder: _buildDashboard,
  ),
  DemoEntry(
    title: 'Video site',
    subtitle: 'A masthead, a rail and a grid of thumbnails. Tablet only.',
    icon: Icons.smart_display_outlined,
    builder: _buildTube,
    minShortestSide: TubeDemo.minShortestSide,
  ),
  DemoEntry(
    title: 'Your photo',
    subtitle: 'Three photographs to fold, or one off the device.',
    icon: Icons.add_photo_alternate_outlined,
    builder: _buildPhoto,
    overlayBuilder: _buildPhotoPicker,
  ),
];

Widget _buildDashboard(BuildContext context) => const DashboardDemo();

Widget _buildTube(BuildContext context) => const TubeDemo();

Widget _buildPhoto(BuildContext context) => const PhotoDemo();

Widget _buildPhotoPicker(
  BuildContext context, {
  required Axis axis,
  required VoidCallback onContentChanged,
}) =>
    PhotoPickerBar(axis: axis, onSelectionChanged: onContentChanged);
