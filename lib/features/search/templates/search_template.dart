import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:safe_watch/core/theme/theme.dart';
import 'package:safe_watch/features/search/controllers/search_controller.dart';
import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/watched_list/controllers/watched_list_controller.dart';
import 'package:safe_watch/shared/widgets/sw_media_widgets.dart';

// ============================================================================
// Safe Watch — Search Template (aba "Explorar")
// ============================================================================
// Tela de exploração no estilo TV Time:
//   - Campo "Pesquisa" com sublinhado no topo
//   - Chips: FEED · DESCOBRIR · SÉRIES · FILMES (ativo em amarelo)
//   - Feed com cards grandes (backdrop + título + botão "+" amarelo)
//   - Ao digitar, mostra os resultados da busca
//
// Fluxo de dados:
//   SearchTemplate (esta tela)
//     → ref.read(searchMediaControllerProvider.notifier).searchMedia(query)
//       → SearchRepository.searchMedia(query) → List<MediaModel>
//     → ref.watch(trendingMediaProvider(type)) → feed
//     → ref.watch(popularMediaProvider(type)) → descobrir
// ============================================================================

/// Categorias de conteúdo exibidas nos chips.
enum _ExploreCategory {
  feed('FEED'),
  discover('DESCOBRIR'),
  tv('SÉRIES'),
  movies('FILMES');

  const _ExploreCategory(this.label);

  final String label;
}

/// Tela "Explorar" do Safe Watch.
class SearchTemplate extends ConsumerStatefulWidget {
  const SearchTemplate({super.key});

  @override
  ConsumerState<SearchTemplate> createState() => _SearchTemplateState();
}

class _SearchTemplateState extends ConsumerState<SearchTemplate> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  _ExploreCategory _category = _ExploreCategory.feed;

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchMediaControllerProvider.notifier).clearResults();
    _focusNode.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Campo de busca ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(SwSpacing.md, SwSpacing.xs, SwSpacing.md, 0),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: SwNeutralColors.white, fontSize: 17),
                cursorColor: SwBrandColors.primary,
                decoration: InputDecoration(
                  hintText: 'Pesquisa',
                  hintStyle: const TextStyle(color: SwNeutralColors.gray600, fontSize: 17),
                  prefixIcon: const Icon(Icons.search, color: SwNeutralColors.gray500, size: 26),
                  suffixIcon: _isSearching
                      ? IconButton(
                          tooltip: 'Limpar busca',
                          icon: const Icon(Icons.close, color: SwNeutralColors.gray500),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: SwNeutralColors.gray700),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: SwNeutralColors.gray700),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: SwNeutralColors.gray400),
                  ),
                ),
                onSubmitted: (query) {
                  // Fluxo: Template → Controller → Repository → Model
                  ref.read(searchMediaControllerProvider.notifier).searchMedia(query);
                },
                onChanged: (query) {
                  if (query.isEmpty) {
                    ref.read(searchMediaControllerProvider.notifier).clearResults();
                  }
                  setState(() {});
                },
              ),
            ),

            // ── Chips de categoria ─────────────────────────────────
            if (!_isSearching)
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: SwSpacing.sm, vertical: 10),
                  itemCount: _ExploreCategory.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: SwSpacing.xs),
                  itemBuilder: (context, index) {
                    final category = _ExploreCategory.values[index];
                    return _CategoryChip(
                      label: category.label,
                      selected: category == _category,
                      onTap: () => setState(() => _category = category),
                    );
                  },
                ),
              ),

            // ── Conteúdo ───────────────────────────────────────────
            Expanded(
              child: _isSearching
                  ? const _SearchResults()
                  : switch (_category) {
                      _ExploreCategory.feed => const _Feed(type: null),
                      _ExploreCategory.tv => const _Feed(type: MediaType.tv),
                      _ExploreCategory.movies => const _Feed(type: MediaType.movie),
                      _ExploreCategory.discover => const _Discover(),
                    },
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip arredondado: amarelo quando ativo, cinza escuro quando inativo.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? SwBrandColors.primary : SwSurfaceColors.chip,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? SwNeutralColors.black : SwNeutralColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Feed (cards grandes)
// ============================================================================

class _Feed extends ConsumerWidget {
  const _Feed({required this.type});

  /// `null` = séries e filmes misturados.
  final MediaType? type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = trendingMediaProvider(type);
    final state = ref.watch(provider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => SwErrorState(error: error, onRetry: () => ref.invalidate(provider)),
      data: (items) {
        if (items.isEmpty) {
          return const SwEmptyState(icon: Icons.explore_outlined, message: 'Nada por aqui ainda.');
        }
        return RefreshIndicator(
          color: SwBrandColors.primary,
          onRefresh: () => ref.refresh(provider.future),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: SwSpacing.lg),
            itemCount: items.length,
            itemBuilder: (context, index) => _FeedCard(media: items[index]),
          ),
        );
      },
    );
  }
}

/// Card grande do feed: backdrop, título com ícone, metadados e sinopse.
class _FeedCard extends ConsumerWidget {
  const _FeedCard({required this.media});

  final MediaModel media;

  String get _meta {
    final parts = <String>[
      if (media.releaseYear.isNotEmpty) media.releaseYear,
      media.isTvShow ? 'Série' : 'Filme',
      if (media.voteAverage > 0) '★ ${media.voteAverage.toStringAsFixed(1)}',
    ];
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inList = _isInList(ref, media);
    final imageUrl =
        media.fullBackdropUrl.isNotEmpty ? media.fullBackdropUrl : media.fullPosterUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SwSpacing.sm, 0, SwSpacing.sm, SwSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Material(
          color: SwSurfaceColors.feedPanel,
          child: InkWell(
            onTap: () => openMediaDetail(context, media),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SwPosterImage(url: imageUrl),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.45, 1.0],
                            colors: [Colors.transparent, Color(0xE6000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        top: SwSpacing.sm,
                        right: SwSpacing.sm,
                        child: _AddButton(
                          added: inList,
                          onPressed: inList ? null : () => _addToList(context, ref, media),
                        ),
                      ),
                      Positioned(
                        left: SwSpacing.sm,
                        right: SwSpacing.sm,
                        bottom: SwSpacing.sm,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  media.isTvShow ? Icons.tv_outlined : Icons.movie_creation_outlined,
                                  color: SwNeutralColors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    media.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: SwNeutralColors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _meta,
                              style: const TextStyle(color: SwNeutralColors.gray300, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (media.overview.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(SwSpacing.sm),
                    child: Text(
                      media.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SwNeutralColors.gray200,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão quadrado com borda amarela ("+" / "✓").
class _AddButton extends StatelessWidget {
  const _AddButton({required this.added, required this.onPressed});

  final bool added;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: added ? 'Já está na sua lista' : 'Adicionar à lista',
      child: Material(
        color: added ? SwBrandColors.primary : const Color(0x99000000),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: SwBrandColors.primary, width: 2),
          borderRadius: BorderRadius.circular(5),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              added ? Icons.check : Icons.add,
              color: added ? SwNeutralColors.black : SwBrandColors.primary,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Descobrir (prateleiras horizontais)
// ============================================================================

class _Discover extends StatelessWidget {
  const _Discover();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: SwSpacing.lg),
      children: [
        _Shelf(title: 'Séries populares', provider: popularMediaProvider(MediaType.tv)),
        _Shelf(title: 'Filmes populares', provider: popularMediaProvider(MediaType.movie)),
        _Shelf(title: 'No ar esta semana', provider: upcomingMediaProvider(MediaType.tv)),
        _Shelf(title: 'Em breve nos cinemas', provider: upcomingMediaProvider(MediaType.movie)),
      ],
    );
  }
}

class _Shelf extends ConsumerWidget {
  const _Shelf({required this.title, required this.provider});

  final String title;
  final FutureProvider<List<MediaModel>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwSectionHeader(title: title),
        SizedBox(
          height: 170,
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(provider),
                child: const Text('Tentar novamente'),
              ),
            ),
            data: (items) => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: SwSpacing.md),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final media = items[index];
                return SizedBox(
                  width: 113,
                  child: SwPosterTile(
                    imageUrl: media.fullPosterUrl,
                    semanticLabel: media.title,
                    borderRadius: 4,
                    onTap: () => openMediaDetail(context, media),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Resultados de busca
// ============================================================================

class _SearchResults extends ConsumerWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchMediaControllerProvider);

    return searchState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => SwErrorState(error: error),
      data: (mediaList) {
        if (mediaList.isEmpty) {
          return const SwEmptyState(
            icon: Icons.search,
            message: 'Pressione buscar no teclado para pesquisar\nséries e filmes.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: SwSpacing.xs),
          itemCount: mediaList.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
          itemBuilder: (context, index) => _SearchResultRow(media: mediaList[index]),
        );
      },
    );
  }
}

class _SearchResultRow extends ConsumerWidget {
  const _SearchResultRow({required this.media});

  final MediaModel media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inList = _isInList(ref, media);

    return InkWell(
      onTap: () => openMediaDetail(context, media),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SwSpacing.sm, vertical: SwSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 90,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SwPosterImage(url: media.fullPosterUrl),
              ),
            ),
            const SizedBox(width: SwSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        media.isTvShow ? Icons.tv_outlined : Icons.movie_creation_outlined,
                        size: 16,
                        color: SwNeutralColors.gray400,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          media.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SwNeutralColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (media.releaseYear.isNotEmpty) media.releaseYear,
                      media.isTvShow ? 'Série' : 'Filme',
                      if (media.voteAverage > 0) '★ ${media.voteAverage.toStringAsFixed(1)}',
                    ].join(' • '),
                    style: const TextStyle(color: SwNeutralColors.gray500, fontSize: 13),
                  ),
                  if (media.overview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      media.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: SwNeutralColors.gray400, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: SwSpacing.xs),
            _AddButton(
              added: inList,
              onPressed: inList ? null : () => _addToList(context, ref, media),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Helpers
// ============================================================================

/// Se a mídia já está na lista do usuário.
bool _isInList(WidgetRef ref, MediaModel media) {
  final items = ref.watch(watchedListControllerProvider).valueOrNull ?? const [];
  return items.any((i) => i.mediaId == media.id && i.mediaType == media.mediaType);
}

/// Adiciona à lista (Template → WatchedListController → Repository).
void _addToList(BuildContext context, WidgetRef ref, MediaModel media) {
  ref.read(watchedListControllerProvider.notifier).addToWatched(media);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('"${media.title}" adicionado à sua lista!'),
      duration: const Duration(seconds: 2),
    ),
  );
}
