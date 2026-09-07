import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_watch/core/routes/app_route.dart';
import 'package:safe_watch/core/theme/theme.dart';
import 'package:safe_watch/core/theme/custom_text_theme.dart';
import 'package:safe_watch/features/search/controllers/search_controller.dart';
import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/search/repositories/search_repository.dart';
import 'package:safe_watch/features/watched_list/controllers/watched_list_controller.dart';
import 'package:safe_watch/shared/widgets/sw_input_text_form.dart';

// ============================================================================
// Safe Watch — Search Template
// ============================================================================
// Tela de busca de séries e filmes.
//
// Fluxo de dados:
//   SearchTemplate (esta tela)
//     → ref.read(searchMediaControllerProvider.notifier).searchMedia(query)
//       → SearchRepository.searchMedia(query)
//         → retorna List<MediaModel>
//     → ref.watch(searchMediaControllerProvider) → AsyncValue<List<MediaModel>>
//       → .when() renderiza loading / data / error
// ============================================================================

/// Tela de busca de mídias do Safe Watch.
///
/// Permite ao usuário buscar filmes e séries por título.
/// Usa [ConsumerStatefulWidget] para manter o estado do campo de busca
/// e acessar providers Riverpod.
class SearchTemplate extends ConsumerStatefulWidget {
  const SearchTemplate({super.key});

  @override
  ConsumerState<SearchTemplate> createState() => _SearchTemplateState();
}

class _SearchTemplateState extends ConsumerState<SearchTemplate> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Observa o estado de busca via Riverpod.
    // AsyncValue gerencia automaticamente loading/data/error.
    final searchState = ref.watch(searchMediaControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Buscar',
          style: getTextStyle(
            context,
            typo: SwTypeTypography.title,
            color: SwNeutralColors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Minha Lista',
            onPressed: () => context.go(SwRoutes.watchedList),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Campo de Busca ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(SwSpacing.md),
            child: SwInputTextForm.search(
              controller: _searchController,
              hintText: 'Buscar séries e filmes...',
              autofocus: true,
              onFieldSubmitted: (query) {
                // Fluxo: Template → Controller → Repository → Model
                ref
                    .read(searchMediaControllerProvider.notifier)
                    .searchMedia(query);
              },
              onChanged: (query) {
                // Limpa resultados se o campo ficar vazio.
                if (query.isEmpty) {
                  ref
                      .read(searchMediaControllerProvider.notifier)
                      .clearResults();
                }
              },
            ),
          ),

          // ── Resultados da Busca ──────────────────────────────────
          Expanded(
            child: searchState.when(
              // Estado: Carregando
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),

              // Estado: Erro
              error: (error, stackTrace) => _SearchErrorWidget(error: error),

              // Estado: Dados carregados
              data: (mediaList) {
                if (mediaList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: SwNeutralColors.gray400,
                        ),
                        const SizedBox(height: SwSpacing.md),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Busque por séries e filmes'
                              : 'Nenhum resultado encontrado',
                          style: getTextStyle(
                            context,
                            typo: SwTypeTypography.body,
                            color: SwNeutralColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SwSpacing.md,
                  ),
                  itemCount: mediaList.length,
                  itemBuilder: (context, index) {
                    final media = mediaList[index];
                    return _MediaListItem(
                      media: media,
                      onAddToWatched: () {
                        // Fluxo: Template → WatchedListController → Repository
                        ref
                            .read(
                              watchedListControllerProvider.notifier,
                            )
                            .addToWatched(media);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '"${media.title}" adicionado à sua lista!',
                            ),
                            backgroundColor: SwSupportColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de erro amigável para a tela de busca.
///
/// Diferencia erros de API key ausente (com instruções) de erros gerais.
class _SearchErrorWidget extends StatelessWidget {
  const _SearchErrorWidget({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final isApiKeyError = error is ApiKeyMissingException;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SwSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApiKeyError ? Icons.key_off_outlined : Icons.wifi_off_rounded,
              size: 56,
              color: isApiKeyError
                  ? SwSupportColors.warning
                  : SwSupportColors.error,
            ),
            const SizedBox(height: SwSpacing.md),
            Text(
              isApiKeyError ? 'API Key não configurada' : 'Erro na busca',
              style: getTextStyle(
                context,
                typo: SwTypeTypography.subtitle,
                color: SwNeutralColors.gray800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SwSpacing.sm),
            Text(
              error.toString(),
              style: getTextStyle(
                context,
                typo: SwTypeTypography.caption,
                color: SwNeutralColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            if (isApiKeyError) ...[
              const SizedBox(height: SwSpacing.lg),
              Container(
                padding: const EdgeInsets.all(SwSpacing.md),
                decoration: BoxDecoration(
                  color: SwNeutralColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Obtenha sua chave gratuita em:\ntmdb.org/settings/api',
                  style: getTextStyle(
                    context,
                    typo: SwTypeTypography.caption,
                    color: SwBrandColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Item individual na lista de resultados de busca.
///
/// Exibe poster, título, ano, tipo e nota da mídia.
class _MediaListItem extends StatelessWidget {
  const _MediaListItem({
    required this.media,
    required this.onAddToWatched,
  });

  final MediaModel media;
  final VoidCallback onAddToWatched;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: SwSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.all(SwSpacing.sm),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 50,
            height: 75,
            color: SwNeutralColors.gray200,
            child: media.fullPosterUrl.isNotEmpty
                ? Image.network(
                    media.fullPosterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.movie,
                      color: SwNeutralColors.gray400,
                    ),
                  )
                : const Icon(
                    Icons.movie,
                    color: SwNeutralColors.gray400,
                  ),
          ),
        ),
        title: Text(
          media.title,
          style: getTextStyle(
            context,
            typo: SwTypeTypography.subtitle,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: SwSpacing.xxs),
            Row(
              children: [
                // Tipo de mídia
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SwSpacing.xs,
                    vertical: SwSpacing.xxxs,
                  ),
                  decoration: BoxDecoration(
                    color: media.mediaType == MediaType.tv
                        ? SwBrandColors.secondary.withValues(alpha: 0.15)
                        : SwBrandColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    media.mediaType == MediaType.tv ? 'Série' : 'Filme',
                    style: getTextStyle(
                      context,
                      typo: SwTypeTypography.caption,
                      color: media.mediaType == MediaType.tv
                          ? SwBrandColors.secondaryDark
                          : SwBrandColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: SwSpacing.xs),
                // Ano
                if (media.releaseYear.isNotEmpty)
                  Text(
                    media.releaseYear,
                    style: getTextStyle(
                      context,
                      typo: SwTypeTypography.caption,
                      color: SwNeutralColors.gray500,
                    ),
                  ),
                const SizedBox(width: SwSpacing.xs),
                // Nota
                const Icon(
                  Icons.star,
                  size: 14,
                  color: SwSupportColors.warning,
                ),
                const SizedBox(width: 2),
                Text(
                  media.voteAverage.toStringAsFixed(1),
                  style: getTextStyle(
                    context,
                    typo: SwTypeTypography.caption,
                    color: SwNeutralColors.gray600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SwSpacing.xxs),
            Text(
              media.overview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: getTextStyle(
                context,
                typo: SwTypeTypography.caption,
                color: SwNeutralColors.gray600,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.add_circle_outline,
            color: SwBrandColors.primary,
          ),
          tooltip: 'Adicionar à lista',
          onPressed: onAddToWatched,
        ),
      ),
    );
  }
}
