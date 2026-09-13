import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const sky = Color(0xFF4A90C8);
const skyDeep = Color(0xFF2B5F8A);
const skySoft = Color(0xFFD6EAF8);
const mist = Color(0xFFF3F7FB);
const cloud = Color(0xFFE4EEF6);
const ink = Color(0xFF1C2B36);

ThemeData buildAppTheme() {
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: sky,
    onPrimary: Colors.white,
    primaryContainer: skySoft,
    onPrimaryContainer: skyDeep,
    secondary: skyDeep,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFC5DDF0),
    onSecondaryContainer: skyDeep,
    tertiary: skyDeep,
    onTertiary: Colors.white,
    error: const Color(0xFFB3261E),
    onError: Colors.white,
    surface: mist,
    onSurface: ink,
    onSurfaceVariant: const Color(0xFF4A5B68),
    surfaceContainerLowest: const Color(0xFFF8FBFD),
    surfaceContainerLow: const Color(0xFFECF3F8),
    surfaceContainer: cloud,
    surfaceContainerHigh: const Color(0xFFD7E4EE),
    surfaceContainerHighest: cloud,
    outline: const Color(0xFFB7C7D3),
    outlineVariant: const Color(0xFFD3DEE6),
  );

  final textTheme = GoogleFonts.plusJakartaSansTextTheme().apply(
    bodyColor: ink,
    displayColor: ink,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: mist,
    textTheme: textTheme,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: mist,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
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
        backgroundColor: sky,
        foregroundColor: Colors.white,
        disabledBackgroundColor: cloud,
        disabledForegroundColor: const Color(0xFF7A8B97),
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: sky,
      inactiveTrackColor: cloud,
      thumbColor: skyDeep,
      overlayColor: sky.withValues(alpha: 0.12),
      trackHeight: 4,
    ),
    chipTheme: ChipThemeData(
      selectedColor: skySoft,
      backgroundColor: cloud,
      disabledColor: cloud,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: ink,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: GoogleFonts.plusJakartaSans(color: skyDeep),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
    dividerColor: scheme.outlineVariant,
  );
}
