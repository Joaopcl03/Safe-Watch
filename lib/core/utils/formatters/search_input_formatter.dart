import 'package:flutter/services.dart';

// ============================================================================
// Safe Watch — Search Input Formatter
// ============================================================================
// TextInputFormatter customizado para o campo de busca.
// Remove caracteres especiais e limita o comprimento.
// ============================================================================

/// Formatter para campos de busca de mídia.
///
/// Remove caracteres especiais (mantendo letras, números, espaços,
/// hífens e apóstrofos) e limita o texto a [maxLength] caracteres.
///
/// Exemplo:
/// ```dart
/// TextField(
///   inputFormatters: [SwSearchInputFormatter()],
/// )
/// ```
class SwSearchInputFormatter extends TextInputFormatter {
  /// Cria um formatter de busca com limite de caracteres.
  ///
  /// [maxLength] define o número máximo de caracteres permitidos.
  /// O valor padrão é 100.
  SwSearchInputFormatter({this.maxLength = 100});

  /// Número máximo de caracteres permitidos no campo de busca.
  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove caracteres especiais, mantém letras (incluindo acentos),
    // números, espaços, hífens e apóstrofos.
    final filtered = newValue.text.replaceAll(
      RegExp(r"[^\w\s\-'À-ÿ]"),
      '',
    );

    // Limita ao comprimento máximo.
    final truncated =
        filtered.length > maxLength ? filtered.substring(0, maxLength) : filtered;

    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(
        offset: truncated.length.clamp(0, truncated.length),
      ),
    );
  }
}
