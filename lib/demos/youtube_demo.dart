import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

import 'demo_images.dart';

/// A video home feed: a top bar, a filter row, a shorts shelf and a column of
/// video rows.
///
/// Thumbnails are the point. A feed like this puts several large photographs on
/// screen at once with small type packed between them, which is the densest
/// mix of the three demos and the one where the fold's parallax reads clearest.
class YouTubeDemo extends StatelessWidget {
  /// Creates the video feed.
  const YouTubeDemo({super.key});

  /// The pill that reads as chosen. Fixed, and none of them respond to a tap:
  /// the filter moves pixels and not hit boxes, so a control behind the glass
  /// answers where it would have been untilted, which reads as broken the
  /// moment the device leans. Interactive parts of a demo go in the host's
  /// overlay instead.
  static const _filter = 'All';

  static const _filters = <String>[
    'All',
    'Music',
    'Live',
    'Photography',
    'Travel',
    'Gaming',
  ];

  static const _videos = <_Video>[
    _Video(
      title:
          'Front row for the whole set: what a small room does to a big band',
      channel: 'Sound Check',
      meta: '412K views · 2 days ago',
      duration: '14:02',
      thumbnail: DemoImages.concert,
      avatar: 0,
    ),
    _Video(
      title: 'How this bridge was built twice, and why the second one held',
      channel: 'Structures Explained',
      meta: '1.2M views · 1 week ago',
      duration: '22:47',
      thumbnail: DemoImages.bridge,
      avatar: 1,
    ),
    _Video(
      title: 'Six hours of rush hour in ninety seconds, filmed from a rooftop',
      channel: 'City Notes',
      meta: '86K views · 3 days ago',
      duration: '9:15',
      thumbnail: DemoImages.traffic,
      avatar: 2,
      live: true,
    ),
    _Video(
      title: 'Shooting a skyline after dark with one prime lens and no tripod',
      channel: 'Frame by Frame',
      meta: '203K views · 5 days ago',
      duration: '17:31',
      thumbnail: DemoImages.cityNight,
      avatar: 3,
    ),
    _Video(
      title: 'Three days on the island, and the one street worth walking twice',
      channel: 'Northbound',
      meta: '755K views · 2 weeks ago',
      duration: '25:08',
      thumbnail: DemoImages.cliffside,
      avatar: 4,
    ),
    _Video(
      title: 'The cheap drone that finally shoots something worth keeping',
      channel: 'Gear, Briefly',
      meta: '1.9M views · 4 days ago',
      duration: '11:44',
      thumbnail: DemoImages.drone,
      avatar: 5,
    ),
  ];

  static const _shorts = <_Short>[
    _Short(
      title: 'Golden hour, no filter',
      views: '1.4M',
      image: DemoImages.goldenHour,
    ),
    _Short(title: 'Pier at low tide', views: '820K', image: DemoImages.pier),
    _Short(
      title: 'Blossom, four days early',
      views: '3.1M',
      image: DemoImages.blossom,
    ),
    _Short(
      title: 'Twelve minutes of coastline',
      views: '640K',
      image: DemoImages.coast,
    ),
    _Short(
      title: 'Ten minutes before the rain',
      views: '512K',
      image: DemoImages.portraitField,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _TopBar(),
        const _FilterRow(filters: _filters, selected: _filter),
        for (var index = 0; index < 2; index++)
          _VideoRow(video: _videos[index]),
        const _ShortsShelf(shorts: _shorts),
        for (var index = 2; index < _videos.length; index++)
          _VideoRow(video: _videos[index]),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFF0033),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.play_arrow, size: 13, color: Colors.white),
          ),
          const SizedBox(width: 6),
          const FossText.heading('Videos'),
          const Spacer(),
          const Icon(Icons.cast_outlined, size: 22),
          const SizedBox(width: 20),
          const Icon(Icons.notifications_none, size: 22),
          const SizedBox(width: 20),
          const Icon(Icons.search, size: 22),
          const SizedBox(width: 16),
          const DemoAvatar(seed: 6, size: FossAvatarSize.sm),
        ],
      ),
    );
  }
}

/// The scrolling row of category pills under the top bar.
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filters, required this.selected});

  final List<String> filters;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return FossChip(
            label: Text(filter),
            size: FossChipSize.sm,
            selected: filter == selected,
          );
        },
      ),
    );
  }
}

/// One row in the video feed.
@immutable
class _Video {
  const _Video({
    required this.title,
    required this.channel,
    required this.meta,
    required this.duration,
    required this.thumbnail,
    required this.avatar,
    this.live = false,
  });

  final String title;
  final String channel;
  final String meta;
  final String duration;
  final String thumbnail;
  final int avatar;

  /// True swaps the duration pill for a live marker.
  final bool live;
}

/// One card in the shorts shelf.
@immutable
class _Short {
  const _Short({
    required this.title,
    required this.views,
    required this.image,
  });

  final String title;
  final String views;
  final String image;
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({required this.video});

  final _Video video;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: DemoImage(assetKey: video.thumbnail),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: video.live
                    ? const FossBadge(
                        label: Text('LIVE'),
                        size: FossBadgeSize.sm,
                        variant: FossBadgeVariant.destructive,
                      )
                    : _DurationBadge(duration: video.duration),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DemoAvatar(seed: video.avatar, size: FossAvatarSize.lg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FossText.label(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      FossText.caption(
                        '${video.channel} · ${video.meta}',
                        color: FossTextColor.mutedForeground,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_vert,
                  size: 18,
                  color: context.fossTheme.colors.mutedForeground,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The running time, bottom right of a thumbnail.
///
/// A badge with its colours pinned rather than taken from the theme: it sits on
/// a photograph, so it has to stay legible over whatever that photograph is
/// doing, in either theme.
class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    return FossBadge(
      label: Text(duration),
      size: FossBadgeSize.sm,
      style: const FossBadgeStyle(
        backgroundColor: Color(0xCC000000),
        foregroundColor: Colors.white,
        borderColor: Colors.transparent,
      ),
    );
  }
}

class _ShortsShelf extends StatelessWidget {
  const _ShortsShelf({required this.shorts});

  final List<_Short> shorts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0033),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.bolt, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const FossText.title('Shorts'),
              ],
            ),
          ),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: shorts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final short = shorts[index];
                return SizedBox(
                  width: 148,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DemoImage(
                        assetKey: short.image,
                        borderRadius: BorderRadius.circular(
                          context.fossTheme.radii.xl,
                        ),
                        cacheWidth: 440,
                      ),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fixed white over a photograph, for the same
                            // reason the duration badge is fixed.
                            FossText.label(
                              short.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FossText.caption(
                              '${short.views} views',
                              style: const TextStyle(color: Color(0xCCFFFFFF)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
