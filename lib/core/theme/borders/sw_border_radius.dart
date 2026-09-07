import 'package:flutter/material.dart';

// ============================================================================
// Safe Watch — Border Radius Constants
// ============================================================================
// Constantes de borda reutilizáveis no design system.
// Prefixo "Sw" para consistência de nomenclatura.
// ============================================================================

/// Constantes de [BorderRadius] do design system Safe Watch.
///
/// Usadas em cards, inputs, botões e containers para manter
/// consistência visual em todo o app.
///
/// Exemplo:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: SwBorderRadius.md,
///   ),
/// )
/// ```
abstract final class SwBorderRadius {
  /// Extra-small border radius (4px).
  static final BorderRadius xs = BorderRadius.circular(4.0);

  /// Small border radius (8px).
  static final BorderRadius sm = BorderRadius.circular(8.0);

  /// Medium border radius (12px) — padrão para cards e inputs.
  static final BorderRadius md = BorderRadius.circular(12.0);

  /// Large border radius (16px).
  static final BorderRadius lg = BorderRadius.circular(16.0);

  /// Extra-large border radius (24px).
  static final BorderRadius xl = BorderRadius.circular(24.0);

  /// Full/circular border radius (999px) — para pills e avatares.
  static final BorderRadius full = BorderRadius.circular(999.0);
}
