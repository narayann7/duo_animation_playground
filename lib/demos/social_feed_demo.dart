import 'package:flutter/material.dart';

import 'demo_images.dart';

/// A photo feed: a stories strip over photographic posts with captions and
/// action rows.
///
/// Large photographs next to small type is the mix the fold reads best on, and
/// the pictures are real so the frost has grain and soft edges to work with
/// rather than a flat gradient.
class SocialFeedDemo extends StatelessWidget {
  /// Creates the feed.
  const SocialFeedDemo({super.key});

  static const _stories = <String>[
    'Your story',
    'priya.n',
    'm.oduya',
    'elena_s',
    'tomas.b',
    'ada.c',
    'felix.a',
  ];

  static const _posts = <_Post>[
    _Post(
      handle: 'elena_s',
      place: 'Rye Harbour',
      image: DemoImages.harbour,
      caption: 'Waited two hours for the light and a cormorant walked into '
          'frame anyway.',
      likes: '1,284',
    ),
    _Post(
      handle: 'priya.n',
      place: 'Golden hour',
      image: DemoImages.goldenHour,
      caption: 'Last ten minutes of sun and she would not turn round.',
      likes: '4,102',
    ),
    _Post(
      handle: 'tomas.b',
      place: 'Somewhere off the ridge road',
      image: DemoImages.meadow,
      caption: 'Sat down for a minute and stayed for an hour.',
      likes: '862',
    ),
    _Post(
      handle: 'ada.c',
      place: 'Kitchen table',
      image: DemoImages.berries,
      caption: 'First of the season. Four of them survived the walk home.',
      likes: '2,470',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
          child: Row(
            children: [
              Text(
                'Feed',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              const Icon(Icons.favorite_border, size: 24),
              const SizedBox(width: 18),
              const Icon(Icons.chat_bubble_outline, size: 22),
            ],
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _stories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Column(
                children: [
                  DemoAvatar(seed: index, size: 58, ring: index != 0),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 68,
                    child: Text(
                      _stories[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const Divider(height: 1),
        for (var index = 0; index < _posts.length; index++)
          _FeedPost(post: _posts[index], seed: index + 1),
      ],
    );
  }
}

/// One post in the feed.
@immutable
class _Post {
  const _Post({
    required this.handle,
    required this.place,
    required this.image,
    required this.caption,
    required this.likes,
  });

  final String handle;
  final String place;
  final String image;
  final String caption;
  final String likes;
}

class _FeedPost extends StatelessWidget {
  const _FeedPost({required this.post, required this.seed});

  final _Post post;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              DemoAvatar(seed: seed, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.handle,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(post.place, style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, size: 20),
            ],
          ),
        ),
        AspectRatio(
          aspectRatio: 4 / 5,
          child: DemoImage(assetKey: post.image),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: const Row(
            children: [
              Icon(Icons.favorite_border, size: 25),
              SizedBox(width: 16),
              Icon(Icons.mode_comment_outlined, size: 23),
              SizedBox(width: 16),
              Icon(Icons.send_outlined, size: 23),
              Spacer(),
              Icon(Icons.bookmark_border, size: 25),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${post.likes} likes',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: '${post.handle} ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: post.caption),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'View all 46 comments',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
