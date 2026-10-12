import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_watch/core/api/api_config.dart';
import 'package:safe_watch/core/theme/theme.dart';
import 'package:safe_watch/core/theme/custom_text_theme.dart';
import 'package:safe_watch/features/search/controllers/search_controller.dart';
import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/search/models/season_model.dart';
import 'package:safe_watch/features/search/models/streaming_source_model.dart';
import 'package:safe_watch/features/watched_list/controllers/watched_list_controller.dart';
import 'package:safe_watch/features/watched_list/models/watched_item_model.dart';

// ============================================================================
// Safe Watch — Media Detail Template
// ============================================================================
// Tela de detalhes de uma mídia (filme ou série).
// Exibe backdrop, poster, sinopse, temporadas/episódios e streaming.
//
// Fluxo de dados:
//   MediaDetailTemplate (esta tela)
//     → ref.read(searchMediaControllerProvider.notifier).getTvDetails(tmdbId)
//       → SearchRepository.getTvDetails(tmdbId)
//         → TmdbClient.getTvDetails(tmdbId)
//     → MediaModel com temporadas + external_ids
// ============================================================================

/// Tela de detalhes de uma mídia.
///
/// Recebe um [MediaModel] básico (da busca) e carrega detalhes completos
/// ao montar a tela.
class MediaDetailTemplate extends ConsumerStatefulWidget {
  const MediaDetailTemplate({required this.media, super.key});

  /// Mídia básica vinda da busca (sem temporadas detalhadas).
  final MediaModel media;

  @override
  ConsumerState<MediaDetailTemplate> createState() => _MediaDetailTemplateState();
}

class _MediaDetailTemplateState extends ConsumerState<MediaDetailTemplate> {
  MediaModel? _detailedMedia;
  List<StreamingSourceModel> _streamingSources = [];
  bool _isLoadingDetails = true;
  bool _isLoadingSources = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final controller = ref.read(searchMediaControllerProvider.notifier);

      // Carregar detalhes completos.
      final details = widget.media.isTvShow
          ? await controller.getTvDetails(widget.media.id)
          : await controller.getMovieDetails(widget.media.id);

      if (mounted) {
        setState(() {
          _detailedMedia = details;
          _isLoadingDetails = false;
        });
      }

      // Carregar fontes de streaming em paralelo.
      _loadStreamingSources();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _loadStreamingSources() async {
    setState(() => _isLoadingSources = true);
    try {
      final controller = ref.read(searchMediaControllerProvider.notifier);
      final sources = await controller.getStreamingSources(
        widget.media.id,
        widget.media.mediaType,
      );
      if (mounted) {
        setState(() {
          _streamingSources = sources;
          _isLoadingSources = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSources = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = _detailedMedia ?? widget.media;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar com Backdrop ──────────────────────────────
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                media.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(blurRadius: 8, color: Colors.black54),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (media.backdropPath.isNotEmpty)
                    Image.network(
                      ApiConfig.tmdbBackdropUrl(media.backdropPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: SwSurfaceColors.card,
                      ),
                    )
                  else
                    Container(color: SwSurfaceColors.card),
                  // Gradient overlay para legibilidade do título.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(SwSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Poster + Info básica ─────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 120,
                          height: 180,
                          child: media.posterPath.isNotEmpty
                              ? Image.network(
                                  media.fullPosterUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: SwSurfaceColors.card,
                                    child: const Icon(Icons.movie, size: 48, color: SwNeutralColors.gray700),
                                  ),
                                )
                              : Container(
                                  color: SwSurfaceColors.card,
                                  child: const Icon(Icons.movie, size: 48, color: SwNeutralColors.gray700),
                                ),
                        ),
                      ),
                      const SizedBox(width: SwSpacing.md),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tipo + Ano
                            Row(
                              children: [
                                _MediaTypeBadge(mediaType: media.mediaType),
                                const SizedBox(width: SwSpacing.xs),
                                if (media.releaseYear.isNotEmpty)
                                  Text(
                                    media.releaseYear,
                                    style: getTextStyle(context, typo: SwTypeTypography.body, color: SwNeutralColors.gray600),
                                  ),
                              ],
                            ),
                            const SizedBox(height: SwSpacing.sm),
                            // Nota
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: SwSupportColors.warning, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  media.voteAverage.toStringAsFixed(1),
                                  style: getTextStyle(context, typo: SwTypeTypography.subtitle),
                                ),
                                Text(
                                  ' / 10',
                                  style: getTextStyle(context, typo: SwTypeTypography.caption, color: SwNeutralColors.gray500),
                                ),
                              ],
                            ),
                            const SizedBox(height: SwSpacing.sm),
                            // Status + Temporadas
                            if (media.status.isNotEmpty)
                              Text(
                                media.status,
                                style: getTextStyle(context, typo: SwTypeTypography.caption, color: SwNeutralColors.gray600),
                              ),
                            if (media.isTvShow && media.numberOfSeasons > 0) ...[
                              const SizedBox(height: SwSpacing.xxs),
                              Text(
                                '${media.numberOfSeasons} temporada${media.numberOfSeasons > 1 ? 's' : ''} \u2022 ${media.numberOfEpisodes} epis\u00f3dios',
                                style: getTextStyle(context, typo: SwTypeTypography.caption, color: SwNeutralColors.gray500),
                              ),
                            ],
                            if (_isLoadingDetails)
                              const Padding(
                                padding: EdgeInsets.only(top: SwSpacing.sm),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: SwSpacing.lg),

                  // ── Botões de ação ────────────────────────────
                  _ActionButtons(media: media),

                  const SizedBox(height: SwSpacing.lg),

                  // ── Sinopse ───────────────────────────────────
                  if (media.overview.isNotEmpty) ...[
                    Text(
                      'Sinopse',
                      style: getTextStyle(context, typo: SwTypeTypography.subtitle),
                    ),
                    const SizedBox(height: SwSpacing.xs),
                    Text(
                      media.overview,
                      style: getTextStyle(context, typo: SwTypeTypography.body, color: SwNeutralColors.gray300),
                    ),
                    const SizedBox(height: SwSpacing.lg),
                  ],

                  // ── Onde Assistir ──────────────────────────────
                  if (_streamingSources.isNotEmpty || _isLoadingSources) ...[
                    Text(
                      'Onde Assistir',
                      style: getTextStyle(context, typo: SwTypeTypography.subtitle),
                    ),
                    const SizedBox(height: SwSpacing.xs),
                    if (_isLoadingSources)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(SwSpacing.md),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      _StreamingSourcesList(sources: _streamingSources),
                    const SizedBox(height: SwSpacing.lg),
                  ],

                  // ── Erro ──────────────────────────────────────
                  if (_errorMessage != null)
                    Text(
                      'Erro ao carregar detalhes: $_errorMessage',
                      style: getTextStyle(context, typo: SwTypeTypography.caption, color: SwSupportColors.error),
                    ),
                ],
              ),
            ),
          ),

          // ── Temporadas (para séries) ───────────────────────────
          if (media.isTvShow && media.seasons.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: SwSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temporadas',
                      style: getTextStyle(context, typo: SwTypeTypography.subtitle),
                    ),
                    const SizedBox(height: SwSpacing.xs),
                  ],
                ),
              ),
            ),

          if (media.isTvShow && media.seasons.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final season = media.seasons[index];
                  // Filtrar specials (season 0) se não houver nome.
                  if (season.seasonNumber == 0 && season.name.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return _SeasonCard(
                    season: season,
                    seriesTmdbId: media.id,
                  );
                },
                childCount: media.seasons.length,
              ),
            ),

          // Espaço final
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }
}

/// Badge do tipo de mídia (Série/Filme).
class _MediaTypeBadge extends StatelessWidget {
  const _MediaTypeBadge({required this.mediaType});
  final MediaType mediaType;

  @override
  Widget build(BuildContext context) {
    final isTv = mediaType == MediaType.tv;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SwSpacing.xs, vertical: SwSpacing.xxxs),
      decoration: BoxDecoration(
        color: (isTv ? SwBrandColors.secondary : SwBrandColors.primary).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isTv ? 'S\u00e9rie' : 'Filme',
        style: getTextStyle(
          context,
          typo: SwTypeTypography.caption,
          color: isTv ? SwBrandColors.secondaryDark : SwBrandColors.primaryDark,
        ),
      ),
    );
  }
}

/// Botões de ação (Quero Assistir, Assistido, Check-in).
class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.media});
  final MediaModel media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(watchedListControllerProvider.notifier).addToWatched(media);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${media.title}" adicionado \u00e0 lista'),
                  backgroundColor: SwSupportColors.success,
                ),
              );
            },
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Quero Assistir'),
          ),
        ),
        const SizedBox(width: SwSpacing.sm),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              final item = WatchedItemModel.fromMedia(media, status: WatchedStatus.watched);
              ref.read(watchedListControllerProvider.notifier).addToWatched(media);
              ref.read(watchedListControllerProvider.notifier).toggleStatus(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${media.title}" marcado como assistido'),
                  backgroundColor: SwSupportColors.success,
                ),
              );
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Assistido'),
          ),
        ),
      ],
    );
  }
}

/// Lista horizontal de fontes de streaming.
class _StreamingSourcesList extends StatelessWidget {
  const _StreamingSourcesList({required this.sources});
  final List<StreamingSourceModel> sources;

  @override
  Widget build(BuildContext context) {
    // Agrupar por tipo.
    final subscriptions = sources.where((s) => s.type == StreamingType.subscription).toList();
    final free = sources.where((s) => s.type == StreamingType.free).toList();
    final rent = sources.where((s) => s.type == StreamingType.rent).toList();
    final buy = sources.where((s) => s.type == StreamingType.buy).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subscriptions.isNotEmpty) _sourceGroup(context, 'Assinatura', subscriptions),
        if (free.isNotEmpty) _sourceGroup(context, 'Gr\u00e1tis', free),
        if (rent.isNotEmpty) _sourceGroup(context, 'Aluguel', rent),
        if (buy.isNotEmpty) _sourceGroup(context, 'Compra', buy),
      ],
    );
  }

  Widget _sourceGroup(BuildContext context, String label, List<StreamingSourceModel> sources) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SwSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: getTextStyle(context, typo: SwTypeTypography.caption, color: SwNeutralColors.gray500),
          ),
          const SizedBox(height: SwSpacing.xxs),
          Wrap(
            spacing: SwSpacing.xs,
            runSpacing: SwSpacing.xs,
            children: sources.map((source) {
              return Chip(
                avatar: const Icon(Icons.play_circle_outline, size: 18, color: SwBrandColors.primary),
                label: Text(
                  source.price != null ? '${source.name} (R\$ ${source.price!.toStringAsFixed(2)})' : source.name,
                  style: getTextStyle(context, typo: SwTypeTypography.caption, color: SwNeutralColors.white),
                ),
                backgroundColor: SwSurfaceColors.card,
                side: const BorderSide(color: SwSurfaceColors.cardBorder),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Card de temporada com expansão para episódios.
class _SeasonCard extends ConsumerStatefulWidget {
  const _SeasonCard({required this.season, required this.seriesTmdbId});
  final SeasonModel season;
  final int seriesTmdbId;

  @override
  ConsumerState<_SeasonCard> createState() => _SeasonCardState();
}

class _SeasonCardState extends ConsumerState<_SeasonCard> {
  bool _isExpanded = false;
  SeasonModel? _detailedSeason;
  bool _isLoadingEpisodes = false;

  Future<void> _loadEpisodes() async {
    if (_detailedSeason != null) return;
    setState(() => _isLoadingEpisodes = true);
    try {
      final controller = ref.read(searchMediaControllerProvider.notifier);
      final season = await controller.getSeasonDetails(
        widget.seriesTmdbId,
        widget.season.seasonNumber,
      );
      if (mounted) {
        setState(() {
          _detailedSeason = season;
          _isLoadingEpisodes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingEpisodes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final season = _detailedSeason ?? widget.season;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: SwSpacing.md,
        vertical: SwSpacing.xxs,
      ),
      child: Column(
        children: [
          ListTile(
            leading: season.posterPath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 40,
                      height: 60,
                      child: Image.network(
                        ApiConfig.tmdbImageUrl(season.posterPath, size: 'w154'),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: SwSurfaceColors.card,
                          child: const Icon(Icons.tv, size: 20, color: SwNeutralColors.gray700),
                        ),
                      ),
                    ),
                  )
                : null,
            title: Text(
              season.name,
              style: getTextStyle(context, typo: SwTypeTypography.body),
            ),
            subtitle: Text(
              '${season.episodeCount} epis\u00f3dios${season.airYear.isNotEmpty ? ' \u2022 ${season.airYear}' : ''}',
              style: getTextStyle(context, typo: SwTypeTypography.caption, color: SwNeutralColors.gray500),
            ),
            trailing: _isLoadingEpisodes
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
              if (_isExpanded) _loadEpisodes();
            },
          ),
          if (_isExpanded && season.episodes.isNotEmpty)
            ...season.episodes.map((episode) => ListTile(
                  dense: true,
                  leading: Text(
                    episode.episodeCode,
                    style: getTextStyle(context, typo: SwTypeTypography.caption, color: SwBrandColors.primary),
                  ),
                  title: Text(
                    episode.name,
                    style: getTextStyle(context, typo: SwTypeTypography.body),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: episode.runtimeFormatted.isNotEmpty
                      ? Text(
                          episode.runtimeFormatted,
                          style: getTextStyle(context, typo: SwTypeTypography.caption, color: SwNeutralColors.gray500),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (episode.voteAverage > 0) ...[
                        const Icon(Icons.star_rounded, size: 14, color: SwSupportColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          episode.voteAverage.toStringAsFixed(1),
                          style: getTextStyle(context, typo: SwTypeTypography.caption, color: SwNeutralColors.gray600),
                        ),
                      ],
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
