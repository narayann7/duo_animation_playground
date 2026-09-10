import 'package:duo_animation/duo_animation.dart';
import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

import 'config/config_screen.dart';
import 'config/demo_config.dart';
import 'demos/photo_demo.dart';
import 'foss_material_theme.dart';
import 'playground_store.dart';

/// Entry point for the Duo Animation Playground.
///
/// The app opens on a configuration screen, then hands the chosen settings to a
/// gallery of ordinary looking app screens so the same fold can be judged
/// against very different content.
///
/// Tilt is driven by the device orientation sensors. The first sample latches
/// the pose the phone was held at on launch, so that angle reads as flat and
/// everything is measured against it. Recalibrate re-latches it.
///
/// Both halves of the setup, the settings and the photographs, are read back
/// off disk before the first frame. Waiting for them is the point: a launch
/// that painted the defaults and then swapped to your own settings a frame
/// later would look like the app changing its mind.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final json = await PlaygroundStore.readJson(PlaygroundStore.configFile);
  await restorePhotoLibrary();
  runApp(
    DuoFoldDemoApp(
      initialConfig:
          json == null ? const DemoConfig() : DemoConfig.fromJson(json),
    ),
  );
}

/// Root of the demo. Owns the one controller and the current configuration.
class DuoFoldDemoApp extends StatefulWidget {
  /// Creates the demo app.
  const DuoFoldDemoApp({super.key, this.initialConfig = const DemoConfig()});

  /// The configuration to open on, read back off disk by [main].
  final DemoConfig initialConfig;

  @override
  State<DuoFoldDemoApp> createState() => _DuoFoldDemoAppState();
}

class _DuoFoldDemoAppState extends State<DuoFoldDemoApp> {
  /// One controller for the whole app, started once. Every demo listens to it,
  /// so moving between screens never drops the sensor subscription or loses the
  /// latched reference pose.
  final DuoFoldController _controller = DuoFoldController();

  late DemoConfig _config = widget.initialConfig;

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
    // Debounced inside the store: a slider drag is one write, not one per
    // frame.
    PlaygroundStore.writeJson(PlaygroundStore.configFile, config.toJson());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Registered as a theme extension rather than through a FossTheme wrapper:
    // context.fossTheme falls back to the extension, so every fossui widget
    // under the navigator resolves the same tokens without a second inherited
    // widget in the tree.
    return MaterialApp(
      title: 'Duo Animation Playground',
      theme: fossMaterialTheme(FossThemeData.light, Brightness.light),
      darkTheme: fossMaterialTheme(FossThemeData.dark, Brightness.dark),
      themeMode: _config.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: ConfigScreen(
        controller: _controller,
        config: _config,
        onChanged: _onConfigChanged,
      ),
    );
  }
}
