import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

import 'demo_images.dart';

/// A video platform's web layout, at tablet size.
///
/// The densest screen in the playground by a distance. A masthead, a rail, a
/// scrolling strip of filter chips, and then a grid of photographs with two
/// lines of small type under each one. Tapping a thumbnail opens the watch
/// page, which swaps the grid for a player, a description, a comment thread and
/// an up-next column.
///
/// That density is the point. The fold is easy to like on one big photograph
/// and hard to like on twelve small ones separated by 16 pixels of background,
/// and this is the second case.
///
/// The layout is the one every video site converged on. What is drawn here
/// rather than taken from fossui is the handful of things that sit on top of a
/// photograph: the duration pill, the live badge, the watched bar and the
/// player's control strip. Those keep fixed colours, because they have to stay
/// readable whatever the thumbnail behind them is doing.
///
/// The brand in the corner is this demo's own. The arrangement is the
/// convention; the mark is not borrowed from anyone.
class TubeDemo extends StatefulWidget {
  /// Creates the demo.
  const TubeDemo({super.key});

  /// Below this shortest side the layout has nowhere to put a rail, a grid and
  /// an up-next column at once, so the gallery does not offer it.
  static const double minShortestSide = 600;

  @override
  State<TubeDemo> createState() => _TubeDemoState();
}

class _TubeDemoState extends State<TubeDemo> {
  _Video? _watching;
  bool _railOpen = true;
  String _chip = _Data.chips.first;
  bool _subscribed = false;
  int _vote = 0;
  bool _playing = true;

  /// Bumped on every change so [_TubeScope] knows to rebuild its dependents
  /// without comparing the state field by field.
  int _revision = 0;

  void _change(VoidCallback apply) => setState(() {
        apply();
        _revision++;
      });

  void open(_Video video) => _change(() {
        _watching = video;
        // A fresh video arrives unsubscribed and unvoted, the way a fresh page
        // load would.
        _subscribed = false;
        _vote = 0;
        _playing = true;
      });

  void back() => _change(() => _watching = null);

  void toggleRail() => _change(() => _railOpen = !_railOpen);

  void setChip(String chip) => _change(() => _chip = chip);

  void toggleSubscribed() => _change(() => _subscribed = !_subscribed);

  void vote(int value) => _change(() => _vote = _vote == value ? 0 : value);

  void togglePlaying() => _change(() => _playing = !_playing);

  _Video? get watching => _watching;
  bool get railOpen => _railOpen;
  String get chip => _chip;
  bool get subscribed => _subscribed;
  int get vote2 => _vote;
  bool get playing => _playing;

  @override
  Widget build(BuildContext context) {
    final colors = context.fossTheme.colors;
    final watching = _watching;
    // The watch page is a view rather than a route, so without this the system
    // back gesture would leave the demo altogether from inside a video. Back
    // means the grid while there is a video open, and only then the host.
    return PopScope(
      canPop: watching == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && watching != null) {
          back();
        }
      },
      child: _TubeScope(
        controller: this,
        revision: _revision,
          child: ColoredBox(
          color: colors.background,
          child: Column(
            children: [
              const _Masthead(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The rail shrinks to icons on the watch page, which is
                    // what every video site does the moment a player needs
                    // the width.
                    _Rail(mini: watching != null || !_railOpen),
                    Expanded(
                      child: watching == null
                          ? const _HomeView()
                          : _WatchView(video: watching),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hands the demo's state down to the controls that read it.
class _TubeScope extends InheritedWidget {
  const _TubeScope({
    required this.controller,
    required this.revision,
    required super.child,
  });

  final _TubeDemoState controller;
  final int revision;

  static _TubeDemoState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_TubeScope>();
    assert(scope != null, 'No _TubeScope above this widget');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(_TubeScope old) => revision != old.revision;
}

// ---------------------------------------------------------------------------
// Fixed colours
// ---------------------------------------------------------------------------

/// The few colours that do not read the theme.
///
/// Each of these sits on top of a photograph rather than on a surface, so it
/// has to stay legible against a thumbnail that could be a snowfield or a night
/// street. The rest of the screen is `FossThemeData` throughout.
abstract final class _Ink {
  /// The brand red. This demo's own mark, not anybody else's.
  static const Color brand = Color(0xFFE0322C);

  /// The scrim a pill sits in, over a photograph.
  static const Color pill = Color(0xCC0F0F0F);

  /// Type and glyphs on top of a photograph.
  static const Color onPhoto = Color(0xFFFFFFFF);

  /// The unwatched part of a progress bar, over a photograph.
  static const Color track = Color(0x66FFFFFF);

  /// The gradient foot under the player controls, so white glyphs survive a
  /// bright frame.
  static const List<Color> playerScrim = <Color>[
    Color(0x00000000),
    Color(0xB3000000),
  ];
}

// ---------------------------------------------------------------------------
// Content
// ---------------------------------------------------------------------------

/// Somebody who posts videos.
@immutable
class _Channel {
  const _Channel({
    required this.name,
    required this.seed,
    required this.subscribers,
    this.verified = true,
  });

  final String name;

  /// Picks the avatar photograph.
  final int seed;

  final String subscribers;
  final bool verified;
}

/// One video, as it appears on a thumbnail and on its own page.
@immutable
class _Video {
  const _Video({
    required this.title,
    required this.channel,
    required this.thumbnail,
    required this.duration,
    required this.views,
    required this.age,
    this.live = false,
    this.watched = 0,
    this.description = '',
  });

  final String title;
  final _Channel channel;
  final String thumbnail;

  /// Shown in the pill on the thumbnail. Ignored when [live].
  final String duration;

  final String views;
  final String age;

  /// True swaps the duration pill for a live badge and the view count for a
  /// watching count.
  final bool live;

  /// How much of it has been watched, 0 to 1. Anything above zero draws the red
  /// bar along the bottom of the thumbnail.
  final double watched;

  final String description;

  /// The line under the title: views and either an age or a live marker.
  String get byline => live ? '$views watching now' : '$views views · $age';
}

/// One comment under a video.
@immutable
class _Comment {
  const _Comment({
    required this.author,
    required this.seed,
    required this.when,
    required this.body,
    required this.likes,
    this.replies = 0,
    this.pinned = false,
  });

  final String author;
  final int seed;
  final String when;
  final String body;
  final String likes;
  final int replies;
  final bool pinned;
}

/// Where the thumbnails live. One file per video.
abstract final class _Thumbs {
  static const String _dir = 'assets/tube';

  static const String fjord = '$_dir/fjord.jpg';
  static const String desert = '$_dir/desert.jpg';
  static const String ridge = '$_dir/ridge.jpg';
  static const String storm = '$_dir/storm.jpg';
  static const String camp = '$_dir/camp.jpg';
  static const String waterfall = '$_dir/waterfall.jpg';
  static const String valley = '$_dir/valley.jpg';
  static const String river = '$_dir/river.jpg';
  static const String alley = '$_dir/alley.jpg';
  static const String surf = '$_dir/surf.jpg';
  static const String workshop = '$_dir/workshop.jpg';
  static const String coast = '$_dir/coast.jpg';
  static const String skyline = '$_dir/skyline.jpg';
  static const String lioness = '$_dir/lioness.jpg';
  static const String strawberries = '$_dir/strawberries.jpg';
  static const String canal = '$_dir/canal.jpg';
  static const String desk = '$_dir/desk.jpg';
  static const String barn = '$_dir/barn.jpg';
  static const String teapot = '$_dir/teapot.jpg';
  static const String neon = '$_dir/neon.jpg';
}

/// Everything on the screen. Written out rather than generated: the fold is
/// judged on real ragged type, and a repeated placeholder title sets every line
/// break in the grid to the same place.
abstract final class _Data {
  static const _Channel northbound =
      _Channel(name: 'Northbound', seed: 0, subscribers: '1.24M');
  static const _Channel fieldNotes =
      _Channel(name: 'Field Notes', seed: 1, subscribers: '806K');
  static const _Channel slowKitchen =
      _Channel(name: 'The Slow Kitchen', seed: 4, subscribers: '2.1M');
  static const _Channel atlas =
      _Channel(name: 'Atlas & Ember', seed: 2, subscribers: '3.9M');
  static const _Channel workshopHours = _Channel(
    name: 'Workshop Hours',
    seed: 5,
    subscribers: '412K',
    verified: false,
  );
  static const _Channel lowTide =
      _Channel(name: 'Low Tide Radio', seed: 7, subscribers: '188K');
  static const _Channel cartographers =
      _Channel(name: 'Cartographers', seed: 3, subscribers: '954K');
  static const _Channel nightShift =
      _Channel(name: 'Night Shift', seed: 6, subscribers: '1.7M');

  static const List<_Channel> subscriptions = <_Channel>[
    northbound,
    fieldNotes,
    slowKitchen,
    atlas,
    workshopHours,
    lowTide,
    cartographers,
    nightShift,
  ];

  static const List<_Video> videos = <_Video>[
    _Video(
      title: 'Four days on the fjord rim with everything on my back',
      channel: northbound,
      thumbnail: _Thumbs.fjord,
      duration: '18:42',
      views: '412K',
      age: '3 days ago',
      watched: 0.62,
      description:
          'No resupply, no bail-out road, and one weather window that closed a '
          'day early. The route, the pack weight, and the two things I would '
          'leave behind next time.',
    ),
    _Video(
      title: 'The red rock loop that everybody starts from the wrong end',
      channel: atlas,
      thumbnail: _Thumbs.desert,
      duration: '24:07',
      views: '1.1M',
      age: '1 week ago',
    ),
    _Video(
      title: 'Driving the ridge road before sunrise',
      channel: northbound,
      thumbnail: _Thumbs.ridge,
      duration: '12:55',
      views: '806K',
      age: '5 days ago',
      watched: 0.18,
    ),
    _Video(
      title: 'A squall line coming in off the water, uncut',
      channel: fieldNotes,
      thumbnail: _Thumbs.storm,
      duration: '',
      views: '3.2K',
      age: '',
      live: true,
    ),
    _Video(
      title: 'Winter camp at minus eighteen: what actually kept us warm',
      channel: atlas,
      thumbnail: _Thumbs.camp,
      duration: '31:20',
      views: '2.4M',
      age: '2 weeks ago',
    ),
    _Video(
      title: 'Finding the waterfall that is not on any map',
      channel: cartographers,
      thumbnail: _Thumbs.waterfall,
      duration: '15:38',
      views: '224K',
      age: '1 day ago',
    ),
    _Video(
      title: 'A week in the valley with one lens',
      channel: fieldNotes,
      thumbnail: _Thumbs.valley,
      duration: '22:14',
      views: '559K',
      age: '4 days ago',
      watched: 0.91,
    ),
    _Video(
      title: 'Cold water, long exposure, one figure on the stones',
      channel: fieldNotes,
      thumbnail: _Thumbs.river,
      duration: '9:41',
      views: '98K',
      age: '6 days ago',
    ),
    _Video(
      title: 'The back streets nobody photographs',
      channel: nightShift,
      thumbnail: _Thumbs.alley,
      duration: '14:02',
      views: '331K',
      age: '2 days ago',
    ),
    _Video(
      title: 'Six hours of open water, from two hundred feet up',
      channel: lowTide,
      thumbnail: _Thumbs.surf,
      duration: '4:12:09',
      views: '1.8M',
      age: '1 month ago',
      watched: 0.07,
    ),
    _Video(
      title: 'Rebuilding the shop from the floor up',
      channel: workshopHours,
      thumbnail: _Thumbs.workshop,
      duration: '41:55',
      views: '672K',
      age: '1 week ago',
    ),
    _Video(
      title: 'Why this coastline is a mile shorter than it was',
      channel: cartographers,
      thumbnail: _Thumbs.coast,
      duration: '19:27',
      views: '945K',
      age: '3 weeks ago',
    ),
    _Video(
      title: 'Every rooftop in the city, one evening',
      channel: nightShift,
      thumbnail: _Thumbs.skyline,
      duration: '27:33',
      views: '2.1M',
      age: '2 months ago',
      watched: 0.44,
    ),
    _Video(
      title: 'Eleven days of waiting for one look',
      channel: fieldNotes,
      thumbnail: _Thumbs.lioness,
      duration: '33:48',
      views: '4.6M',
      age: '5 months ago',
    ),
    _Video(
      title: 'The only strawberry recipe worth the washing up',
      channel: slowKitchen,
      thumbnail: _Thumbs.strawberries,
      duration: '11:19',
      views: '1.3M',
      age: '1 week ago',
    ),
    _Video(
      title: 'The canal houses in the hour before the crowds',
      channel: northbound,
      thumbnail: _Thumbs.canal,
      duration: '16:44',
      views: '487K',
      age: '4 days ago',
    ),
    _Video(
      title: 'How I actually plan a six month trip',
      channel: atlas,
      thumbnail: _Thumbs.desk,
      duration: '20:03',
      views: '288K',
      age: '1 week ago',
      watched: 0.33,
    ),
    _Video(
      title: 'Golden hour on the old Hoffmann place',
      channel: cartographers,
      thumbnail: _Thumbs.barn,
      duration: '8:56',
      views: '156K',
      age: '2 days ago',
    ),
    _Video(
      title: 'A pot of tea, properly, in nine minutes',
      channel: slowKitchen,
      thumbnail: _Thumbs.teapot,
      duration: '9:12',
      views: '723K',
      age: '3 weeks ago',
    ),
    _Video(
      title: 'The neon quarter at three in the morning',
      channel: nightShift,
      thumbnail: _Thumbs.neon,
      duration: '25:41',
      views: '3.4M',
      age: '1 month ago',
      watched: 0.76,
    ),
  ];

  static const List<String> chips = <String>[
    'All',
    'Live',
    'Hiking',
    'Cooking',
    'Travel',
    'Photography',
    'Podcasts',
    'Documentary',
    'Recently uploaded',
    'Watched',
    'New to you',
  ];

  static const List<(IconData, String)> primaryNav = <(IconData, String)>[
    (Icons.home_outlined, 'Home'),
    (Icons.bolt_outlined, 'Shorts'),
    (Icons.subscriptions_outlined, 'Subscriptions'),
  ];

  static const List<(IconData, String)> youNav = <(IconData, String)>[
    (Icons.history_outlined, 'History'),
    (Icons.playlist_play_outlined, 'Playlists'),
    (Icons.smart_display_outlined, 'Your videos'),
    (Icons.watch_later_outlined, 'Watch later'),
    (Icons.thumb_up_outlined, 'Liked videos'),
  ];

  static const List<(IconData, String)> exploreNav = <(IconData, String)>[
    (Icons.local_fire_department_outlined, 'Trending'),
    (Icons.library_music_outlined, 'Music'),
    (Icons.sports_esports_outlined, 'Gaming'),
    (Icons.newspaper_outlined, 'News'),
    (Icons.emoji_events_outlined, 'Sport'),
    (Icons.school_outlined, 'Learning'),
  ];

  static const List<String> footerLinks = <String>[
    'About',
    'Press',
    'Copyright',
    'Contact',
    'Creators',
    'Advertise',
    'Developers',
    'Terms',
    'Privacy',
    'Policy & Safety',
  ];

  static const List<_Comment> comments = <_Comment>[
    _Comment(
      author: 'Hanne Vold',
      seed: 2,
      when: '2 days ago',
      body: 'The bit at fourteen minutes where you stop talking for a full '
          'minute and let the wind do it is the best thing on this channel.',
      likes: '4.1K',
      replies: 38,
      pinned: true,
    ),
    _Comment(
      author: 'Marcus Oduya',
      seed: 5,
      when: '2 days ago',
      body: 'Carried almost this exact kit last autumn and the one thing I '
          'would add is a second pair of liner gloves. Wet liners end a day.',
      likes: '892',
      replies: 12,
    ),
    _Comment(
      author: 'Priya Nair',
      seed: 1,
      when: '1 day ago',
      body: 'Please do a proper pack breakdown. Weight, not brands.',
      likes: '511',
      replies: 4,
    ),
    _Comment(
      author: 'Tomas Bauer',
      seed: 6,
      when: '22 hours ago',
      body: 'Did the same route in June and it is a completely different walk '
          'with the snow off it. Worth saying for anyone planning.',
      likes: '267',
    ),
    _Comment(
      author: 'Ada Cardoso',
      seed: 3,
      when: '14 hours ago',
      body: 'Nine hundred metres of ascent before breakfast is a choice.',
      likes: '134',
      replies: 2,
    ),
  ];
}

// ---------------------------------------------------------------------------
// Chrome
// ---------------------------------------------------------------------------

/// The bar across the top: the rail toggle and the mark, the search field, and
/// the account side.
class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final tube = _TubeScope.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          _GhostIcon(
            icon: Icons.menu,
            label: 'Menu',
            onPressed: tube.toggleRail,
          ),
          const SizedBox(width: 8),
          const _BrandMark(),
          // Three zones, the middle one flexible. The search field is capped
          // rather than greedy, since left to fill a 13 inch tablet it would
          // run to 900 pixels, and it has to be able to shrink below the cap
          // rather than demand it on an 11 inch one.
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: const _SearchBar(),
                  ),
                ),
                const SizedBox(width: 8),
                const _GhostIcon(
                  icon: Icons.mic_none_outlined,
                  label: 'Search by voice',
                ),
              ],
            ),
          ),
          const _GhostIcon(icon: Icons.video_call_outlined, label: 'Create'),
          const SizedBox(width: 2),
          const _NotificationBell(),
          const SizedBox(width: 10),
          const DemoAvatar(seed: 4, size: FossAvatarSize.md),
        ],
      ),
    );
  }
}

/// The mark in the corner. A rounded tile with a play glyph in it, and a
/// wordmark beside it.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 21,
          decoration: BoxDecoration(
            color: _Ink.brand,
            borderRadius: BorderRadius.circular(theme.radii.sm),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.play_arrow_rounded,
            size: 17,
            color: _Ink.onPhoto,
          ),
        ),
        const SizedBox(width: 6),
        const FossText(
          'Playhouse',
          size: FossTextSize.lg,
          weight: FossTextWeight.semibold,
        ),
        const SizedBox(width: 3),
        // The country code every video site wears next to its wordmark.
        FossText.caption('UK', color: FossTextColor.mutedForeground),
      ],
    );
  }
}

/// The pill-shaped search field with its own submit button.
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.fossTheme.colors;
    return Row(
      children: [
        Expanded(
          child: FossTextField(
            size: FossTextFieldSize.sm,
            hintText: 'Search',
            leading: Icon(
              Icons.search,
              size: 17,
              color: colors.mutedForeground,
            ),
          ),
        ),
        const SizedBox(width: 6),
        FossButton.icon(
          variant: FossButtonVariant.secondary,
          size: FossButtonSize.sm,
          semanticLabel: 'Search',
          onPressed: _noop,
          icon: const Icon(Icons.search, size: 17),
        ),
      ],
    );
  }
}

/// The bell, with the number of things waiting behind it.
class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const _GhostIcon(
          icon: Icons.notifications_none_outlined,
          label: 'Notifications',
        ),
        Positioned(
          right: 2,
          top: 2,
          child: IgnorePointer(
            child: FossBadge(
              variant: FossBadgeVariant.destructive,
              size: FossBadgeSize.sm,
              label: const Text('9+'),
            ),
          ),
        ),
      ],
    );
  }
}

/// A round, quiet icon button. The masthead and the player are full of them.
class _GhostIcon extends StatelessWidget {
  const _GhostIcon({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FossButton.icon(
      variant: FossButtonVariant.ghost,
      size: FossButtonSize.sm,
      semanticLabel: label,
      onPressed: onPressed ?? _noop,
      icon: Icon(icon, size: 20),
    );
  }
}

// ---------------------------------------------------------------------------
// Rail
// ---------------------------------------------------------------------------

/// The side rail, either full width with section headings or squeezed down to
/// a column of icons.
class _Rail extends StatelessWidget {
  const _Rail({required this.mini});

  /// True draws the icons-only rail the watch page uses.
  final bool mini;

  @override
  Widget build(BuildContext context) {
    final colors = context.fossTheme.colors;
    return Container(
      width: mini ? 76 : 232,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: mini ? const _MiniRail() : const _FullRail(),
    );
  }
}

/// The icons-only rail: the first four destinations, nothing else.
class _MiniRail extends StatelessWidget {
  const _MiniRail();

  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String)>[
      (Icons.home_outlined, 'Home'),
      (Icons.bolt_outlined, 'Shorts'),
      (Icons.subscriptions_outlined, 'Subscriptions'),
      (Icons.video_library_outlined, 'You'),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final (icon, label) in items)
          _MiniRailItem(icon: icon, label: label, selected: label == 'Home'),
      ],
    );
  }
}

class _MiniRailItem extends StatelessWidget {
  const _MiniRailItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: selected ? colors.muted : null,
          borderRadius: BorderRadius.circular(theme.radii.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: colors.foreground),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.xs.copyWith(color: colors.foreground),
            ),
          ],
        ),
      ),
    );
  }
}

/// The full rail: destinations, the subscription list, and the small print
/// every video site puts at the bottom of it.
class _FullRail extends StatelessWidget {
  const _FullRail();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
      children: [
        for (final (icon, label) in _Data.primaryNav)
          _RailItem(icon: icon, label: label, selected: label == 'Home'),
        const _RailDivider(),
        const _RailHeading('You', trailing: Icons.chevron_right),
        for (final (icon, label) in _Data.youNav)
          _RailItem(icon: icon, label: label),
        const _RailDivider(),
        const _RailHeading('Subscriptions'),
        for (final channel in _Data.subscriptions)
          _RailChannel(channel: channel),
        const _RailDivider(),
        const _RailHeading('Explore'),
        for (final (icon, label) in _Data.exploreNav)
          _RailItem(icon: icon, label: label),
        const _RailDivider(),
        const _RailFooter(),
      ],
    );
  }
}

class _RailDivider extends StatelessWidget {
  const _RailDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: FossSeparator(),
    );
  }
}

class _RailHeading extends StatelessWidget {
  const _RailHeading(this.label, {this.trailing});

  final String label;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 8, 8),
      child: Row(
        children: [
          FossText.label(label),
          if (trailing case final trailing?) ...[
            const SizedBox(width: 4),
            Icon(trailing, size: 16),
          ],
        ],
      ),
    );
  }
}

/// One destination in the full rail.
class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return FossListTile(
      variant:
          selected ? FossListTileVariant.filled : FossListTileVariant.plain,
      leading: Icon(icon, size: 20),
      title: selected
          ? FossText.label(label, maxLines: 1, overflow: TextOverflow.ellipsis)
          : FossText.body(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: _noop,
    );
  }
}

/// One subscription: an avatar, a name, and a dot if they are on air.
class _RailChannel extends StatelessWidget {
  const _RailChannel({required this.channel});

  final _Channel channel;

  @override
  Widget build(BuildContext context) {
    final live = channel == _Data.fieldNotes;
    return FossListTile(
      variant: FossListTileVariant.plain,
      leading: DemoAvatar(seed: channel.seed, size: FossAvatarSize.xs),
      title: FossText.body(
        channel.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: live
          ? const _LiveDot()
          : const Icon(Icons.circle_outlined, size: 0),
      onTap: _noop,
    );
  }
}

/// The red dot beside a channel that is broadcasting.
class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: _Ink.brand,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// The wrapped small print at the foot of the rail.
class _RailFooter extends StatelessWidget {
  const _RailFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final link in _Data.footerLinks)
                FossText.caption(link, color: FossTextColor.mutedForeground),
            ],
          ),
          const SizedBox(height: 12),
          FossText.caption(
            '© 2026 Playhouse',
            color: FossTextColor.mutedForeground,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

/// The chip strip pinned over a scrolling grid.
class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ChipBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: const [
              _VideoGrid(from: 0, count: 8),
              SizedBox(height: 24),
              _ShortsShelf(),
              SizedBox(height: 24),
              _VideoGrid(from: 8, count: 12),
            ],
          ),
        ),
      ],
    );
  }
}

/// The horizontally scrolling row of filters. Live: the selected chip is real
/// state, even though nothing filters behind it.
class _ChipBar extends StatelessWidget {
  const _ChipBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.fossTheme.colors;
    final tube = _TubeScope.of(context);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: _Data.chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = _Data.chips[index];
          return FossChip(
            label: Text(chip),
            selected: chip == tube.chip,
            onSelected: (_) => tube.setChip(chip),
          );
        },
      ),
    );
  }
}

/// A block of the grid, as many across as the width allows.
class _VideoGrid extends StatelessWidget {
  const _VideoGrid({required this.from, required this.count});

  /// Index of the first video in [_Data.videos] this block draws.
  final int from;

  /// How many it draws.
  final int count;

  /// The narrowest a tile goes before a column is dropped. Under this the
  /// two-line title stops holding a sensible number of words.
  static const double _minTileWidth = 216;

  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    final videos = _Data.videos.skip(from).take(count).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final fits =
            (constraints.maxWidth + _gap) ~/ (_minTileWidth + _gap);
        final columns = fits.clamp(2, 4);
        final width =
            (constraints.maxWidth - _gap * (columns - 1)) / columns;
        return Wrap(
          spacing: _gap,
          runSpacing: 28,
          children: [
            for (final video in videos)
              SizedBox(width: width, child: _VideoTile(video: video)),
          ],
        );
      },
    );
  }
}

/// One video in the grid: thumbnail, avatar, two lines of title, two lines of
/// metadata and an overflow glyph.
class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video});

  final _Video video;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final tube = _TubeScope.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => tube.open(video),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumbnail(video: video, radius: theme.radii.xl),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DemoAvatar(seed: video.channel.seed, size: FossAvatarSize.md),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.sm.medium.copyWith(
                        color: colors.foreground,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _ChannelLine(channel: video.channel),
                    const SizedBox(height: 1),
                    Text(
                      video.byline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.xs
                          .copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.more_vert,
                size: 17,
                color: colors.mutedForeground,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A channel's name with its tick, wherever one is needed.
class _ChannelLine extends StatelessWidget {
  const _ChannelLine({required this.channel, this.bold = false});

  final _Channel channel;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final style = (bold ? theme.typography.sm.medium : theme.typography.xs)
        .copyWith(color: colors.mutedForeground);
    return Row(
      children: [
        Flexible(
          child: Text(
            channel.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (channel.verified) ...[
          const SizedBox(width: 4),
          Icon(Icons.check_circle, size: 13, color: colors.mutedForeground),
        ],
      ],
    );
  }
}

/// The photograph, with everything that sits on top of it.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.video,
    required this.radius,
  });

  final _Video video;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(video.thumbnail, fit: BoxFit.cover),
            Positioned(
              right: 6,
              bottom: video.watched > 0 ? 10 : 6,
              child: video.live
                  ? const _LiveBadge()
                  : _DurationPill(duration: video.duration),
            ),
            if (video.watched > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _WatchedBar(fraction: video.watched),
              ),
          ],
        ),
      ),
    );
  }
}

/// The runtime, bottom right of a thumbnail.
class _DurationPill extends StatelessWidget {
  const _DurationPill({required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _Ink.pill,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          duration,
          style: context.fossTheme.typography.xs.medium
              .copyWith(color: _Ink.onPhoto, height: 1.3),
        ),
      ),
    );
  }
}

/// The badge a broadcast wears instead of a runtime.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _Ink.brand,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sensors, size: 11, color: _Ink.onPhoto),
            const SizedBox(width: 3),
            Text(
              'LIVE',
              style: context.fossTheme.typography.xs.medium
                  .copyWith(color: _Ink.onPhoto, height: 1.3, letterSpacing: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// The red line along the foot of a thumbnail you have already started.
class _WatchedBar extends StatelessWidget {
  const _WatchedBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: Stack(
        children: [
          const ColoredBox(color: _Ink.track, child: SizedBox.expand()),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0.0, 1.0),
            child: const ColoredBox(color: _Ink.brand),
          ),
        ],
      ),
    );
  }
}

/// The row of tall thumbnails every video site drops into the middle of the
/// grid.
class _ShortsShelf extends StatelessWidget {
  const _ShortsShelf();

  static const List<int> _picks = <int>[13, 14, 18, 9, 5, 17, 11];

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, size: 22, color: _Ink.brand),
            const SizedBox(width: 6),
            const FossText.title('Shorts'),
            const Spacer(),
            FossButton(
              variant: FossButtonVariant.ghost,
              size: FossButtonSize.sm,
              onPressed: _noop,
              trailing: const Icon(Icons.chevron_right, size: 16),
              child: const Text('Show all'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: _picks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final video = _Data.videos[_picks[index]];
              return SizedBox(
                width: 146,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(theme.radii.lg),
                        child: Image.asset(
                          video.thumbnail,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.xs.medium
                          .copyWith(color: colors.foreground, height: 1.3),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${video.views} views',
                      style: theme.typography.xs
                          .copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Watch
// ---------------------------------------------------------------------------

/// The player and everything under it, with an up-next column beside it if
/// there is room.
class _WatchView extends StatelessWidget {
  const _WatchView({required this.video});

  final _Video video;

  /// Under this the up-next column drops below the description instead of
  /// sitting beside it, which is what a video site does on a narrow window.
  static const double _twoColumnWidth = 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= _twoColumnWidth;
        final main = ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          children: [
            _Player(video: video),
            const SizedBox(height: 16),
            _WatchHeading(video: video),
            const SizedBox(height: 12),
            _DescriptionBox(video: video),
            if (!sideBySide) ...[
              const SizedBox(height: 20),
              const _UpNext(),
            ],
            const SizedBox(height: 24),
            const _Comments(),
          ],
        );

        if (!sideBySide) {
          return main;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: main),
            SizedBox(
              width: 372,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 20, 24, 40),
                children: const [_UpNext()],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The player: a frame with a scrim, a big centre button and a control strip.
class _Player extends StatelessWidget {
  const _Player({required this.video});

  final _Video video;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final tube = _TubeScope.of(context);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.radii.xl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(video.thumbnail, fit: BoxFit.cover),
            // The scrim only covers the bottom third. A full-frame wash would
            // flatten the photograph, and the photograph is what the fold has
            // to work on.
            const Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 0.42,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _Ink.playerScrim,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.12),
              child: GestureDetector(
                onTap: tube.togglePlaying,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: _Ink.pill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tube.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 34,
                    color: _Ink.onPhoto,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _PlayerControls(video: video),
            ),
            Positioned(
              left: 14,
              top: 12,
              child: Row(
                children: [
                  const Icon(Icons.hd_outlined, size: 18, color: _Ink.onPhoto),
                  const SizedBox(width: 8),
                  Text(
                    video.channel.name,
                    style: theme.typography.xs.medium
                        .copyWith(color: _Ink.onPhoto),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The strip along the bottom of the player: scrubber, then the two rows of
/// glyphs every player has.
class _PlayerControls extends StatelessWidget {
  const _PlayerControls({required this.video});

  final _Video video;

  /// How far through it is. Written down rather than ticking, because a
  /// repainting scrubber under the fold would be measuring the wrong thing.
  static const double _progress = 0.34;

  /// How much has loaded ahead of the playhead.
  static const double _buffered = 0.52;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final tube = _TubeScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Scrubber(progress: _progress, buffered: _buffered),
          const SizedBox(height: 6),
          Row(
            children: [
              _PlayerIcon(
                icon: tube.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                label: 'Play',
                onPressed: tube.togglePlaying,
              ),
              const _PlayerIcon(icon: Icons.skip_next_rounded, label: 'Next'),
              const _PlayerIcon(icon: Icons.volume_up_rounded, label: 'Volume'),
              const SizedBox(width: 4),
              const _VolumeStub(),
              const SizedBox(width: 10),
              Text(
                '6:21 / ${video.duration}',
                style: theme.typography.xs.medium
                    .copyWith(color: _Ink.onPhoto),
              ),
              const Spacer(),
              const _PlayerIcon(
                icon: Icons.closed_caption_outlined,
                label: 'Subtitles',
              ),
              const _PlayerIcon(
                icon: Icons.settings_outlined,
                label: 'Settings',
              ),
              const _PlayerIcon(
                icon: Icons.branding_watermark_outlined,
                label: 'Miniplayer',
              ),
              const _PlayerIcon(
                icon: Icons.crop_16_9_outlined,
                label: 'Theatre mode',
              ),
              const _PlayerIcon(
                icon: Icons.fullscreen_rounded,
                label: 'Full screen',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The scrubbed line: watched, buffered, and the knob.
class _Scrubber extends StatelessWidget {
  const _Scrubber({required this.progress, required this.buffered});

  final double progress;
  final double buffered;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(height: 3, color: _Ink.track),
              Container(height: 3, width: width * buffered, color: _Ink.track),
              Container(height: 3, width: width * progress, color: _Ink.brand),
              Positioned(
                left: width * progress - 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: _Ink.brand,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The stub of a volume slider that appears beside the speaker glyph.
class _VolumeStub extends StatelessWidget {
  const _VolumeStub();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 12,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(height: 3, color: _Ink.track),
          Container(height: 3, width: 40, color: _Ink.onPhoto),
          Positioned(
            left: 34,
            child: Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                color: _Ink.onPhoto,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A glyph on the player strip. White rather than themed, since it is on a
/// photograph.
class _PlayerIcon extends StatelessWidget {
  const _PlayerIcon({required this.icon, required this.label, this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed ?? _noop,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          child: Icon(icon, size: 21, color: _Ink.onPhoto),
        ),
      ),
    );
  }
}

/// Title, then the channel on the left and the action pills on the right.
class _WatchHeading extends StatelessWidget {
  const _WatchHeading({required this.video});

  final _Video video;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final tube = _TubeScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 6),
              child: _GhostIcon(
                icon: Icons.arrow_back,
                label: 'Back to the grid',
                onPressed: tube.back,
              ),
            ),
            Expanded(
              child: Text(
                video.title,
                style: theme.typography.xl.semibold
                    .copyWith(color: colors.foreground, height: 1.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // The subscribe block and the action pills share a line when there is
        // room and stack when there is not. Both halves are given a bounded
        // width either way: handed an unbounded one they size to their content
        // and the channel name has nothing to ellipsise against.
        LayoutBuilder(
          builder: (context, constraints) {
            final channel = _ChannelBlock(video: video);
            const actions = _WatchActions();
            if (constraints.maxWidth < _sideBySideActions) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  channel,
                  const SizedBox(height: 14),
                  actions,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: channel),
                const SizedBox(width: 12),
                const Flexible(child: actions),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Under this the channel block and the action pills stop sharing a line.
  static const double _sideBySideActions = 660;
}

/// Avatar, name, subscriber count and the subscribe button.
class _ChannelBlock extends StatelessWidget {
  const _ChannelBlock({required this.video});

  final _Video video;

  @override
  Widget build(BuildContext context) {
    final tube = _TubeScope.of(context);
    final subscribed = tube.subscribed;
    return Row(
      children: [
        DemoAvatar(seed: video.channel.seed, size: FossAvatarSize.xl2),
        const SizedBox(width: 12),
        // Expanded rather than sized to content: a long channel name should
        // push the subscribe button off the end of nothing.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ChannelLine(channel: video.channel, bold: true),
              FossText.caption(
                '${video.channel.subscribers} subscribers',
                color: FossTextColor.mutedForeground,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        FossButton(
          variant: subscribed
              ? FossButtonVariant.secondary
              : FossButtonVariant.primary,
          size: FossButtonSize.sm,
          onPressed: tube.toggleSubscribed,
          leading: subscribed
              ? const Icon(Icons.notifications_active_outlined, size: 15)
              : null,
          child: Text(subscribed ? 'Subscribed' : 'Subscribe'),
        ),
      ],
    );
  }
}

/// The pills to the right of the channel: the split vote, then the rest.
class _WatchActions extends StatelessWidget {
  const _WatchActions();

  @override
  Widget build(BuildContext context) {
    final tube = _TubeScope.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _VotePill(vote: tube.vote2, onVote: tube.vote),
        const _ActionPill(icon: Icons.reply_outlined, label: 'Share'),
        const _ActionPill(icon: Icons.download_outlined, label: 'Download'),
        const _ActionPill(icon: Icons.content_cut, label: 'Clip'),
        const _ActionPill(icon: Icons.playlist_add, label: 'Save'),
        FossButton.icon(
          variant: FossButtonVariant.secondary,
          size: FossButtonSize.sm,
          semanticLabel: 'More actions',
          onPressed: _noop,
          icon: const Icon(Icons.more_horiz, size: 17),
        ),
      ],
    );
  }
}

/// Like and dislike, joined, with a rule between them.
class _VotePill extends StatelessWidget {
  const _VotePill({required this.vote, required this.onVote});

  /// 1 liked, -1 disliked, 0 neither.
  final int vote;
  final ValueChanged<int> onVote;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(FossRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _VoteHalf(
            icon: vote == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
            label: '18K',
            semantics: 'Like',
            onTap: () => onVote(1),
          ),
          Container(width: 1, height: 18, color: colors.border),
          _VoteHalf(
            icon: vote == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
            semantics: 'Dislike',
            onTap: () => onVote(-1),
          ),
        ],
      ),
    );
  }
}

class _VoteHalf extends StatelessWidget {
  const _VoteHalf({
    required this.icon,
    required this.semantics,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final String semantics;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    // The count is folded into the label and the inner text excluded, rather
    // than left to merge: a half that announced 'Like' and '18K' as two nodes
    // reads as two controls to a screen reader, and there is only one.
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: label == null ? semantics : '$semantics, $label',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: colors.secondaryForeground),
              if (label case final label?) ...[
                const SizedBox(width: 7),
                Text(
                  label,
                  style: theme.typography.sm.medium
                      .copyWith(color: colors.secondaryForeground),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the grey pills beside the vote.
class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FossButton(
      variant: FossButtonVariant.secondary,
      size: FossButtonSize.sm,
      onPressed: _noop,
      leading: Icon(icon, size: 16),
      child: Text(label),
    );
  }
}

/// The grey block under the player: the counts, then the text.
class _DescriptionBox extends StatelessWidget {
  const _DescriptionBox({required this.video});

  final _Video video;

  static const String _fallback =
      'Shot over nine days. Full route notes, the gear list with weights, and '
      'the two river crossings that are worse than they look are all in the '
      'pinned comment.';

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final body = video.description.isEmpty ? _fallback : video.description;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(theme.radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FossText.label('${video.views} views'),
              const SizedBox(width: 10),
              FossText.label(video.live ? 'Live now' : video.age),
              const SizedBox(width: 10),
              Flexible(
                child: FossText.label(
                  '#fieldwork #longwalk #nofilter',
                  color: FossTextColor.primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.typography.sm.copyWith(
              color: colors.foreground,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          FossText.label('Show more'),
        ],
      ),
    );
  }
}

/// The comment thread: a count, a sort control, a box to write in, then the
/// comments.
class _Comments extends StatelessWidget {
  const _Comments();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const FossText.title('1,284 Comments'),
            const SizedBox(width: 20),
            FossButton(
              variant: FossButtonVariant.ghost,
              size: FossButtonSize.sm,
              onPressed: _noop,
              leading: const Icon(Icons.sort, size: 16),
              child: const Text('Sort by'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _CommentComposer(),
        const SizedBox(height: 20),
        for (final comment in _Data.comments)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _CommentRow(comment: comment),
          ),
      ],
    );
  }
}

/// The line you would type into, and the two buttons under it.
class _CommentComposer extends StatelessWidget {
  const _CommentComposer();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DemoAvatar(seed: 4, size: FossAvatarSize.lg),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const FossTextField(
                size: FossTextFieldSize.sm,
                hintText: 'Add a comment',
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FossButton(
                    variant: FossButtonVariant.ghost,
                    size: FossButtonSize.sm,
                    onPressed: _noop,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FossButton(
                    size: FossButtonSize.sm,
                    onPressed: _noop,
                    child: const Text('Comment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One comment.
class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});

  final _Comment comment;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DemoAvatar(seed: comment.seed, size: FossAvatarSize.lg),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (comment.pinned) ...[
                Row(
                  children: [
                    Icon(
                      Icons.push_pin_outlined,
                      size: 13,
                      color: colors.mutedForeground,
                    ),
                    const SizedBox(width: 5),
                    FossText.caption(
                      'Pinned by ${_Data.northbound.name}',
                      color: FossTextColor.mutedForeground,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  Flexible(
                    child: Text(
                      comment.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.sm.medium
                          .copyWith(color: colors.foreground),
                    ),
                  ),
                  const SizedBox(width: 7),
                  FossText.caption(
                    comment.when,
                    color: FossTextColor.mutedForeground,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.body,
                style: theme.typography.sm
                    .copyWith(color: colors.foreground, height: 1.45),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_outlined,
                    size: 15,
                    color: colors.mutedForeground,
                  ),
                  const SizedBox(width: 6),
                  FossText.caption(
                    comment.likes,
                    color: FossTextColor.mutedForeground,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.thumb_down_outlined,
                    size: 15,
                    color: colors.mutedForeground,
                  ),
                  const SizedBox(width: 18),
                  FossText.label('Reply'),
                  if (comment.replies > 0) ...[
                    const SizedBox(width: 18),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_drop_down,
                          size: 19,
                          color: colors.primary,
                        ),
                        FossText.label(
                          '${comment.replies} replies',
                          color: FossTextColor.primary,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The column of what to watch after this one.
class _UpNext extends StatelessWidget {
  const _UpNext();

  @override
  Widget build(BuildContext context) {
    final tube = _TubeScope.of(context);
    final watching = tube.watching;
    final queue =
        _Data.videos.where((video) => video != watching).take(9).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const FossText.label('Up next'),
            const Spacer(),
            FossText.caption('Autoplay', color: FossTextColor.mutedForeground),
            const SizedBox(width: 8),
            const _AutoplaySwitchStub(),
          ],
        ),
        const SizedBox(height: 12),
        for (final video in queue)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _UpNextRow(video: video),
          ),
      ],
    );
  }
}

/// The autoplay switch, drawn on rather than wired up. A live switch here
/// would be the one control on the page that changes nothing you can see.
class _AutoplaySwitchStub extends StatelessWidget {
  const _AutoplaySwitchStub();

  @override
  Widget build(BuildContext context) {
    final colors = context.fossTheme.colors;
    return Container(
      width: 32,
      height: 18,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(FossRadii.full),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: colors.primaryForeground,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact tile: a small thumbnail on the left, three lines on the right.
class _UpNextRow extends StatelessWidget {
  const _UpNextRow({required this.video});

  final _Video video;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final tube = _TubeScope.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => tube.open(video),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: _Thumbnail(video: video, radius: theme.radii.md),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.sm.medium
                      .copyWith(color: colors.foreground, height: 1.3),
                ),
                const SizedBox(height: 4),
                _ChannelLine(channel: video.channel),
                const SizedBox(height: 1),
                Text(
                  video.byline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.xs
                      .copyWith(color: colors.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Handed to the controls that are here to be looked at rather than used, so
/// they render live rather than greyed out.
void _noop() {}
