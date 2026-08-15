import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Brand colours
  static const Color primaryPurple = Color(0xFF6750A4);
  static const Color secondaryViolet = Color(0xFF625B71);
  static const Color tertiaryPink = Color(0xFF7D5260);
  static const Color accentTeal = Color(0xFF00897B);
  static const Color accentAmber = Color(0xFFFFAB40);

  // ── Gender avatar colours ────────────────────────────────────────────────
  static const Color maleBlue = Color(0xFF1565C0);
  static const Color maleBlueBg = Color(0xFFBBDEFB);
  static const Color femalePink = Color(0xFFAD1457);
  static const Color femalePinkBg = Color(0xFFF8BBD0);

  // Category colours
  static const Color groceryColor = Color(0xFF43A047);
  static const Color onlineColor = Color(0xFF1E88E5);
  static const Color physicalColor = Color(0xFFFF7043);
  static const Color wearablesColor = Color(0xFF8E24AA);
  static const Color homeColor = Color(0xFF00ACC1);
  static const Color healthColor = Color(0xFFE91E63);
  static const Color electronicsColor = Color(0xFF3949AB);
  static const Color educationColor = Color(0xFFFFA000);
  static const Color otherColor = Color(0xFF757575);

  static Color categoryColor(String category) {
    switch (category) {
      case 'Grocery':
        return groceryColor;
      case 'Online':
        return onlineColor;
      case 'Physical':
        return physicalColor;
      case 'Wearables':
        return wearablesColor;
      case 'Home & Living':
        return homeColor;
      case 'Health & Beauty':
        return healthColor;
      case 'Electronics':
        return electronicsColor;
      case 'Education':
        return educationColor;
      default:
        return otherColor;
    }
  }

  /// Returns the icon for a given category. Single source of truth —
  /// used by AddItemScreen, CategoryDropdown, and VoiceInputSheet.
  static IconData categoryIcon(String category) {
    switch (category) {
      case 'Grocery':
        return Icons.shopping_basket_rounded;
      case 'Online':
        return Icons.computer_rounded;
      case 'Physical':
        return Icons.store_rounded;
      case 'Wearables':
        return Icons.checkroom_rounded;
      case 'Home & Living':
        return Icons.home_rounded;
      case 'Health & Beauty':
        return Icons.favorite_rounded;
      case 'Electronics':
        return Icons.devices_rounded;
      case 'Education':
        return Icons.menu_book_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Base Theme Factory (DRY - Removes ~300 lines of duplication)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Builds a complete ThemeData with all component themes configured.
  ///
  /// This factory method eliminates duplication across lightTheme, darkTheme,
  /// soothingTheme, and vibrantDarkTheme by centralizing all common configuration.
  /// Each theme method only needs to provide the ColorScheme and TextTheme.
  static ThemeData _buildBaseTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        color: colorScheme.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.poppins(fontSize: 14),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.poppins(
          color: colorScheme.onInverseSurface,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Public Theme Methods (Now concise - just ColorScheme + TextTheme)
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryPurple,
      brightness: Brightness.light,
    );

    return _buildBaseTheme(
      colorScheme: colorScheme,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryPurple,
      brightness: Brightness.dark,
    );

    return _buildBaseTheme(
      colorScheme: colorScheme,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    );
  }

  static ThemeData soothingTheme() {
    const seedColor = Color(0xFF2D4A3E); // Forest green

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return _buildBaseTheme(
      colorScheme: colorScheme,
      textTheme: GoogleFonts.nunitoSansTextTheme().copyWith(
        displayLarge: GoogleFonts.nunitoSans(
          fontSize: 57,
          fontWeight: FontWeight.w300,
          color: colorScheme.onSurface,
        ),
        headlineLarge: GoogleFonts.nunitoSans(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.nunitoSans(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.nunitoSans(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  static ThemeData vibrantDarkTheme() {
    const seedColor = Color(0xFF6200EA); // Deep purple

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return _buildBaseTheme(
      colorScheme: colorScheme,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
