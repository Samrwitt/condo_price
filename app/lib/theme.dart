import 'package:flutter/material.dart';

const olive = Color(0xFF5C6B2F);
const oliveDeep = Color(0xFF3A421C);
const oliveSoft = Color(0xFFD6DBA8);
const cream = Color(0xFFF6F1E6);
const sand = Color(0xFFE7DFCE);
const ink = Color(0xFF2C281C);
const clay = Color(0xFF8A6236);

ThemeData buildAppTheme() {
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: olive,
    onPrimary: const Color(0xFFFFF8E7),
    primaryContainer: oliveSoft,
    onPrimaryContainer: oliveDeep,
    secondary: clay,
    onSecondary: const Color(0xFFFFF8E7),
    secondaryContainer: const Color(0xFFE8D4B0),
    onSecondaryContainer: const Color(0xFF3F2C12),
    tertiary: oliveDeep,
    onTertiary: const Color(0xFFFFF8E7),
    error: const Color(0xFF9B3D2A),
    onError: const Color(0xFFFFF8E7),
    surface: cream,
    onSurface: ink,
    onSurfaceVariant: const Color(0xFF5C5648),
    surfaceContainerLowest: const Color(0xFFFAF6EE),
    surfaceContainerLow: const Color(0xFFF0E9DA),
    surfaceContainer: sand,
    surfaceContainerHigh: const Color(0xFFDDD4C2),
    surfaceContainerHighest: sand,
    outline: const Color(0xFFC4BBA8),
    outlineVariant: const Color(0xFFD8CFBE),
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: cream,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: olive,
        foregroundColor: const Color(0xFFFFF8E7),
        disabledBackgroundColor: sand,
        disabledForegroundColor: const Color(0xFF8A8374),
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: olive,
      inactiveTrackColor: sand,
      thumbColor: oliveDeep,
      overlayColor: olive.withValues(alpha: 0.12),
      trackHeight: 4,
    ),
    chipTheme: ChipThemeData(
      selectedColor: oliveSoft,
      backgroundColor: sand,
      disabledColor: sand,
      labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w600),
      secondaryLabelStyle: const TextStyle(color: oliveDeep),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
    dividerColor: scheme.outlineVariant,
  );
}
