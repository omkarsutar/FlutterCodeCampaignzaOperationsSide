import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF673AB7);
  static const Color secondary = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: colorScheme,
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(fontSize: 57),
      displayMedium: base.textTheme.displayMedium?.copyWith(fontSize: 45),
      displaySmall: base.textTheme.displaySmall?.copyWith(fontSize: 36),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(fontSize: 32),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontSize: 28),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontSize: 24),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 22),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 18),
      titleSmall: base.textTheme.titleSmall?.copyWith(fontSize: 16),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 17),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 16),
      bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 14),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontSize: 16),
      labelMedium: base.textTheme.labelMedium?.copyWith(fontSize: 14),
      labelSmall: base.textTheme.labelSmall?.copyWith(fontSize: 13),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: const Color(0xFFF3E5F5),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: const Color(0xFFF3E5F5),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Colors.black,
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
