import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// How far either end of the slider leans, in degrees.
///
/// The same 45 the config screen's manual tilt runs to, so the two controls
/// mean the same thing by a full-left throw and a value dragged here still
/// reads sensibly on the screen you set it from.
const double tiltSliderRangeDegrees = 45;

/// Diameter of the thumb. Also the inset the track keeps at either end, since
/// the thumb is centred on the value and cannot travel past the edge.
const double _thumbDiameter = 28;

const double _inset = _thumbDiameter / 2;

/// Hand-driven tilt, drawn over a demo.
///
/// Stands in for the rotation sensors when the playground's slider setting is
/// on. The centre is flat and either end is a full lean; the thumb stays where
/// it is let go, which is the whole point of it: a fold you can hold open is a
/// fold you can look at. Double tapping the thumb puts it back to flat, which
/// is the way out of a lean you have finished with without hunting for the
/// middle of the track.
///
/// The angle itself lives in the config, not here. Every gesture is reported
/// rather than applied, and [value] is what comes back down. The only thing
/// this holds is whether a tap on the thumb is still waiting to be joined by a
/// second one.
///
/// Nothing is drawn but the knob. No track behind it and no detent under it:
/// this sits on top of the picture the fold is being judged on, and a rail
/// across the bottom of every demo is a rail across every screenshot. The band
/// it travels in still takes a touch anywhere along it, it just is not painted.
///
/// Colours are pinned rather than themed, the way the photo strip's are: this
/// floats over whatever the demo is showing, up to and including a full-bleed
/// photograph, and has to stay legible against all of it.
class TiltSlider extends StatefulWidget {
  /// Creates a slider showing [value] degrees.
  const TiltSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// The angle the thumb sits at, in degrees, clamped to the range for
  /// display.
  final double value;

  /// Called with the angle under the finger, on every touch and every move.
  final ValueChanged<double> onChanged;

  @override
  State<TiltSlider> createState() => _TiltSliderState();
}

class _TiltSliderState extends State<TiltSlider> {
  /// Open while a tap on the thumb could still turn out to be the first half
  /// of a double tap.
  ///
  /// The double tap is counted here rather than handed to
  /// [GestureDetector.onDoubleTapDown], and that is the whole reason this
  /// widget has state at all. A double tap recogniser has to see whether a
  /// second tap arrives before it can let the first one through, so every
  /// single tap on the track paid a [kDoubleTapTimeout] of nothing happening
  /// before the thumb moved. On a control whose only job is to follow your
  /// finger that reads as broken. Counting it by hand lets the first tap land
  /// on the frame it happened.
  Timer? _thumbTapWindow;

  bool get _awaitingSecondTap => _thumbTapWindow?.isActive ?? false;

  @override
  void dispose() {
    _thumbTapWindow?.cancel();
    super.dispose();
  }

  /// Where on the track [degrees] sits, as 0 at the left end and 1 at the
  /// right.
  static double _fractionOf(double degrees) {
    final clamped =
        degrees.clamp(-tiltSliderRangeDegrees, tiltSliderRangeDegrees);
    return (clamped / tiltSliderRangeDegrees + 1) / 2;
  }

  /// The angle a touch at [localX] on a track [width] wide asks for.
  ///
  /// Clamped at both ends so dragging off the side of the phone parks the fold
  /// at a full lean rather than running away with it.
  static double _degreesAt(double localX, double width) {
    final travel = width - _thumbDiameter;
    if (travel <= 0) {
      return 0;
    }
    final fraction = ((localX - _inset) / travel).clamp(0.0, 1.0);
    return (fraction * 2 - 1) * tiltSliderRangeDegrees;
  }

  /// Whether a touch at [localX] landed on the thumb, which sits at [degrees].
  ///
  /// Slack of a thumb's width either side: the thumb is 28 across and one of
  /// the gestures that has to hit it is a double tap, which lands less
  /// precisely than a press does.
  static bool _onThumb(double localX, double width, double degrees) {
    final travel = width - _thumbDiameter;
    if (travel <= 0) {
      return false;
    }
    final centre = _inset + _fractionOf(degrees) * travel;
    return (localX - centre).abs() <= _thumbDiameter;
  }

  /// A finger has touched down at [local] on a track [width] wide.
  void _onTapDown(Offset local, double width) {
    if (!_onThumb(local.dx, width, widget.value)) {
      // Out on the track: go there, now, and forget any half-finished double
      // tap, which was aimed somewhere else entirely.
      _thumbTapWindow?.cancel();
      widget.onChanged(_degreesAt(local.dx, width));
      return;
    }
    if (_awaitingSecondTap) {
      _thumbTapWindow?.cancel();
      widget.onChanged(0);
      return;
    }
    // Nothing reported: the thumb is already here, so a tap on it is a reach
    // for it rather than a request to shuffle it to wherever inside it the
    // finger landed. It only opens the window for a second tap.
    _thumbTapWindow = Timer(kDoubleTapTimeout, () {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Semantics(
          slider: true,
          label: 'Tilt',
          value: '${widget.value.round()} degrees',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Tap and drag only. There is deliberately no double tap
            // recogniser here; see _thumbTapWindow for what it cost.
            onTapDown: (details) => _onTapDown(details.localPosition, width),
            // Both drag callbacks report the position touched rather than a
            // delta: the thumb goes where your finger is, wherever the gesture
            // happened to start.
            onHorizontalDragStart: (details) =>
                widget.onChanged(_degreesAt(details.localPosition.dx, width)),
            onHorizontalDragUpdate: (details) =>
                widget.onChanged(_degreesAt(details.localPosition.dx, width)),
            child: SizedBox(
              height: _thumbDiameter + 16,
              child: Align(
                // -1 puts the thumb's left edge on the left end of its travel
                // and 1 its right edge on the right, which is the same inset
                // the gesture arithmetic above works in.
                alignment: Alignment(_fractionOf(widget.value) * 2 - 1, 0),
                child: Container(
                  width: _thumbDiameter,
                  height: _thumbDiameter,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Color(0x66000000), blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
