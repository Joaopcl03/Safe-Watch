import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_watch/core/routes/app_route.dart';
import 'package:safe_watch/core/theme/theme.dart';
import 'package:safe_watch/features/search/models/media_model.dart';

// ============================================================================
// Safe Watch — Componentes visuais de mídia (estilo TV Time)
// ============================================================================
// Componentes reutilizados pelas telas Séries, Filmes, Explorar e Perfil:
//   - SwPosterTile: pôster 2:3 com barra de progresso amarela opcional
//   - SwSectionPill: rótulo cinza arredondado ("ASSISTIR A SEGUIR")
//   - SwGridToggleButton: botão amarelo de alternar grade/lista
//   - SwSectionHeader: título de seção com chevron ("Estatísticas  >")
//   - SwPosterImage: imagem de rede com placeholder escuro
// ============================================================================

/// Abre a tela de detalhes de uma mídia por cima do bottom nav.
void openMediaDetail(BuildContext context, MediaModel media) {
  context.push(SwRoutes.mediaDetail, extra: media);
}

/// Imagem de rede com placeholder escuro e ícone de fallback.
class SwPosterImage extends StatelessWidget {
  const SwPosterImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.movie_outlined,
    super.key,
  });

  final String url;
  final BoxFit fit;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: SwSurfaceColors.card,
      child: Center(
        child: Icon(fallbackIcon, color: SwNeutralColors.gray700, size: 32),
      ),
    );

    if (url.isEmpty) return placeholder;

    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const ColoredBox(color: SwSurfaceColors.card),
    );
  }
}

/// Pôster 2:3 com barra de progresso amarela opcional logo abaixo.
///
/// Se [progress] for `null`, a barra não é exibida.
class SwPosterTile extends StatelessWidget {
  const SwPosterTile({
    required this.imageUrl,
    required this.semanticLabel,
    this.progress,
    this.onTap,
    this.onLongPress,
    this.borderRadius = 2,
    super.key,
  });

  /// Altura da barra de progresso.
  static const double progressBarHeight = 7;

  final String imageUrl;
  final String semanticLabel;
  final double? progress;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SwPosterImage(url: imageUrl),
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(onTap: onTap, onLongPress: onLongPress),
                  ),
                ],
              ),
            ),
          ),
          if (progress != null)
            SizedBox(
              height: progressBarHeight,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: SwSurfaceColors.progressTrack,
                color: SwBrandColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Rótulo cinza arredondado usado como cabeçalho de seção.
class SwSectionPill extends StatelessWidget {
  const SwSectionPill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: SwSurfaceColors.pill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: SwNeutralColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Botão amarelo quadrado para alternar entre grade e lista.
class SwGridToggleButton extends StatelessWidget {
  const SwGridToggleButton({
    required this.isGrid,
    required this.onPressed,
    super.key,
  });

  final bool isGrid;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isGrid ? 'Mostrar em lista' : 'Mostrar em grade',
      child: Material(
        color: SwSurfaceColors.background,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: SwBrandColors.primary, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(
              isGrid ? Icons.grid_view_rounded : Icons.view_list_rounded,
              color: SwBrandColors.primary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de seção grande com chevron opcional ("Estatísticas  >").
class SwSectionHeader extends StatelessWidget {
  const SwSectionHeader({required this.title, this.onTap, super.key});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SwSpacing.md,
          SwSpacing.lg,
          SwSpacing.sm,
          SwSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: SwNeutralColors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: SwNeutralColors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

/// Estado vazio padrão (ícone + mensagem + ação opcional).
class SwEmptyState extends StatelessWidget {
  const SwEmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SwSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: SwNeutralColors.gray700),
            const SizedBox(height: SwSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: SwNeutralColors.gray500, fontSize: 15),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: SwSpacing.lg),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de erro padrão com botão "Tentar novamente".
class SwErrorState extends StatelessWidget {
  const SwErrorState({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final text = error.toString();
    final isApiKeyError = text.contains('API') || text.contains('401');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SwSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isApiKeyError ? Icons.key_off_outlined : Icons.wifi_off_rounded,
              size: 56,
              color: isApiKeyError ? SwBrandColors.primary : SwSupportColors.error,
            ),
            const SizedBox(height: SwSpacing.md),
            Text(
              isApiKeyError ? 'API Key não configurada' : 'Não foi possível carregar',
              style: const TextStyle(
                color: SwNeutralColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SwSpacing.xs),
            Text(
              isApiKeyError
                  ? 'Obtenha sua chave gratuita em tmdb.org/settings/api'
                  : text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: SwNeutralColors.gray500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: SwSpacing.lg),
              OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
            ],
          ],
        ),
      ),
    );
  }
}
