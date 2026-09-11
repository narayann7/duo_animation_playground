import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

import 'demo_images.dart';

/// An analytics dashboard, laid out twice: a single column on a phone and a
/// rail beside a multi-column grid on a tablet.
///
/// Dense small type over flat token-coloured surfaces is the opposite of what
/// the photo demos give the fold. Cards have long straight borders and hairline
/// separators, and those are the edges a fold shows off worst if the maths is
/// wrong: a photograph hides a smeared edge, a 1px rule does not.
///
/// Everything on screen is a `Foss*` widget reading one `FossThemeData`. The
/// only hand-drawn thing is the weekly bar column, because no UI kit ships a
/// chart.
class DashboardDemo extends StatefulWidget {
  /// Creates the dashboard.
  const DashboardDemo({super.key});

  /// Shortest side, in logical pixels, at or above which the tablet layout is
  /// used. 600 is the usual Material breakpoint and puts every iPad, in either
  /// orientation, on the wide layout.
  ///
  /// Measured on the shortest side rather than the width on purpose. This app
  /// is held at an angle and turned over in the hand, and a layout that swapped
  /// itself out halfway through a tilt would be judged instead of the fold.
  static const double tabletBreakpoint = 600;

  @override
  State<DashboardDemo> createState() => _DashboardDemoState();
}

class _DashboardDemoState extends State<DashboardDemo> {
  _Period _period = _Period.week;

  /// Which filters are on. A set rather than a single value, since the chips
  /// stack: a week of storefront takings in the north is three of them.
  Set<String> _filters = <String>{_Data.filters.first};

  void _setPeriod(_Period period) => setState(() => _period = period);

  /// Replaces the set rather than mutating it. [_DashboardScope] compares the
  /// old value against the new one to decide whether to rebuild its dependents,
  /// and a set mutated in place is compared against itself, so the chips would
  /// never redraw.
  void _setFilter(String filter, bool on) => setState(() {
        final next = <String>{..._filters};
        if (on) {
          next.add(filter);
        } else {
          next.remove(filter);
        }
        _filters = next;
      });

  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).shortestSide >= DashboardDemo.tabletBreakpoint;
    // The toaster is mounted here rather than around the whole app so its
    // toasts land inside the fold with everything else. A toast that floated
    // above the glass would be the one crisp thing on a folded screen.
    return FossToaster(
      child: _DashboardScope(
        period: _period,
        filters: _filters,
        onPeriodChanged: _setPeriod,
        onFilterChanged: _setFilter,
        child: wide ? const _WideDashboard() : const _NarrowDashboard(),
      ),
    );
  }
}

/// Carries the dashboard's state down to the controls that read it.
///
/// An inherited widget rather than four layers of constructor argument: the
/// period is read by the tabs, the chart and the masthead's subtitle, and none
/// of those are near each other in the tree.
class _DashboardScope extends InheritedWidget {
  const _DashboardScope({
    required this.period,
    required this.filters,
    required this.onPeriodChanged,
    required this.onFilterChanged,
    required super.child,
  });

  final _Period period;
  final Set<String> filters;
  final ValueChanged<_Period> onPeriodChanged;
  final void Function(String filter, bool on) onFilterChanged;

  static _DashboardScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_DashboardScope>();
    assert(scope != null, 'No _DashboardScope above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(_DashboardScope old) =>
      period != old.period || !setEquals(filters, old.filters);
}

// ---------------------------------------------------------------------------
// Content
// ---------------------------------------------------------------------------

/// A headline figure with its change over the period.
@immutable
class _Metric {
  const _Metric({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    this.up = true,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;

  /// Up is not automatically good, but it is for all four of these.
  final bool up;
}

/// One region's share of the period, drawn as a gauge.
@immutable
class _Share {
  const _Share(this.label, this.percent, this.note);

  final String label;
  final double percent;
  final String note;
}

/// A line in the activity feed.
@immutable
class _Event {
  const _Event({
    required this.who,
    required this.what,
    required this.when,
    required this.seed,
    this.badge,
    this.badgeVariant = FossBadgeVariant.secondary,
  });

  final String who;
  final String what;
  final String when;

  /// Picks the avatar photograph.
  final int seed;

  final String? badge;
  final FossBadgeVariant badgeVariant;
}

/// A product, how many went out and what they came to.
@immutable
class _Line {
  const _Line(this.name, this.units, this.value);

  final String name;
  final String units;
  final String value;
}

/// A piece of work with a completion fraction.
@immutable
class _Task {
  const _Task(this.title, this.owner, this.progress);

  final String title;
  final String owner;
  final double progress;
}

/// A stretch of time the dashboard can be looking at, and the bars that go
/// with it.
///
/// Every series is in thousands of pounds, so one formatter covers all four.
/// Written out rather than resampled from a single dataset: a day is not a week
/// divided by seven, and the shape of the column is the whole point.
enum _Period {
  day(
    label: 'Day',
    subtitle: 'Northern region · Friday 14 March',
    total: '£6.4k',
    bars: <double>[0.4, 0.9, 1.3, 1.1, 1.6, 1.1],
    ticks: <String>['8', '10', '12', '14', '16', '18'],
  ),
  week(
    label: 'Week',
    subtitle: 'Northern region · week to 14 March',
    total: '£48.2k',
    bars: <double>[5.2, 6.1, 5.8, 7.4, 8.9, 11.3, 3.5],
    ticks: <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  ),
  month(
    label: 'Month',
    subtitle: 'Northern region · March',
    total: '£206k',
    bars: <double>[44.1, 51.8, 48.2, 61.9],
    ticks: <String>['W1', 'W2', 'W3', 'W4'],
  ),
  year(
    label: 'Year',
    subtitle: 'Northern region · year to date',
    total: '£2.41m',
    bars: <double>[
      168,
      152,
      206,
      191,
      214,
      229,
      241,
      236,
      218,
      205,
      196,
      184,
    ],
    ticks: <String>[
      'J',
      'F',
      'M',
      'A',
      'M',
      'J',
      'J',
      'A',
      'S',
      'O',
      'N',
      'D',
    ],
  );

  const _Period({
    required this.label,
    required this.subtitle,
    required this.total,
    required this.bars,
    required this.ticks,
  });

  /// What the tab says.
  final String label;

  /// The line under the dashboard's title while this period is showing.
  final String subtitle;

  /// The headline figure on the takings card.
  final String total;

  /// One value per bar, in thousands.
  final List<double> bars;

  /// The label under each bar. Same length as [bars].
  final List<String> ticks;

  /// The bar values written the way the peak label wants them. Past a hundred
  /// thousand the decimal is noise, so it goes.
  String format(double thousands) => thousands >= 100
      ? '£${thousands.round()}k'
      : '£${thousands.toStringAsFixed(1)}k';
}

/// Everything the dashboard shows. Written out rather than generated so the
/// numbers stay put between builds and the type has real ragged edges to fold.
abstract final class _Data {
  static const String title = 'Overview';

  static const List<_Metric> metrics = <_Metric>[
    _Metric(
      label: 'Revenue',
      value: '£48,210',
      delta: '+12.4%',
      icon: Icons.payments_outlined,
    ),
    _Metric(
      label: 'Orders',
      value: '1,846',
      delta: '+4.1%',
      icon: Icons.receipt_long_outlined,
    ),
    _Metric(
      label: 'Refunds',
      value: '£1,102',
      delta: '−8.7%',
      icon: Icons.undo_outlined,
      up: false,
    ),
    _Metric(
      label: 'New accounts',
      value: '312',
      delta: '+2.0%',
      icon: Icons.person_add_alt_outlined,
    ),
  ];


  static const List<_Share> shares = <_Share>[
    _Share('Storefront', 62, '£29.9k'),
    _Share('Wholesale', 27, '£13.0k'),
    _Share('Markets', 11, '£5.3k'),
  ];

  static const List<_Event> events = <_Event>[
    _Event(
      who: 'Priya Nair',
      what: 'approved the March wholesale price list',
      when: '11 min',
      seed: 1,
      badge: 'Approved',
      badgeVariant: FossBadgeVariant.primary,
    ),
    _Event(
      who: 'Marcus Oduya',
      what: 'flagged two invoices past 30 days',
      when: '48 min',
      seed: 4,
      badge: 'Overdue',
      badgeVariant: FossBadgeVariant.destructive,
    ),
    _Event(
      who: 'Elena Sokolova',
      what: 'closed the Rye Harbour stock count',
      when: '2 hr',
      seed: 2,
    ),
    _Event(
      who: 'Tomas Bauer',
      what: 'added 14 SKUs to the spring catalogue',
      when: '5 hr',
      seed: 6,
    ),
    _Event(
      who: 'Ada Cardoso',
      what: 'moved the Friday market to the square',
      when: 'Yesterday',
      seed: 3,
    ),
  ];

  static const List<_Task> tasks = <_Task>[
    _Task('Spring catalogue', 'Tomas', 0.82),
    _Task('Stock count', 'Elena', 0.55),
    _Task('Supplier terms', 'Priya', 0.31),
  ];

  static const List<_Line> lines = <_Line>[
    _Line('Seville marmalade', '312', '£2,184'),
    _Line('Smoked sea salt', '286', '£1,430'),
    _Line('Cold brew, 6 pack', '241', '£2,892'),
    _Line('Rye sourdough', '198', '£891'),
  ];

  static const List<_Share> dispatch = <_Share>[
    _Share('Same day', 94, '1,735 orders'),
    _Share('Next day', 81, '98 orders'),
  ];

  static const List<String> filters = <String>[
    'This week',
    'Storefront',
    'Northern',
  ];
}

// ---------------------------------------------------------------------------
// Phone
// ---------------------------------------------------------------------------

/// One column, everything stacked, nothing wider than the screen.
class _NarrowDashboard extends StatelessWidget {
  const _NarrowDashboard();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const _Masthead(compact: true),
          const SizedBox(height: 14),
          const _PeriodTabs(),
          const SizedBox(height: 14),
          // Two by two rather than a four-wide row that would squeeze the
          // figures to three characters each.
          for (var row = 0; row < _Data.metrics.length; row += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              // IntrinsicHeight so the pair matches: a card is as tall as its
              // own text, and two side by side at different heights read as a
              // layout bug rather than as two figures. It also bounds the row,
              // which a stretch inside a list needs.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _StatCard(metric: _Data.metrics[row])),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(metric: _Data.metrics[row + 1])),
                  ],
                ),
              ),
            ),
          const _TrendCard(),
          const SizedBox(height: 12),
          const _SharesCard(),
          const SizedBox(height: 12),
          const _OverdueAlert(),
          const SizedBox(height: 12),
          const _TasksCard(),
          const SizedBox(height: 12),
          const _TopLinesCard(),
          const SizedBox(height: 12),
          const _DispatchCard(),
          const SizedBox(height: 12),
          const _ActivityCard(limit: 3),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tablet
// ---------------------------------------------------------------------------

/// A rail down the side and a grid beside it, which is the arrangement a
/// dashboard gets the moment there is room for one.
class _WideDashboard extends StatelessWidget {
  const _WideDashboard();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _NavRail(),
          const FossSeparator(orientation: FossSeparatorOrientation.vertical),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              children: [
                const _Masthead(compact: false),
                const SizedBox(height: 18),
                // Four across: the whole point of the wide layout is that the
                // headline figures and the chart are in one glance.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final metric in _Data.metrics)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: metric == _Data.metrics.last ? 0 : 16,
                            ),
                            child: _StatCard(metric: metric),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _PeriodTabs(),
                const SizedBox(height: 16),
                const _OverdueAlert(),
                const SizedBox(height: 16),
                const _TileGrid(),
                const SizedBox(height: 16),
                const _ActivityCard(limit: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The panels below the headline figures, in as many columns as fit.
///
/// Columns rather than a grid of equal cells on purpose. A card is as tall as
/// whatever is inside it, and a row of cards stretched to a shared height
/// leaves the shallow ones with a hand's width of empty surface under their
/// last line. Dealing the tiles into columns lets every card stop where its
/// content stops.
class _TileGrid extends StatelessWidget {
  const _TileGrid();

  /// The narrowest a tile is allowed to get before a column is dropped. Below
  /// this the meters start ellipsising their labels. It is low enough that an
  /// 11 inch iPad on its side gets three columns rather than two.
  static const double _minTileWidth = 232;

  /// The gap between tiles, across and down.
  static const double _gap = 16;

  /// The activity feed is deliberately not in here. It is a column of
  /// sentences, and a sentence in a quarter-width tile wraps to five lines and
  /// makes the tile taller than everything beside it. It goes full width under
  /// the grid instead.
  static const List<Widget> _tiles = <Widget>[
    _TrendCard(),
    _SharesCard(),
    _TasksCard(),
    _TopLinesCard(),
    _DispatchCard(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fits = (constraints.maxWidth + _gap) ~/ (_minTileWidth + _gap);
        final columns = fits.clamp(2, 3);
        // Dealt round robin, so the reading order down each column still runs
        // across the page in the order the tiles are listed.
        final dealt = List.generate(
          columns,
          (column) => <Widget>[
            for (var i = column; i < _tiles.length; i += columns) _tiles[i],
          ],
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var column = 0; column < columns; column++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: column == columns - 1 ? 0 : _gap,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final tile in dealt[column])
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: tile == dealt[column].last ? 0 : _gap,
                          ),
                          child: tile,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The side rail: where the app is, and where else it goes.
class _NavRail extends StatelessWidget {
  const _NavRail();

  static const List<(IconData, String)> _items = <(IconData, String)>[
    (Icons.grid_view_outlined, 'Overview'),
    (Icons.show_chart_outlined, 'Reports'),
    (Icons.inventory_2_outlined, 'Inventory'),
    (Icons.receipt_long_outlined, 'Invoices'),
    (Icons.people_outline, 'Team'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    return SizedBox(
      width: 236,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(theme.radii.md),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.hexagon_outlined,
                    size: 17,
                    color: colors.primaryForeground,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: FossText.title(
                    'Harbourline',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (final (icon, label) in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: FossListTile(
                  // Only the current page gets the filled surface; the rest sit
                  // plain, which is the whole of a rail's selected state.
                  variant: label == _Data.title
                      ? FossListTileVariant.filled
                      : FossListTileVariant.plain,
                  leading: Icon(
                    icon,
                    size: 18,
                    color: label == _Data.title
                        ? colors.primary
                        : colors.mutedForeground,
                  ),
                  title: FossText.label(label),
                ),
              ),
            const Spacer(),
            const FossSeparator(),
            const SizedBox(height: 12),
            Row(
              children: [
                const DemoAvatar(seed: 0, size: FossAvatarSize.lg),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FossText.label(
                        'Ruth Ellery',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      FossText.caption(
                        'Regional lead',
                        color: FossTextColor.mutedForeground,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces, shared by both layouts
// ---------------------------------------------------------------------------

/// Title, period and the two actions a dashboard always has.
class _Masthead extends StatelessWidget {
  const _Masthead({required this.compact});

  /// True drops the actions to a second line and shrinks the title a step.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scope = _DashboardScope.of(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact)
          const FossText.heading(_Data.title)
        else
          const FossText.display(_Data.title),
        const SizedBox(height: 3),
        FossText.caption(
          scope.period.subtitle,
          color: FossTextColor.mutedForeground,
        ),
      ],
    );

    // These land where they look while the phone is flat, and drift from their
    // pixels as it leans: the fold moves the image without moving the hit
    // boxes, and a tap is a point. A drag is measured on its delta and does not
    // care where it started, which is why this screen scrolls normally at any
    // angle. DemoHost keeps an overlay slot above the glass for controls that
    // have to be exact.
    final size = compact ? FossButtonSize.sm : FossButtonSize.md;
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FossButton(
          variant: FossButtonVariant.outline,
          size: size,
          onPressed: () => _toast(
            context,
            FossToastVariant.success,
            'Exported ${scope.period.label.toLowerCase()} takings',
            '${scope.period.total} across ${scope.filters.length} filters.',
          ),
          child: const Text('Export'),
        ),
        const SizedBox(width: 8),
        FossButton(
          size: size,
          onPressed: () => _toast(
            context,
            FossToastVariant.info,
            'Report queued',
            'It will be in your inbox in a minute or two.',
          ),
          child: const Text('New report'),
        ),
      ],
    );

    if (!compact) {
      // Heading and actions on one line, the filters on their own below them.
      // Three things competing for one row is how a masthead ends up with an
      // ellipsis in the title on the narrower end of the wide layout.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: heading),
              const SizedBox(width: 12),
              actions,
            ],
          ),
          const SizedBox(height: 12),
          const _FilterChips(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            const DemoAvatar(seed: 0, size: FossAvatarSize.lg),
          ],
        ),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: actions),
      ],
    );
  }
}

/// The filters the figures are already standing on.
class _FilterChips extends StatelessWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    final scope = _DashboardScope.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in _Data.filters)
          FossChip(
            size: FossChipSize.sm,
            selected: scope.filters.contains(filter),
            onSelected: (on) => scope.onFilterChanged(filter, on),
            label: Text(filter),
          ),
      ],
    );
  }
}

/// The period switcher. Live: it drives the takings chart and the line under
/// the title.
class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs();

  @override
  Widget build(BuildContext context) {
    final scope = _DashboardScope.of(context);
    return FossTabs<_Period>(
      value: scope.period,
      onChanged: scope.onPeriodChanged,
      tabs: <FossTab<_Period>>[
        for (final period in _Period.values)
          FossTab(value: period, label: period.label),
      ],
    );
  }
}

/// One headline figure.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final colors = context.fossTheme.colors;
    // Green for a rise, the destructive step for a fall, and an arrow beside
    // each so the direction is not carried by the colour alone.
    final tone = metric.up ? colors.success : colors.destructive;
    return FossCard(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metric.icon, size: 16, color: colors.mutedForeground),
              const SizedBox(width: 6),
              Expanded(
                child: FossText.caption(
                  metric.label,
                  color: FossTextColor.mutedForeground,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FossText.heading(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                metric.up ? Icons.arrow_upward : Icons.arrow_downward,
                size: 13,
                color: tone,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  metric.delta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.fossTheme.typography.xs.medium
                      .copyWith(color: tone),
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: FossText.caption(
                  'vs last week',
                  color: FossTextColor.mutedForeground,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Takings by weekday, with the total above it.
class _TrendCard extends StatelessWidget {
  const _TrendCard();

  @override
  Widget build(BuildContext context) {
    final period = _DashboardScope.of(context).period;
    return FossCard(
      title: const Text('Takings'),
      description: Text(period.label),
      action: FossBadge(
        variant: FossBadgeVariant.secondary,
        label: Text(period.total),
      ),
      content: const _PeriodBars(),
    );
  }
}

/// The selected period's bars: one measure, one hue.
///
/// Hand-drawn because no UI kit has a chart in it. The rules it does follow are
/// the ordinary ones: a single series so no legend, the fill in one colour so
/// height is the only thing carrying the value, the track and the tick labels
/// recessive, and a number on the peak alone rather than on every bar.
class _PeriodBars extends StatelessWidget {
  const _PeriodBars();

  /// How tall the plot is, labels excluded.
  static const double _height = 92;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final period = _DashboardScope.of(context).period;
    final bars = period.bars;
    final peak = bars.reduce((a, b) => a > b ? a : b);
    final top = BorderRadius.vertical(top: Radius.circular(theme.radii.sm));
    // Twelve months in a third of a column leaves no room for a gap on both
    // sides of every bar, so the year tightens up.
    final gap = bars.length > 8 ? 1.0 : 2.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var bar = 0; bar < bars.length; bar++)
                Expanded(
                  child: Padding(
                    // A gap of surface between neighbours, so two tall bars
                    // never read as one block.
                    padding: EdgeInsets.symmetric(horizontal: gap),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.muted,
                            borderRadius: top,
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: bars[bar] / peak,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: top,
                              ),
                            ),
                          ),
                        ),
                        if (bars[bar] == peak)
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                period.format(bars[bar]),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                softWrap: false,
                                textAlign: TextAlign.center,
                                // The label is ink, not the series colour: it
                                // sits on the fill and has to stay readable.
                                style: theme.typography.xs.medium.copyWith(
                                  color: colors.primaryForeground,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final tick in period.ticks)
              Expanded(
                child: FossText.caption(
                  tick,
                  color: FossTextColor.mutedForeground,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Where the week's takings came from.
class _SharesCard extends StatelessWidget {
  const _SharesCard();

  @override
  Widget build(BuildContext context) {
    return FossCard(
      title: const Text('Channels'),
      description: const Text('Share of takings'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final share in _Data.shares)
            Padding(
              padding: EdgeInsets.only(
                bottom: share == _Data.shares.last ? 0 : 14,
              ),
              // The money rides on the label rather than the value, because
              // the label is the half of the meter's row that flexes: a long
              // value string pushes the row past its card instead of
              // ellipsising.
              child: FossMeter(
                value: share.percent,
                label: '${share.label} · ${share.note}',
              ),
            ),
        ],
      ),
    );
  }
}

/// What is in flight, and how far along.
class _TasksCard extends StatelessWidget {
  const _TasksCard();

  @override
  Widget build(BuildContext context) {
    return FossCard(
      title: const Text('In progress'),
      action: FossBadge(
        variant: FossBadgeVariant.outline,
        size: FossBadgeSize.sm,
        label: Text('${_Data.tasks.length}'),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final task in _Data.tasks)
            Padding(
              padding: EdgeInsets.only(
                bottom: task == _Data.tasks.last ? 0 : 14,
              ),
              child: FossProgress(
                value: task.progress,
                label: task.title,
                valueLabel: task.owner,
              ),
            ),
        ],
      ),
    );
  }
}

/// What actually sold, which is the question the takings chart does not answer.
class _TopLinesCard extends StatelessWidget {
  const _TopLinesCard();

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    return FossCard(
      title: const Text('Top lines'),
      description: const Text('By units'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in _Data.lines)
            Padding(
              padding: EdgeInsets.only(
                bottom: line == _Data.lines.last ? 0 : 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FossText.body(
                      line.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FossBadge(
                    variant: FossBadgeVariant.secondary,
                    size: FossBadgeSize.sm,
                    label: Text(line.units),
                  ),
                  const SizedBox(width: 8),
                  // Tabular figures so the column of money lines up on the
                  // decimal rather than wandering with the digit widths.
                  Text(
                    line.value,
                    maxLines: 1,
                    style: theme.typography.sm.medium.copyWith(
                      color: theme.colors.foreground,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// How much of the week's post went out on time.
class _DispatchCard extends StatelessWidget {
  const _DispatchCard();

  @override
  Widget build(BuildContext context) {
    return FossCard(
      title: const Text('Dispatch'),
      action: const FossBadge(
        variant: FossBadgeVariant.secondary,
        size: FossBadgeSize.sm,
        label: Text('On track'),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final band in _Data.dispatch)
            Padding(
              padding: EdgeInsets.only(
                bottom: band == _Data.dispatch.last ? 0 : 14,
              ),
              child: FossMeter(
                value: band.percent,
                label: '${band.label} · ${band.note}',
              ),
            ),
        ],
      ),
    );
  }
}

/// The one thing on the screen that wants doing today.
class _OverdueAlert extends StatelessWidget {
  const _OverdueAlert();

  @override
  Widget build(BuildContext context) {
    return const FossAlert(
      variant: FossAlertVariant.warning,
      title: Text('Two invoices past 30 days'),
      description: Text(
        'Hartwell & Sons and Meridian Foods. £3,480 between them, both chased '
        'once.',
      ),
    );
  }
}

/// Who did what, most recent first.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.limit});

  /// How many lines to show. A phone gets fewer, not smaller ones.
  final int limit;

  @override
  Widget build(BuildContext context) {
    final events = _Data.events.take(limit).toList();
    return FossCard(
      title: const Text('Activity'),
      description: const Text('Across the region'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < events.length; index++) ...[
            if (index != 0) const FossSeparator(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _EventRow(event: events[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final _Event event;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DemoAvatar(seed: event.seed),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // One paragraph, two weights: the name is what the eye scans for,
              // the rest is the sentence it lands in.
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: event.who,
                      style: theme.typography.sm.medium
                          .copyWith(color: colors.foreground),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: event.what,
                      style: theme.typography.sm
                          .copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  FossText.caption(
                    event.when,
                    color: FossTextColor.mutedForeground,
                  ),
                  if (event.badge case final badge?) ...[
                    const SizedBox(width: 8),
                    FossBadge(
                      variant: event.badgeVariant,
                      size: FossBadgeSize.sm,
                      label: Text(badge),
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

/// Raises a toast on the toaster [DashboardDemo] mounts, which sits inside the
/// fold so the toast is folded along with everything under it.
void _toast(
  BuildContext context,
  FossToastVariant variant,
  String title,
  String description,
) {
  showFossToast(
    context,
    FossToast(
      variant: variant,
      title: Text(title),
      description: Text(description),
    ),
  );
}
