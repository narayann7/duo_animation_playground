import 'package:flutter/material.dart';

import 'demo_images.dart';

/// A video home feed: a top bar, a shorts shelf and a column of video rows.
///
/// Thumbnails are the point. A feed like this puts several large photographs on
/// screen at once with small type packed between them, which is the densest
/// mix of the three demos and the one where the fold's parallax reads clearest.
class YouTubeDemo extends StatelessWidget {
  /// Creates the video feed.
  const YouTubeDemo({super.key});

  static const _videos = <_Video>[
    _Video(
      title: 'Front row for the whole set: what a small room does to a big band',
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
    _Short(title: 'Golden hour, no filter', views: '1.4M', image: DemoImages.goldenHour),
    _Short(title: 'Pier at low tide', views: '820K', image: DemoImages.pier),
    _Short(title: 'Blossom, four days early', views: '3.1M', image: DemoImages.blossom),
    _Short(title: 'Twelve minutes of coastline', views: '640K', image: DemoImages.coast),
    _Short(title: 'Dinner, eventually', views: '512K', image: DemoImages.berries),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _TopBar(),
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
    final theme = Theme.of(context);
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
            child: const Icon(
              Icons.play_arrow,
              size: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Videos',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          const Icon(Icons.cast_outlined, size: 22),
          const SizedBox(width: 20),
          const Icon(Icons.notifications_none, size: 22),
          const SizedBox(width: 20),
          const Icon(Icons.search, size: 22),
          const SizedBox(width: 16),
          const DemoAvatar(seed: 6, size: 28),
        ],
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
  });

  final String title;
  final String channel;
  final String meta;
  final String duration;
  final String thumbnail;
  final int avatar;
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xCC000000),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video.duration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DemoAvatar(seed: video.avatar, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${video.channel} · ${video.meta}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_vert, size: 18, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortsShelf extends StatelessWidget {
  const _ShortsShelf({required this.shorts});

  final List<_Short> shorts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  child: const Icon(
                    Icons.bolt,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Shorts',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
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
                        borderRadius: BorderRadius.circular(12),
                        cacheWidth: 440,
                      ),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              short.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${short.views} views',
                              style: const TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 11,
                              ),
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
