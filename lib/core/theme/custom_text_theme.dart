import 'package:flutter/material.dart';
import 'package:safe_watch/core/theme/theme.dart';

// ============================================================================
// Safe Watch — Custom Text Theme
// ============================================================================
// Tipografia centralizada com enum [SwTypeTypography].
// Usar: getTextStyle(context, typo: SwTypeTypography.h1, color: ...)
// ============================================================================

/// Enum de estilos tipográficos do design system Safe Watch.
///
/// Cada valor mapeia para um [TextStyle] específico com tamanho,
/// peso e espaçamento pré-definidos.
enum SwTypeTypography {
  /// Display — usado para títulos de destaque (40px, bold).
  display,

  /// Heading 1 — título principal (32px, bold).
  h1,

  /// Heading 2 — subtítulo (28px, semi-bold).
  h2,

  /// Heading 3 — título de seção (24px, semi-bold).
  h3,

  /// Title — título de card/componente (20px, semi-bold).
  title,

  /// Subtitle — subtítulo de componente (18px, medium).
  subtitle,

  /// Body Large — texto de corpo ampliado (16px, regular).
  bodyLarge,

  /// Body — texto de corpo padrão (14px, regular).
  body,

  /// Caption — texto auxiliar (12px, regular).
  caption,

  /// Overline — label superior pequeno (10px, medium, uppercase).
  overline,

  /// Button — texto de botão (14px, semi-bold).
  button,
}

/// Retorna um [TextStyle] baseado no [SwTypeTypography] fornecido.
///
/// Parâmetros:
/// - [context]: BuildContext para acessar o theme (reservado para extensões futuras).
/// - [typo]: O estilo tipográfico desejado.
/// - [color]: Cor opcional; se não fornecida, usa [SwNeutralColors.gray900].
///
/// Exemplo:
/// ```dart
/// Text(
///   'Título',
///   style: getTextStyle(
///     context,
///     typo: SwTypeTypography.h1,
///     color: SwBrandColors.primary,
///   ),
/// )
/// ```
TextStyle getTextStyle(
  BuildContext context, {
  required SwTypeTypography typo,
  Color? color,
}) {
  final defaultColor = color ?? SwNeutralColors.gray900;

  return switch (typo) {
    SwTypeTypography.display => TextStyle(
        fontSize: SwFontSize.display,
        fontWeight: FontWeight.w700,
        color: defaultColor,
        height: 1.2,
        letterSpacing: -0.5,
      ),
    SwTypeTypography.h1 => TextStyle(
        fontSize: SwFontSize.h1,
        fontWeight: FontWeight.w700,
        color: defaultColor,
        height: 1.25,
        letterSpacing: -0.3,
      ),
    SwTypeTypography.h2 => TextStyle(
        fontSize: SwFontSize.h2,
        fontWeight: FontWeight.w600,
        color: defaultColor,
        height: 1.3,
      ),
    SwTypeTypography.h3 => TextStyle(
        fontSize: SwFontSize.h3,
        fontWeight: FontWeight.w600,
        color: defaultColor,
        height: 1.33,
      ),
    SwTypeTypography.title => TextStyle(
        fontSize: SwFontSize.xxl,
        fontWeight: FontWeight.w600,
        color: defaultColor,
        height: 1.4,
      ),
    SwTypeTypography.subtitle => TextStyle(
        fontSize: SwFontSize.xl,
        fontWeight: FontWeight.w500,
        color: defaultColor,
        height: 1.4,
      ),
    SwTypeTypography.bodyLarge => TextStyle(
        fontSize: SwFontSize.lg,
        fontWeight: FontWeight.w400,
        color: defaultColor,
        height: 1.5,
      ),
    SwTypeTypography.body => TextStyle(
        fontSize: SwFontSize.md,
        fontWeight: FontWeight.w400,
        color: defaultColor,
        height: 1.5,
      ),
    SwTypeTypography.caption => TextStyle(
        fontSize: SwFontSize.sm,
        fontWeight: FontWeight.w400,
        color: defaultColor,
        height: 1.4,
      ),
    SwTypeTypography.overline => TextStyle(
        fontSize: SwFontSize.xs,
        fontWeight: FontWeight.w500,
        color: defaultColor,
        height: 1.5,
        letterSpacing: 1.5,
      ),
    SwTypeTypography.button => TextStyle(
        fontSize: SwFontSize.md,
        fontWeight: FontWeight.w600,
        color: defaultColor,
        height: 1.4,
        letterSpacing: 0.5,
      ),
  };
}
