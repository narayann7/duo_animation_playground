# Duo Animation Playground

Companion app for the `duo_animation` package. Set the fold up on a config screen, then look at it
on demo screens that behave like real ones.

[![Watch the demo](https://img.youtube.com/vi/x9X1VojlE3s/maxresdefault.jpg)](https://youtu.be/x9X1VojlE3s)

## Demos

| Demo | What it is for |
| --- | --- |
| Dashboard | Flat cards and hairline rules, where a smeared edge has nowhere to hide |
| Video site | Twelve small photographs at once with type under each. Tablets only |
| Your photo | Three bundled photographs, plus up to five off your own device |

The app saves your settings and the photographs you add, so a relaunch opens where you left off.

## The look

UI is built with [fossui](https://fossui.org/), pinned at 0.1.2. `lib/foss_material_theme.dart`
hands Material a colour scheme from the same tokens.

## Running it

```
fvm flutter run -d <device-id>
```

Flutter version is pinned by `.fvmrc`. Needs Impeller, so use real Android or iOS hardware, not
the web. No rotation sensor? Use the tilt slider on the config screen.

The playground depends on the package by path, so it builds against the working copy next door.
