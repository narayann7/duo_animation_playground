import 'package:duo_animation/duo_animation.dart';
import 'package:flutter/material.dart';

import 'config/config_screen.dart';
import 'config/demo_config.dart';

/// Entry point for the Duo Animation Playground.
///
/// The app opens on a configuration screen, then hands the chosen settings to a
/// gallery of ordinary looking app screens so the same fold can be judged
/// against very different content.
///
/// Tilt is driven by the device orientation sensors. The first sample latches
/// the pose the phone was held at on launch, so that angle reads as flat and
/// everything is measured against it. Recalibrate re-latches it.
void main() {
  runApp(const DuoFoldDemoApp());
}

/// Root of the demo. Owns the one controller and the current configuration.
class DuoFoldDemoApp extends StatefulWidget {
  /// Creates the demo app.
  const DuoFoldDemoApp({super.key});

  @override
  State<DuoFoldDemoApp> createState() => _DuoFoldDemoAppState();
}

class _DuoFoldDemoAppState extends State<DuoFoldDemoApp> {
  /// One controller for the whole app, started once. Every demo listens to it,
  /// so moving between screens never drops the sensor subscription or loses the
  /// latched reference pose.
  final DuoFoldController _controller = DuoFoldController();

  DemoConfig _config = const DemoConfig();

  @override
  void initState() {
    super.initState();
    _applyToController(_config);
    _controller.start();
  }

  /// Pushes the motion half of [config] onto the controller. The optical half
  /// travels with the config value instead, since it is read by the fold widget
  /// rather than by the filter.
  void _applyToController(DemoConfig config) {
    _controller
      ..constraints = config.constraintOption.constraints
      ..autoRecenter = config.autoRecenter
      ..useSensor = config.useSensor
      ..manualTiltDegrees = config.manualTiltDegrees;
  }

  void _onConfigChanged(DemoConfig config) {
    setState(() => _config = config);
    _applyToController(config);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duo Animation Playground',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: _config.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: ConfigScreen(
        controller: _controller,
        config: _config,
        onChanged: _onConfigChanged,
      ),
    );
  }
}
