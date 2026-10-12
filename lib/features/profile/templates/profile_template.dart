import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_watch/core/config/env_config.dart';
import 'package:safe_watch/core/routes/app_route.dart';
import 'package:safe_watch/core/theme/theme.dart';
import 'package:safe_watch/features/auth/controllers/auth_controller.dart';
import 'package:safe_watch/features/auth/models/auth_state.dart';
import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/watched_list/controllers/watched_list_controller.dart';
import 'package:safe_watch/features/watched_list/models/watched_item_model.dart';
import 'package:safe_watch/shared/widgets/sw_media_widgets.dart';

// ============================================================================
// Safe Watch — Profile Template
// ============================================================================
// Tela de perfil no estilo TV Time:
//   - Cabeçalho com imagem de fundo, sino amarelo, menu "•••", avatar e EDITAR
//   - Contadores (séries · filmes · assistidos)
//   - Estatísticas em cards horizontais (tempo vendo TV, episódios...)
//   - Listas (colagem de pôsteres com indicador de página)
//   - Prateleiras de Séries e Filmes
//   - Menu "•••" com conexão Trakt, configurações e logout
//
// Fluxo de dados:
//   ProfileTemplate (esta tela)
//     → ref.watch(authControllerProvider) → AuthState
//     → ref.watch(watchedListControllerProvider) → estatísticas
// ============================================================================

/// Estimativas usadas no cálculo de tempo assistido (sem dados reais de duração).
const _avgEpisodeMinutes = 45;
const _avgMovieMinutes = 120;
const _avgEpisodesPerSeason = 10;

/// Tela de perfil do usuário.
class ProfileTemplate extends ConsumerWidget {
  const ProfileTemplate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final items = ref.watch(watchedListControllerProvider).valueOrNull ?? const [];

    final series = items.where((i) => i.mediaType == MediaType.tv).toList();
    final movies = items.where((i) => i.mediaType == MediaType.movie).toList();
    final watched = items.where((i) => i.status == WatchedStatus.watched).toList();
    final wantToWatch = items.where((i) => i.status == WatchedStatus.wantToWatch).toList();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ProfileHeader(
            authState: authState,
            backgroundUrl: items.isNotEmpty ? items.first.fullPosterUrl : '',
          ),
          _CountersRow(
            counters: [
              (series.length, series.length == 1 ? 'série' : 'séries'),
              (movies.length, movies.length == 1 ? 'filme' : 'filmes'),
              (watched.length, watched.length == 1 ? 'assistido' : 'assistidos'),
            ],
          ),

          // ── Estatísticas ─────────────────────────────────────
          const SwSectionHeader(title: 'Estatísticas'),
          _StatsCarousel(series: series, movies: movies),

          // ── Listas ───────────────────────────────────────────
          SwSectionHeader(
            title: 'Listas',
            onTap: () => context.go(SwRoutes.series),
          ),
          _ListsCarousel(
            lists: [
              ('Quero assistir', wantToWatch),
              ('Assistidos', watched),
            ],
          ),

          // ── Séries ───────────────────────────────────────────
          SwSectionHeader(
            title: 'Séries',
            onTap: () => context.go(SwRoutes.series),
          ),
          _PosterShelf(items: series, emptyMessage: 'Nenhuma série adicionada'),

          // ── Filmes ───────────────────────────────────────────
          SwSectionHeader(
            title: 'Filmes',
            onTap: () => context.go(SwRoutes.movies),
          ),
          _PosterShelf(items: movies, emptyMessage: 'Nenhum filme adicionado'),

          const SizedBox(height: SwSpacing.xl),
          const Center(
            child: Text(
              'Safe Watch v1.0.0',
              style: TextStyle(color: SwNeutralColors.gray700, fontSize: 12),
            ),
          ),
          const SizedBox(height: SwSpacing.lg),
        ],
      ),
    );
  }
}

// ============================================================================
// Cabeçalho
// ============================================================================

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.authState, required this.backgroundUrl});

  final AuthState authState;
  final String backgroundUrl;

  @override
  Widget build(BuildContext context) {
    final name = authState.isAuthenticated ? (authState.userName ?? 'Usuário') : 'Visitante';
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 230 + topInset,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo: pôster desfocado (ou gradiente se a lista estiver vazia).
          if (backgroundUrl.isNotEmpty)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: SwPosterImage(url: backgroundUrl),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2B3442), Color(0xFF0B0D12)],
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0xEE000000)],
              ),
            ),
          ),

          // Barra superior: sino + menu.
          Positioned(
            top: topInset + SwSpacing.xs,
            left: SwSpacing.sm,
            right: SwSpacing.xs,
            child: Row(
              children: [
                Material(
                  color: SwBrandColors.primary,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Notificações',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.notifications_none, color: SwNeutralColors.black),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nenhuma notificação no momento')),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Mais opções',
                  icon: const Icon(Icons.more_horiz, color: SwNeutralColors.white, size: 32),
                  onPressed: () => _showSettingsSheet(context),
                ),
              ],
            ),
          ),

          // Avatar + nome + EDITAR.
          Positioned(
            left: SwSpacing.md,
            right: SwSpacing.md,
            bottom: SwSpacing.lg,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: SwNeutralColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: SwSurfaceColors.card,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: SwBrandColors.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: SwSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SwNeutralColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 30,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            side: const BorderSide(color: SwNeutralColors.white, width: 1.5),
                          ),
                          onPressed: () => _showSettingsSheet(context),
                          child: const Text(
                            'EDITAR',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Contadores
// ============================================================================

class _CountersRow extends StatelessWidget {
  const _CountersRow({required this.counters});

  final List<(int, String)> counters;

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(color: SwSurfaceColors.divider);

    return Container(
      height: 76,
      decoration: const BoxDecoration(border: Border(top: border, bottom: border)),
      child: Row(
        children: [
          for (var i = 0; i < counters.length; i++) ...[
            if (i > 0) const VerticalDivider(width: 1, color: SwSurfaceColors.divider),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${counters[i].$1}',
                    style: const TextStyle(
                      color: SwNeutralColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    counters[i].$2,
                    style: const TextStyle(color: SwNeutralColors.gray300, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// Estatísticas
// ============================================================================

class _StatsCarousel extends StatelessWidget {
  const _StatsCarousel({required this.series, required this.movies});

  final List<WatchedItemModel> series;
  final List<WatchedItemModel> movies;

  /// Estimativa de episódios assistidos com base no progresso salvo.
  int get _episodesWatched {
    var total = 0;
    for (final s in series) {
      if (s.status == WatchedStatus.watched && s.totalSeasons > 0 && s.isCompleted) {
        total += s.totalSeasons * _avgEpisodesPerSeason;
      } else if (s.hasStarted) {
        final previousSeasons = (s.seasonProgress - 1).clamp(0, 999);
        total += previousSeasons * _avgEpisodesPerSeason + s.episodeProgress;
      }
    }
    return total;
  }

  int get _moviesWatched => movies.where((m) => m.status == WatchedStatus.watched).length;

  @override
  Widget build(BuildContext context) {
    final episodes = _episodesWatched;

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: SwSpacing.sm),
        children: [
          _StatCard(
            icon: Icons.tv_outlined,
            title: 'Tempo vendo TV',
            child: _DurationValue(minutes: episodes * _avgEpisodeMinutes),
          ),
          _StatCard(
            icon: Icons.tv_outlined,
            title: 'Episódios assistidos',
            child: _BigNumber(value: episodes),
          ),
          _StatCard(
            icon: Icons.movie_creation_outlined,
            title: 'Tempo vendo filmes',
            child: _DurationValue(minutes: _moviesWatched * _avgMovieMinutes),
          ),
          _StatCard(
            icon: Icons.movie_creation_outlined,
            title: 'Filmes assistidos',
            child: _BigNumber(value: _moviesWatched),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: SwSurfaceColors.cardBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: SwNeutralColors.white, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: SwNeutralColors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: SwSurfaceColors.cardBorder),
          Expanded(child: Center(child: child)),
        ],
      ),
    );
  }
}

class _BigNumber extends StatelessWidget {
  const _BigNumber({required this.value});

  final int value;

  /// Formata com separador de milhar no padrão brasileiro (8.558).
  String get _formatted {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatted,
      style: const TextStyle(
        color: SwNeutralColors.white,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DurationValue extends StatelessWidget {
  const _DurationValue({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    const minutesPerDay = 24 * 60;
    const minutesPerMonth = 30 * minutesPerDay;

    final months = minutes ~/ minutesPerMonth;
    final days = (minutes % minutesPerMonth) ~/ minutesPerDay;
    final hours = (minutes % minutesPerDay) ~/ 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _DurationPart(value: months, label: 'MESES'),
        _DurationPart(value: days, label: 'DIAS'),
        _DurationPart(value: hours, label: 'HORAS'),
      ],
    );
  }
}

class _DurationPart extends StatelessWidget {
  const _DurationPart({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: SwNeutralColors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: SwNeutralColors.gray300,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Listas (colagem de pôsteres)
// ============================================================================

class _ListsCarousel extends StatefulWidget {
  const _ListsCarousel({required this.lists});

  final List<(String, List<WatchedItemModel>)> lists;

  @override
  State<_ListsCarousel> createState() => _ListsCarouselState();
}

class _ListsCarouselState extends State<_ListsCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.lists.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) {
              final (title, items) = widget.lists[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: SwSpacing.md),
                child: _ListCollage(title: title, items: items),
              );
            },
          ),
        ),
        const SizedBox(height: SwSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.lists.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page ? SwBrandColors.primary : SwNeutralColors.gray600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ListCollage extends StatelessWidget {
  const _ListCollage({required this.title, required this.items});

  final String title;
  final List<WatchedItemModel> items;

  @override
  Widget build(BuildContext context) {
    final posters = items.where((i) => i.fullPosterUrl.isNotEmpty).take(4).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (posters.isEmpty)
            const ColoredBox(color: SwSurfaceColors.card)
          else
            Row(
              children: [
                for (final p in posters)
                  Expanded(child: SwPosterImage(url: p.fullPosterUrl)),
              ],
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xB3000000)],
              ),
            ),
          ),
          Positioned(
            left: SwSpacing.sm,
            bottom: SwSpacing.sm,
            right: SwSpacing.sm,
            child: Text(
              '$title (${items.length})',
              style: const TextStyle(
                color: SwNeutralColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(blurRadius: 6, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Prateleiras de pôsteres
// ============================================================================

class _PosterShelf extends StatelessWidget {
  const _PosterShelf({required this.items, required this.emptyMessage});

  final List<WatchedItemModel> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: SwSpacing.md),
        child: Text(
          emptyMessage,
          style: const TextStyle(color: SwNeutralColors.gray600, fontSize: 14),
        ),
      );
    }

    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: SwSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 110,
            child: SwPosterTile(
              imageUrl: item.fullPosterUrl,
              semanticLabel: item.title,
              borderRadius: 6,
              onTap: () => openMediaDetail(context, item.toMedia()),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// Menu "•••" (Trakt, configurações, logout)
// ============================================================================

void _showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isTraktConfigured = EnvConfig.isTraktConfigured;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Trakt ─────────────────────────────────────────────
          ListTile(
            leading: Icon(
              isAuthenticated ? Icons.link : Icons.link_off,
              color: isAuthenticated ? SwBrandColors.primary : SwNeutralColors.gray500,
            ),
            title: const Text('Trakt.tv'),
            subtitle: Text(
              isAuthenticated
                  ? 'Conectado — histórico e watchlist sincronizados'
                  : 'Conecte para sincronizar histórico e watchlist',
              style: const TextStyle(color: SwNeutralColors.gray500),
            ),
            trailing: isAuthenticated
                ? null
                : TextButton(
                    onPressed: isTraktConfigured
                        ? () {
                            Navigator.pop(context);
                            ref.read(authControllerProvider.notifier).signInWithTrakt();
                          }
                        : null,
                    child: Text(isTraktConfigured ? 'CONECTAR' : 'INDISPONÍVEL'),
                  ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Aparência'),
            subtitle: const Text('Escuro', style: TextStyle(color: SwNeutralColors.gray500)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implementar seletor de tema
            },
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Região de Streaming'),
            subtitle: const Text('Brasil (BR)', style: TextStyle(color: SwNeutralColors.gray500)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implementar seletor de região
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Safe Watch',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.movie_filter_outlined,
                  size: 48,
                  color: SwBrandColors.primary,
                ),
                children: const [
                  Text(
                    'Registre tudo que você assiste.\n\n'
                    'Dados fornecidos por TMDB, Trakt.tv, TheTVDB e Watchmode.',
                  ),
                ],
              );
            },
          ),
          if (isAuthenticated) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: SwSupportColors.error),
              title: const Text('Sair', style: TextStyle(color: SwSupportColors.error)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ],
          const SizedBox(height: SwSpacing.sm),
        ],
      ),
    );
  }
}
