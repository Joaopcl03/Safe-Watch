import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_watch/core/routes/app_route.dart';
import 'package:safe_watch/core/theme/theme.dart';
import 'package:safe_watch/features/search/controllers/search_controller.dart';
import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/watched_list/controllers/watched_list_controller.dart';
import 'package:safe_watch/features/watched_list/models/watched_item_model.dart';
import 'package:safe_watch/shared/widgets/sw_media_widgets.dart';

// ============================================================================
// Safe Watch — Watched List Template (Séries / Filmes)
// ============================================================================
// Tela principal de Séries (tela inicial) e de Filmes, no estilo TV Time:
//   - Abas "MINHA LISTA" e "EM BREVE"
//   - Seções com rótulo cinza ("ASSISTIR A SEGUIR", "NÃO INICIADAS"...)
//   - Grade de pôsteres 3 colunas com barra de progresso amarela
//   - Botão amarelo para alternar grade/lista
//
// Fluxo de dados:
//   WatchedListTemplate (esta tela)
//     → ref.watch(watchedListControllerProvider)
//       → AsyncValue<List<WatchedItemModel>> (filtrado por mediaType)
//     → ref.watch(upcomingMediaProvider(mediaType)) → aba "Em breve"
//     → ref.read(watchedListControllerProvider.notifier).toggleStatus(id)
//       → WatchedListRepository.updateWatchedItem(...)
// ============================================================================

/// Após quantos dias sem atividade uma série vai para "sem assistir há algum tempo".
const _staleAfter = Duration(days: 30);

/// Tela de biblioteca do usuário para um [mediaType] (séries ou filmes).
class WatchedListTemplate extends StatelessWidget {
  const WatchedListTemplate({required this.mediaType, super.key});

  /// Tipo de mídia exibido: [MediaType.tv] (Séries) ou [MediaType.movie] (Filmes).
  final MediaType mediaType;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const TabBar(
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'MINHA LISTA'),
                  Tab(text: 'EM BREVE'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _MyListTab(mediaType: mediaType),
                    _ComingSoonTab(mediaType: mediaType),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Aba "Minha Lista"
// ============================================================================

/// Seção agrupada da lista do usuário.
class _Section {
  const _Section(this.label, this.items, {this.showProgress = false});

  final String label;
  final List<WatchedItemModel> items;
  final bool showProgress;
}

class _MyListTab extends ConsumerStatefulWidget {
  const _MyListTab({required this.mediaType});

  final MediaType mediaType;

  @override
  ConsumerState<_MyListTab> createState() => _MyListTabState();
}

class _MyListTabState extends ConsumerState<_MyListTab>
    with AutomaticKeepAliveClientMixin {
  bool _isGrid = true;

  @override
  bool get wantKeepAlive => true;

  bool get _isTv => widget.mediaType == MediaType.tv;

  /// Agrupa os itens nas seções exibidas na tela.
  List<_Section> _buildSections(List<WatchedItemModel> all) {
    final items = all.where((i) => i.mediaType == widget.mediaType).toList();

    if (!_isTv) {
      return [
        _Section(
          'Assistir a seguir',
          items.where((i) => i.status == WatchedStatus.wantToWatch).toList(),
        ),
        _Section(
          'Assistidos',
          items.where((i) => i.status == WatchedStatus.watched).toList(),
        ),
      ].where((s) => s.items.isNotEmpty).toList();
    }

    final now = DateTime.now();
    final upNext = <WatchedItemModel>[];
    final stale = <WatchedItemModel>[];
    final notStarted = <WatchedItemModel>[];
    final finished = <WatchedItemModel>[];

    for (final item in items) {
      final markedFinished = item.status == WatchedStatus.watched &&
          (item.isCompleted || !item.hasStarted);
      if (markedFinished) {
        finished.add(item);
      } else if (item.hasStarted) {
        final last = item.watchedAt;
        final isStale = last != null && now.difference(last) > _staleAfter;
        (isStale ? stale : upNext).add(item);
      } else {
        notStarted.add(item);
      }
    }

    return [
      _Section('Assistir a seguir', upNext, showProgress: true),
      _Section('Não iniciadas', notStarted),
      _Section('Sem assistir há algum tempo', stale, showProgress: true),
      _Section('Concluídas', finished, showProgress: true),
    ].where((s) => s.items.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(watchedListControllerProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => SwErrorState(
        error: error,
        onRetry: () => ref.invalidate(watchedListControllerProvider),
      ),
      data: (items) {
        final sections = _buildSections(items);

        if (sections.isEmpty) {
          return SwEmptyState(
            icon: _isTv ? Icons.tv_outlined : Icons.movie_creation_outlined,
            message: _isTv
                ? 'Você ainda não adicionou nenhuma série.\nEncontre algo para assistir!'
                : 'Você ainda não adicionou nenhum filme.\nEncontre algo para assistir!',
            actionLabel: 'EXPLORAR',
            onAction: () => context.go(SwRoutes.search),
          );
        }

        return CustomScrollView(
          slivers: [
            for (var i = 0; i < sections.length; i++) ...[
              SliverToBoxAdapter(
                child: _SectionHeaderRow(
                  label: sections[i].label,
                  trailing: i == 0
                      ? SwGridToggleButton(
                          isGrid: _isGrid,
                          onPressed: () => setState(() => _isGrid = !_isGrid),
                        )
                      : null,
                ),
              ),
              if (_isGrid)
                _PosterGrid(section: sections[i])
              else
                _ItemList(section: sections[i]),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: SwSpacing.lg)),
          ],
        );
      },
    );
  }
}

/// Linha de cabeçalho: rótulo cinza centralizado + ação opcional à direita.
class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(SwSpacing.sm, 14, SwSpacing.sm, 10),
      child: SizedBox(
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SwSectionPill(label: label),
            if (trailing != null)
              Align(alignment: Alignment.centerRight, child: trailing),
          ],
        ),
      ),
    );
  }
}

/// Grade de pôsteres 3 colunas.
class _PosterGrid extends ConsumerWidget {
  const _PosterGrid({required this.section});

  final _Section section;

  static const double _spacing = 5;
  static const double _hPadding = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: _hPadding),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width =
              (constraints.crossAxisExtent - 2 * _hPadding - 2 * _spacing) / 3;
          final extent = width * 1.5 +
              (section.showProgress ? SwPosterTile.progressBarHeight : 0);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: _spacing,
              crossAxisSpacing: _spacing,
              mainAxisExtent: extent,
            ),
            delegate: SliverChildBuilderDelegate(
              childCount: section.items.length,
              (context, index) {
                final item = section.items[index];
                return SwPosterTile(
                  imageUrl: item.fullPosterUrl,
                  semanticLabel: item.title,
                  progress: section.showProgress ? item.progressFraction : null,
                  onTap: () => openMediaDetail(context, item.toMedia()),
                  onLongPress: () => _showItemActions(context, ref, item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Lista detalhada (modo alternativo ao de grade).
class _ItemList extends ConsumerWidget {
  const _ItemList({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverList.separated(
      itemCount: section.items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 88),
      itemBuilder: (context, index) {
        final item = section.items[index];
        final watched = item.status == WatchedStatus.watched;

        return InkWell(
          onTap: () => openMediaDetail(context, item.toMedia()),
          onLongPress: () => _showItemActions(context, ref, item),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SwSpacing.sm,
              vertical: SwSpacing.xs,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 96,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SwPosterImage(url: item.fullPosterUrl),
                  ),
                ),
                const SizedBox(width: SwSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SwNeutralColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.isTvShow
                            ? item.progressText
                            : (watched ? 'Assistido' : 'Não assistido'),
                        style: const TextStyle(
                          color: SwNeutralColors.gray500,
                          fontSize: 13,
                        ),
                      ),
                      if (section.showProgress) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: item.progressFraction,
                            minHeight: 4,
                            backgroundColor: SwSurfaceColors.progressTrack,
                            color: SwBrandColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: watched
                      ? 'Marcar como não assistido'
                      : 'Marcar como assistido',
                  icon: Icon(
                    watched ? Icons.check_circle : Icons.check_circle_outline,
                    color: watched
                        ? SwBrandColors.primary
                        : SwNeutralColors.gray600,
                    size: 30,
                  ),
                  onPressed: () => ref
                      .read(watchedListControllerProvider.notifier)
                      .toggleStatus(item.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bottom sheet com ações do item (pressionar e segurar o pôster).
void _showItemActions(
  BuildContext context,
  WidgetRef ref,
  WatchedItemModel item,
) {
  final watched = item.status == WatchedStatus.watched;
  final notifier = ref.read(watchedListControllerProvider.notifier);

  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SwSpacing.md,
              0,
              SwSpacing.md,
              SwSpacing.sm,
            ),
            child: Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SwNeutralColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Ver detalhes'),
            onTap: () {
              Navigator.pop(sheetContext);
              openMediaDetail(context, item.toMedia());
            },
          ),
          ListTile(
            leading: Icon(
              watched ? Icons.remove_done : Icons.check_circle_outline,
              color: SwBrandColors.primary,
            ),
            title: Text(
              watched ? 'Marcar como não assistido' : 'Marcar como assistido',
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              notifier.toggleStatus(item.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: SwSupportColors.error),
            title: const Text('Remover da lista'),
            onTap: () {
              Navigator.pop(sheetContext);
              notifier.removeFromWatched(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${item.title}" removido da lista')),
              );
            },
          ),
        ],
      ),
    ),
  );
}

// ============================================================================
// Aba "Em breve"
// ============================================================================

class _ComingSoonTab extends ConsumerWidget {
  const _ComingSoonTab({required this.mediaType});

  final MediaType mediaType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = upcomingMediaProvider(mediaType);
    final state = ref.watch(provider);
    final isTv = mediaType == MediaType.tv;

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => SwErrorState(
        error: error,
        onRetry: () => ref.invalidate(provider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const SwEmptyState(
            icon: Icons.event_outlined,
            message: 'Nada previsto por enquanto.',
          );
        }

        return RefreshIndicator(
          color: SwBrandColors.primary,
          onRefresh: () => ref.refresh(provider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _SectionHeaderRow(
                  label: isTv ? 'No ar esta semana' : 'Lançamentos em breve',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 5,
                    childAspectRatio: 0.52,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    childCount: items.length,
                    (context, index) => _UpcomingTile(media: items[index]),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: SwSpacing.lg)),
            ],
          ),
        );
      },
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.media});

  final MediaModel media;

  String get _dateLabel {
    final date = DateTime.tryParse(media.releaseDate);
    if (date == null) return media.releaseYear;
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SwPosterTile(
            imageUrl: media.fullPosterUrl,
            semanticLabel: media.title,
            onTap: () => openMediaDetail(context, media),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          media.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SwNeutralColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          _dateLabel,
          style: const TextStyle(color: SwBrandColors.primary, fontSize: 11),
        ),
      ],
    );
  }
}
