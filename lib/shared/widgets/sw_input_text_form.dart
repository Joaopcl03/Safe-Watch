import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_watch/core/theme/theme.dart';
import 'package:safe_watch/core/theme/borders/sw_border_radius.dart';

// ============================================================================
// Safe Watch — Design System Input Widget
// ============================================================================
// Componente reutilizável de input com variantes via factory constructors.
// Padrão: construtor privado ._() com fábricas nomeadas para cada variante.
// Prefixo "Sw" para componentes do design system.
// ============================================================================

/// Widget de input text form do design system Safe Watch.
///
/// Usa o padrão de construtor privado com factories nomeados
/// para garantir consistência visual entre variantes.
///
/// Variantes disponíveis:
/// - [SwInputTextForm.primary] — Input padrão de texto.
/// - [SwInputTextForm.search] — Input com ícone de busca.
/// - [SwInputTextForm.password] — Input com toggle de visibilidade.
/// - [SwInputTextForm.name] — Input para nomes com capitalização automática.
///
/// Exemplo:
/// ```dart
/// SwInputTextForm.search(
///   controller: _searchController,
///   hintText: 'Buscar séries e filmes...',
///   onChanged: (value) => ref.read(searchControllerProvider.notifier).searchMedia(value),
/// )
/// ```
class SwInputTextForm extends StatefulWidget {
  // ── Construtor privado ─────────────────────────────────────────────
  const SwInputTextForm._(
    {
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.isPassword = false,
    this.fillColor,
    this.borderRadius,
  });

  // ── Factory: Primary ─────────────────────────────────────────────────
  /// Input padrão para entrada de texto geral.
  ///
  /// Usado para campos genéricos como e-mail, descrições, etc.
  factory SwInputTextForm.primary({
    Key? key,
    TextEditingController? controller,
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    VoidCallback? onTap,
    FocusNode? focusNode,
    bool autofocus = false,
    TextInputAction? textInputAction,
  }) {
    return SwInputTextForm._(
      key: key,
      controller: controller,
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      onTap: onTap,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: textInputAction,
    );
  }

  // ── Factory: Search ──────────────────────────────────────────────────
  /// Input estilizado para campos de busca.
  ///
  /// Inclui ícone de lupa como prefixo e bordas arredondadas.
  factory SwInputTextForm.search({
    Key? key,
    TextEditingController? controller,
    String? hintText,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return SwInputTextForm._(
      key: key,
      controller: controller,
      hintText: hintText ?? 'Buscar...',
      prefixIcon: const Icon(Icons.search, color: SwNeutralColors.gray500),
      enabled: enabled,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      fillColor: SwNeutralColors.gray100,
      borderRadius: SwBorderRadius.full,
    );
  }

  // ── Factory: Password ────────────────────────────────────────────────
  /// Input para senhas com toggle de visibilidade.
  ///
  /// O ícone de "olho" alterna entre texto visível e oculto.
  factory SwInputTextForm.password({
    Key? key,
    TextEditingController? controller,
    String? hintText,
    String? labelText,
    bool enabled = true,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    FocusNode? focusNode,
    bool autofocus = false,
    TextInputAction? textInputAction,
  }) {
    return SwInputTextForm._(
      key: key,
      controller: controller,
      hintText: hintText ?? 'Senha',
      labelText: labelText,
      prefixIcon: const Icon(Icons.lock_outline, color: SwNeutralColors.gray500),
      enabled: enabled,
      obscureText: true,
      isPassword: true,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: textInputAction,
      keyboardType: TextInputType.visiblePassword,
    );
  }

  // ── Factory: Name ────────────────────────────────────────────────────
  /// Input para nomes com capitalização automática de palavras.
  ///
  /// Aplica [TextCapitalization.words] automaticamente.
  factory SwInputTextForm.name({
    Key? key,
    TextEditingController? controller,
    String? hintText,
    String? labelText,
    bool enabled = true,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    FocusNode? focusNode,
    bool autofocus = false,
    TextInputAction? textInputAction,
  }) {
    return SwInputTextForm._(
      key: key,
      controller: controller,
      hintText: hintText ?? 'Nome completo',
      labelText: labelText,
      prefixIcon:
          const Icon(Icons.person_outline, color: SwNeutralColors.gray500),
      enabled: enabled,
      textCapitalization: TextCapitalization.words,
      keyboardType: TextInputType.name,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: textInputAction,
    );
  }

  // ── Propriedades ─────────────────────────────────────────────────────
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final bool isPassword;
  final Color? fillColor;
  final BorderRadius? borderRadius;

  @override
  State<SwInputTextForm> createState() => _SwInputTextFormState();
}

class _SwInputTextFormState extends State<SwInputTextForm> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      onTap: widget.onTap,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      style: const TextStyle(
        fontSize: SwFontSize.md,
        color: SwNeutralColors.gray900,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: _buildSuffixIcon(),
        filled: widget.fillColor != null,
        fillColor: widget.fillColor,
        border: widget.borderRadius != null
            ? OutlineInputBorder(
                borderRadius: widget.borderRadius!,
                borderSide: BorderSide.none,
              )
            : null,
        enabledBorder: widget.borderRadius != null
            ? OutlineInputBorder(
                borderRadius: widget.borderRadius!,
                borderSide: BorderSide.none,
              )
            : null,
        focusedBorder: widget.borderRadius != null
            ? OutlineInputBorder(
                borderRadius: widget.borderRadius!,
                borderSide: const BorderSide(
                  color: SwBrandColors.primary,
                  width: 2,
                ),
              )
            : null,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: SwNeutralColors.gray500,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    return widget.suffixIcon;
  }
}
