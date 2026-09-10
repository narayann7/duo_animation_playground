# Duo Animation Playground

A companion app for the `duo_animation` package: set up the fold, then look at it on screens that
behave like real ones.

## What is in it

The app opens on a configuration screen. Hinge constraint, the optical sliders, the haze and
surround swatches, the motion switches and a manual tilt for hardware with no rotation sensor are
all there, along with a live readout so you can tell a dead sensor from a wrong-looking effect.
Press **Show demos** and pick a screen to fold:

| Demo | What it is for |
| --- | --- |
| Social feed | Photographs against small type, the mix the fold reads best on |
| Video feed | Several large thumbnails on screen at once, densest of the three |
| Your photo | Three bundled photographs, or one off your own device |

Every picture is a real photograph rather than a generated placeholder. The effect is judged on
grain and edge detail, so a gradient stand-in flatters it and teaches you nothing.

## Running it

`flutter` is managed by fvm and pinned by the package's `.fvmrc`.

```
fvm flutter run -d <device-id>
fvm flutter build apk --debug
```

The effect needs Impeller, so it runs on real Android or iOS hardware and not on the web. An
emulator with no rotation sensor falls back to the manual tilt slider on the configuration
screen.

Shaders are build-time assets. A change to the package's `.frag` needs a relaunch, not a hot
restart.

## Layout

```
lib/
  main.dart                app root, one controller, config state
  tilt_readout.dart        live tilt and recalibrate
  config/                  the configuration value and its screen
  demos/                   the catalog, the host, and one file per demo
assets/photos/             the bundled photographs
```

The playground depends on the package by path, so it always builds against the working copy next
door rather than a published version.
