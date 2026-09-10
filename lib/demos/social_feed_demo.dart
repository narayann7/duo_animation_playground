import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

import 'demo_images.dart';

/// A photo feed: a stories strip over photographic posts with captions and
/// action rows.
///
/// Large photographs next to small type is the mix the fold reads best on, and
/// the pictures are real so the frost has grain and soft edges to work with
/// rather than a flat gradient.
///
/// The layout is the one every photo app converged on. What comes from fossui
/// is the parts inside it: the avatars, the type steps, the rules, the pills.
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
      badge: 'New',
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
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 12, 10),
          child: Row(
            children: [
              FossText.display('Feed'),
              Spacer(),
              Icon(Icons.favorite_border, size: 24),
              SizedBox(width: 18),
              Icon(Icons.chat_bubble_outline, size: 22),
            ],
          ),
        ),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _stories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Column(
                children: [
                  DemoAvatar(
                    seed: index,
                    size: FossAvatarSize.xl2,
                    ring: index != 0,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 68,
                    child: FossText.caption(
                      _stories[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const FossSeparator(),
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
    this.badge,
  });

  final String handle;
  final String place;
  final String image;
  final String caption;
  final String likes;

  /// Optional pill beside the handle, for a post the feed is calling out.
  final String? badge;
}

class _FeedPost extends StatelessWidget {
  const _FeedPost({required this.post, required this.seed});

  final _Post post;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              DemoAvatar(seed: seed, size: FossAvatarSize.lg),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: FossText.label(
                            post.handle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post.badge case final badge?) ...[
                          const SizedBox(width: 6),
                          FossBadge(
                            label: Text(badge),
                            variant: FossBadgeVariant.secondary,
                            size: FossBadgeSize.sm,
                          ),
                        ],
                      ],
                    ),
                    FossText.caption(
                      post.place,
                      color: FossTextColor.mutedForeground,
                    ),
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
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
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
              FossText.label('${post.likes} likes'),
              const SizedBox(height: 3),
              // A caption is one paragraph with the handle bolded inside it,
              // not two widgets, so this is the one place the type step gets
              // read off the theme rather than picked by a FossText.
              RichText(
                text: TextSpan(
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.foreground,
                  ),
                  children: [
                    TextSpan(
                      text: '${post.handle} ',
                      style: theme.typography.sm.semibold,
                    ),
                    TextSpan(text: post.caption),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              const FossText.caption(
                'View all 46 comments',
                color: FossTextColor.mutedForeground,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
