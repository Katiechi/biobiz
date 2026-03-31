import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// BioBiz "Digital Atelier" Design System
///
/// Design philosophy: Organic Professionalism
/// - No-line interface: tonal depth instead of borders
/// - Heritage gradient for primary CTAs
/// - Plus Jakarta Sans (headlines) + Inter (body)
/// - Surface tonal hierarchy for layered depth
/// - Gold accent for signature FAB elements
class AppTheme {
  // ─── Brand Colors ───────────────────────────────────────
  static const Color primary = Color(0xFFA20513);           // Heritage red
  static const Color primaryContainer = Color(0xFFC62828);  // Rich red
  static const Color primaryLight = Color(0xFFEF5350);      // Light red (dark mode)

  static const Color secondary = Color(0xFF795900);         // Brown
  static const Color secondaryContainer = Color(0xFFFDCA59); // Gold container
  static const Color secondaryFixed = Color(0xFFFFDF9F);    // Soft gold

  static const Color gold = Color(0xFFD4A537);              // Signature FAB gold
  static const Color goldDark = Color(0xFFB8860B);          // Dark gold

  // ─── Surface Tonal Hierarchy ────────────────────────────
  static const Color surface = Color(0xFFFDF8F6);           // Base
  static const Color surfaceBright = Color(0xFFFDF8F6);     // Same as base
  static const Color surfaceDim = Color(0xFFDDD9D7);        // Dimmed
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // Cards
  static const Color surfaceContainer = Color(0xFFF2EDEB);  // Grouping
  static const Color surfaceContainerLow = Color(0xFFF7F3F1); // Subtle
  static const Color surfaceContainerHigh = Color(0xFFECE7E5); // Interaction
  static const Color surfaceContainerHighest = Color(0xFFE6E1E0); // Input bg

  // ─── Dark Mode Surfaces ─────────────────────────────────
  static const Color surfaceDark = Color(0xFF1C1210);       // Deep brown-black
  static const Color cardDark = Color(0xFF2A1F1B);          // Dark card
  static const Color cardDarkElevated = Color(0xFF3A2E28);  // Elevated card

  // ─── Text Colors ────────────────────────────────────────
  static const Color onSurface = Color(0xFF1C1B1A);         // Primary text
  static const Color onSurfaceVariant = Color(0xFF5B403D);  // Secondary text
  static const Color textDark = Color(0xFFFAF5F0);          // Warm light on dark
  static const Color textMuted = Color(0xFF8B7B74);         // Muted warm

  // ─── Outline ────────────────────────────────────────────
  static const Color outline = Color(0xFF8F706C);
  static const Color outlineVariant = Color(0xFFE4BEBA);

  // ─── Semantic ───────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // ─── Heritage Gradient ──────────────────────────────────
  static const LinearGradient heritageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  // ─── Typography ─────────────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light ? onSurface : textDark;
    final mutedColor = brightness == Brightness.light ? onSurfaceVariant : textMuted;

    return TextTheme(
      // Display — dramatic headlines
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: color,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: color,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color,
      ),
      // Headlines
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: color,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: color,
      ),
      // Titles
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: color,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      ),
      // Body — Inter for readability
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedColor,
      ),
      // Labels — uppercase editorial style
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: color,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: mutedColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: mutedColor,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(Brightness.light);
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: const Color(0xFF735500),
      tertiary: const Color(0xFF00557A),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFF006E9D),
      onTertiaryContainer: Colors.white,
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: const Color(0xFF410002),
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: surface,

      // ─── AppBar ───────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
        ),
      ),

      // ─── Navigation Bar ───────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.08),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 26);
          }
          return const IconThemeData(color: textMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            );
          }
          return GoogleFonts.inter(
            color: textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      // ─── Cards (No-Line Philosophy) ───────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // Ghost border — outline-variant at 15% for accessibility
          side: BorderSide(color: outlineVariant.withValues(alpha: 0.15)),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Filled Button (Heritage Gradient applied per-widget) ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ─── Outlined Button ──────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          backgroundColor: surfaceContainerHigh,
          side: BorderSide.none,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ─── Text Button ─────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── FAB (Gold Signature) ─────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ─── Input Fields (Bottom-Border Pattern) ─────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHighest,
        border: UnderlineInputBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.2), width: 2),
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.2), width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          borderSide: BorderSide(color: error, width: 2),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          borderSide: BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w600),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return primary;
          return textMuted;
        }),
      ),

      // ─── Chips ────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selectedColor: primary.withValues(alpha: 0.12),
        checkmarkColor: primary,
        backgroundColor: surfaceContainerHigh,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        side: BorderSide.none,
      ),

      // ─── Snackbar ─────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: onSurface,
      ),

      // ─── Divider (Tonal, not line-based) ──────────────
      dividerTheme: DividerThemeData(
        color: outlineVariant.withValues(alpha: 0.15),
        thickness: 1,
      ),

      // ─── List Tile ────────────────────────────────────
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ─── Switch ───────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.4);
          return null;
        }),
      ),

      // ─── Dialog ───────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: surfaceContainerLowest,
      ),

      // ─── Bottom Sheet ─────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: textMuted,
      ),

      // ─── Progress Indicator ───────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceContainerHighest,
      ),

      // ─── TabBar ───────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textMuted,
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: primary, width: 2.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(Brightness.dark);
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryLight,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Colors.white,
      secondary: const Color(0xFFE8C96A),
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFF5A4300),
      onSecondaryContainer: secondaryFixed,
      tertiary: const Color(0xFF88CEFF),
      onTertiary: Colors.black,
      tertiaryContainer: const Color(0xFF004D6E),
      onTertiaryContainer: const Color(0xFFC8E6FF),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: errorContainer,
      surface: surfaceDark,
      onSurface: textDark,
      onSurfaceVariant: const Color(0xFFD7C1BD),
      outline: const Color(0xFF9F8C88),
      outlineVariant: const Color(0xFF534341),
      surfaceContainerLowest: const Color(0xFF140D0B),
      surfaceContainerLow: const Color(0xFF211A17),
      surfaceContainer: cardDark,
      surfaceContainerHigh: cardDarkElevated,
      surfaceContainerHighest: const Color(0xFF453935),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: surfaceDark,

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surfaceDark,
        foregroundColor: textDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: cardDark,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryLight.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLight, size: 26);
          }
          return const IconThemeData(color: textMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: primaryLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            );
          }
          return GoogleFonts.inter(
            color: textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          backgroundColor: cardDarkElevated,
          side: BorderSide.none,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDarkElevated,
        border: UnderlineInputBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          borderSide: BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: primaryLight, fontWeight: FontWeight.w600),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return primaryLight;
          return textMuted;
        }),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selectedColor: primaryLight.withValues(alpha: 0.15),
        checkmarkColor: primaryLight,
        backgroundColor: cardDarkElevated,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        side: BorderSide.none,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        thickness: 1,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryLight;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryLight.withValues(alpha: 0.4);
          return null;
        }),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: cardDark,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: textMuted,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryLight,
        linearTrackColor: cardDarkElevated,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: primaryLight,
        unselectedLabelColor: textMuted,
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: primaryLight, width: 2.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Heritage gradient button — use this for primary CTAs
/// Wraps a child widget in the signature gradient container.
class HeritageGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const HeritageGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 52,
    this.borderRadius = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return AnimatedOpacity(
      opacity: isDisabled ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: height,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: AppTheme.heritageGradient,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Gold FAB — the signature floating action button
class GoldFab extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;

  const GoldFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: AppTheme.gold,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Icon(icon),
    );
  }
}
