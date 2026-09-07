import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_watch/core/routes/app_route.dart';
import 'package:safe_watch/core/theme/theme.dart';
import 'package:safe_watch/core/theme/custom_text_theme.dart';
import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/watched_list/controllers/watched_list_controller.dart';
import 'package:safe_watch/features/watched_list/models/watched_item_model.dart';

// ============================================================================
// Safe Watch — Watched List Template
// ============================================================================
// Tela da lista de assistidos com tabs "Assistidos" e "Quero Assistir".
//
// Fluxo de dados:
//   WatchedListTemplate (esta tela)
//     → ref.watch(watchedListControllerProvider)
//       → AsyncValue<List<WatchedItemModel>>
//     → ref.read(watchedListControllerProvider.notifier).toggleStatus(id)
//       → WatchedListRepository.updateWatchedItem(...)
//         → persiste WatchedItemModel
//       → state atualizado → UI reconstruída
// ============================================================================

/// Tela da lista de assistidos do Safe Watch.
///
/// Exibe duas tabs:
/// - **Assistidos**: Itens já marcados como assistidos.
/// - **Quero Assistir**: Itens na lista de desejos.
///
/// Usa [ConsumerWidget] para acessar providers Riverpod.
class WatchedListTemplate extends ConsumerWidget {
  const WatchedListTemplate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa o estado da lista via Riverpod.
    // AsyncValue gerencia automaticamente loading/data/error.
    final watchedListState = ref.watch(watchedListControllerProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Minha Lista',
            style: getTextStyle(
              context,
              typo: SwTypeTypography.title,
              color: SwNeutralColors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Buscar',
              onPressed: () => context.go(SwRoutes.search),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: SwNeutralColors.white,
            labelColor: SwNeutralColors.white,
            unselectedLabelColor: SwNeutralColors.gray400,
            tabs: [
              Tab(
                icon: Icon(Icons.check_circle_outline),
                text: 'Assistidos',
              ),
              Tab(
                icon: Icon(Icons.bookmark_outline),
                text: 'Quero Assistir',
              ),
            ],
          ),
        ),
        body: watchedListState.when(
          // Estado: Carregando
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),

          // Estado: Erro
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: SwSupportColors.error,
                ),
                const SizedBox(height: SwSpacing.md),
                Text(
                  'Erro ao carregar lista: $error',
                  style: getTextStyle(
                    context,
                    typo: SwTypeTypography.body,
                    color: SwSupportColors.error,
                  ),
                ),
              ],
            ),
          ),

          // Estado: Dados carregados
          data: (items) {
            final watched = items
                .where((i) => i.status == WatchedStatus.watched)
                .toList();
            final wantToWatch = items
                .where((i) => i.status == WatchedStatus.wantToWatch)
                .toList();

            return TabBarView(
              children: [
                // ── Tab: Assistidos ────────────────────────────────
                _WatchedItemsList(
                  items: watched,
                  emptyMessage: 'Nenhum item assistido ainda',
                  emptyIcon: Icons.movie_outlined,
                ),

                // ── Tab: Quero Assistir ────────────────────────────
                _WatchedItemsList(
                  items: wantToWatch,
                  emptyMessage: 'Sua lista de desejos está vazia',
                  emptyIcon: Icons.bookmark_outline,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Lista de itens assistidos/quero assistir.
///
/// Widget interno reutilizado nas duas tabs.
class _WatchedItemsList extends ConsumerWidget {
  const _WatchedItemsList({
    required this.items,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  final List<WatchedItemModel> items;
  final String emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: SwNeutralColors.gray400),
            const SizedBox(height: SwSpacing.md),
            Text(
              emptyMessage,
              style: getTextStyle(
                context,
                typo: SwTypeTypography.body,
                color: SwNeutralColors.gray500,
              ),
            ),
            const SizedBox(height: SwSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => context.go(SwRoutes.search),
              icon: const Icon(Icons.search),
              label: const Text('Buscar mídias'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(SwSpacing.md),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _WatchedItemCard(item: item);
      },
    );
  }
}

/// Card individual de um item na lista.
class _WatchedItemCard extends ConsumerWidget {
  const _WatchedItemCard({required this.item});

  final WatchedItemModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: SwSpacing.lg),
        color: SwSupportColors.error,
        child: const Icon(Icons.delete, color: SwNeutralColors.white),
      ),
      onDismissed: (_) {
        // Fluxo: Template → Controller → Repository
        ref
            .read(watchedListControllerProvider.notifier)
            .removeFromWatched(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${item.title}" removido da lista')),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: SwSpacing.sm),
        child: ListTile(
          contentPadding: const EdgeInsets.all(SwSpacing.sm),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 75,
              color: SwNeutralColors.gray200,
              child: item.fullPosterUrl.isNotEmpty
                  ? Image.network(
                      item.fullPosterUrl,
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
            item.title,
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
                      color: item.mediaType == MediaType.tv
                          ? SwBrandColors.secondary.withValues(alpha: 0.15)
                          : SwBrandColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.mediaType == MediaType.tv ? 'Série' : 'Filme',
                      style: getTextStyle(
                        context,
                        typo: SwTypeTypography.caption,
                        color: item.mediaType == MediaType.tv
                            ? SwBrandColors.secondaryDark
                            : SwBrandColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: SwSpacing.xs),
                  // Progresso (para séries)
                  if (item.isTvShow)
                    Text(
                      item.progressText,
                      style: getTextStyle(
                        context,
                        typo: SwTypeTypography.caption,
                        color: SwNeutralColors.gray500,
                      ),
                    ),
                  // Nota
                  const SizedBox(width: SwSpacing.xs),
                  const Icon(
                    Icons.star,
                    size: 14,
                    color: SwSupportColors.warning,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    item.voteAverage.toStringAsFixed(1),
                    style: getTextStyle(
                      context,
                      typo: SwTypeTypography.caption,
                      color: SwNeutralColors.gray600,
                    ),
                  ),
                ],
              ),
              // Data de quando assistiu
              if (item.watchedAt != null) ...[
                const SizedBox(height: SwSpacing.xxs),
                Text(
                  'Assistido em ${_formatDate(item.watchedAt!)}',
                  style: getTextStyle(
                    context,
                    typo: SwTypeTypography.caption,
                    color: SwNeutralColors.gray500,
                  ),
                ),
              ],
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              item.status == WatchedStatus.watched
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
              color: item.status == WatchedStatus.watched
                  ? SwSupportColors.success
                  : SwNeutralColors.gray400,
            ),
            tooltip: item.status == WatchedStatus.watched
                ? 'Marcar como não assistido'
                : 'Marcar como assistido',
            onPressed: () {
              // Fluxo: Template → Controller → Repository
              ref
                  .read(watchedListControllerProvider.notifier)
                  .toggleStatus(item.id);
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
