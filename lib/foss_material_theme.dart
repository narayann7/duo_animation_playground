import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

/// Builds the Material theme that carries a [FossThemeData].
///
/// The playground keeps `MaterialApp` for its navigator and its scaffolds while
/// every visible control comes from fossui. Those two have to agree on colour,
/// or a fossui card sits on a Material surface of a different shade.
///
/// fossui's own `toThemeData` registers the tokens and nothing else, which
/// leaves Material at its defaults. This adds the parts Material still paints
/// on its own: the scaffold behind every screen, and a colour scheme derived
/// from the same roles rather than from a seed.
ThemeData fossMaterialTheme(FossThemeData foss, Brightness brightness) {
  final colors = foss.colors;
  return ThemeData(
    brightness: brightness,
    extensions: <ThemeExtension<dynamic>>[foss],
    scaffoldBackgroundColor: colors.background,
    canvasColor: colors.background,
    dividerColor: colors.border,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: foss.typography.lg.semibold.copyWith(
        color: colors.foreground,
      ),
    ),
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.primaryForeground,
      secondary: colors.secondary,
      onSecondary: colors.secondaryForeground,
      error: colors.destructive,
      onError: colors.destructiveForegroundOn,
      surface: colors.background,
      onSurface: colors.foreground,
      surfaceContainerHighest: colors.muted,
      onSurfaceVariant: colors.mutedForeground,
      outline: colors.border,
      outlineVariant: colors.input,
    ),
  );
}
