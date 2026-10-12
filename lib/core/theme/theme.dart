import 'package:flutter/material.dart';

// ============================================================================
// Safe Watch — Design System Theme
// ============================================================================
// Define cores, tipografia, espaçamentos e tamanhos de fonte.
// Prefixo "Sw" para todos os componentes do design system.
// ============================================================================

/// Cores neutras do design system.
/// Usadas para backgrounds, textos, bordas e superfícies.
abstract final class SwNeutralColors {
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF8F9FA);
  static const Color gray100 = Color(0xFFF1F3F5);
  static const Color gray200 = Color(0xFFE9ECEF);
  static const Color gray300 = Color(0xFFDEE2E6);
  static const Color gray400 = Color(0xFFCED4DA);
  static const Color gray500 = Color(0xFFADB5BD);
  static const Color gray600 = Color(0xFF868E96);
  static const Color gray700 = Color(0xFF495057);
  static const Color gray800 = Color(0xFF343A40);
  static const Color gray900 = Color(0xFF212529);
  static const Color black = Color(0xFF000000);
}

/// Cores da marca Safe Watch.
/// Usadas para elementos de destaque, CTAs e identidade visual.
abstract final class SwBrandColors {
  static const Color primary = Color(0xFFFFD000);
  static const Color primaryLight = Color(0xFFFFE15C);
  static const Color primaryDark = Color(0xFFC9A400);
  static const Color secondary = Color(0xFF00CEC9);
  static const Color secondaryLight = Color(0xFF81ECEC);
  static const Color secondaryDark = Color(0xFF00B894);
  static const Color accent = Color(0xFFFD79A8);
}

/// Cores de superfície do tema escuro (visual estilo "TV Time").
/// Fundo preto, cards levemente elevados e painéis com tom quente.
abstract final class SwSurfaceColors {
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0E0E0E);
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardBorder = Color(0xFF3A3A3A);
  static const Color divider = Color(0xFF2A2A2A);
  static const Color pill = Color(0xFF5C5C5C);
  static const Color chip = Color(0xFF262626);
  static const Color feedPanel = Color(0xFF2A2417);
  static const Color progressTrack = Color(0xFF3A3A3A);
}

/// Cores de suporte para feedback do sistema.
/// Sucesso, alerta, erro e informação.
abstract final class SwSupportColors {
  static const Color success = Color(0xFF00B894);
  static const Color successLight = Color(0xFFD4EDDA);
  static const Color warning = Color(0xFFFDAA5D);
  static const Color warningLight = Color(0xFFFFF3CD);
  static const Color error = Color(0xFFE17055);
  static const Color errorLight = Color(0xFFF8D7DA);
  static const Color info = Color(0xFF74B9FF);
  static const Color infoLight = Color(0xFFD1ECF1);
}

/// Constantes de espaçamento do design system.
/// Usadas para padding, margin e gaps consistentes.
abstract final class SwSpacing {
  static const double xxxs = 2.0;
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

/// Constantes de tamanho de fonte do design system.
abstract final class SwFontSize {
  static const double xs = 10.0;
  static const double sm = 12.0;
  static const double md = 14.0;
  static const double lg = 16.0;
  static const double xl = 18.0;
  static const double xxl = 20.0;
  static const double h3 = 24.0;
  static const double h2 = 28.0;
  static const double h1 = 32.0;
  static const double display = 40.0;
}

/// Tema principal do Safe Watch.
///
/// Fornece [lightTheme] e [darkTheme] pré-configurados
/// com a paleta de cores da marca.
abstract final class SwTheme {
  /// Tema claro.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: SwBrandColors.primary,
        primaryContainer: SwBrandColors.primaryLight,
        secondary: SwBrandColors.secondary,
        secondaryContainer: SwBrandColors.secondaryLight,
        surface: SwNeutralColors.white,
        error: SwSupportColors.error,
        onPrimary: SwNeutralColors.white,
        onSecondary: SwNeutralColors.white,
        onSurface: SwNeutralColors.gray900,
        onError: SwNeutralColors.white,
      ),
      scaffoldBackgroundColor: SwNeutralColors.gray50,
      appBarTheme: const AppBarTheme(
        backgroundColor: SwBrandColors.primary,
        foregroundColor: SwNeutralColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: SwNeutralColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SwNeutralColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwNeutralColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwNeutralColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwBrandColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwSupportColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SwSpacing.md,
          vertical: SwSpacing.sm,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SwBrandColors.primary,
          foregroundColor: SwNeutralColors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: SwSpacing.lg,
            vertical: SwSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SwBrandColors.primary,
        foregroundColor: SwNeutralColors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: SwNeutralColors.gray200,
        thickness: 1,
      ),
    );
  }

  /// Tema escuro (visual principal do app, inspirado no TV Time).
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: SwBrandColors.primary,
        primaryContainer: SwBrandColors.primaryDark,
        secondary: SwBrandColors.primary,
        secondaryContainer: SwBrandColors.primaryDark,
        surface: SwSurfaceColors.surface,
        surfaceContainerHighest: SwSurfaceColors.card,
        error: SwSupportColors.error,
        onPrimary: SwNeutralColors.black,
        onSecondary: SwNeutralColors.black,
        onSurface: SwNeutralColors.white,
        onError: SwNeutralColors.white,
        outline: SwSurfaceColors.cardBorder,
      ),
      scaffoldBackgroundColor: SwSurfaceColors.background,
      canvasColor: SwSurfaceColors.background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: SwSurfaceColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: SwNeutralColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: SwNeutralColors.white,
        unselectedLabelColor: SwNeutralColors.gray500,
        indicatorColor: SwNeutralColors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: CardThemeData(
        color: SwSurfaceColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SwSurfaceColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwSurfaceColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwSurfaceColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: SwBrandColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwSupportColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SwSpacing.md,
          vertical: SwSpacing.sm,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SwBrandColors.primary,
          foregroundColor: SwNeutralColors.black,
          padding: const EdgeInsets.symmetric(
            horizontal: SwSpacing.lg,
            vertical: SwSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SwNeutralColors.white,
          side: const BorderSide(color: SwNeutralColors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SwBrandColors.primary,
        foregroundColor: SwNeutralColors.black,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: SwSurfaceColors.card,
        contentTextStyle: TextStyle(color: SwNeutralColors.white),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SwSurfaceColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: SwSurfaceColors.card,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SwBrandColors.primary,
      ),
      dividerTheme: const DividerThemeData(
        color: SwSurfaceColors.divider,
        thickness: 1,
      ),
    );
  }
}
