
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_watch/features/auth/templates/login_template.dart';
import 'package:safe_watch/features/profile/templates/profile_template.dart';
import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/search/templates/media_detail_template.dart';
import 'package:safe_watch/features/search/templates/search_template.dart';
import 'package:safe_watch/features/watched_list/templates/watched_list_template.dart';
import 'package:safe_watch/shared/widgets/sw_bottom_nav_shell.dart';

// ============================================================================
// Safe Watch — Rotas do Aplicativo (go_router)
// ============================================================================
// Configuração centralizada de rotas com:
//   - StatefulShellRoute para Bottom Navigation (Séries, Filmes, Explorar, Perfil)
//   - Rota de detalhe que navega por cima do shell (esconde o bottom nav)
//   - Rota de login separada (fora do shell)
// ============================================================================

/// Nomes de rotas centralizados para evitar strings mágicas.
abstract final class SwRoutes {
  static const String login = '/login';
  static const String series = '/series';
  static const String movies = '/movies';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String mediaDetail = '/media-detail';

  /// Alias mantido por compatibilidade: a antiga "Minha Lista" agora é Séries.
  static const String watchedList = series;
}

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Configuração do [GoRouter] do aplicativo.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: SwRoutes.series,
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    // ── Login (fora do shell) ───────────────────────────────────────
    GoRoute(
      path: SwRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginTemplate(),
    ),

    // ── Detalhes (por cima do shell) ────────────────────────────────
    GoRoute(
      path: SwRoutes.mediaDetail,
      name: 'media-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final media = state.extra as MediaModel;
        return MediaDetailTemplate(media: media);
      },
    ),

    // ── Shell com Bottom Navigation ─────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return SwBottomNavShell(navigationShell: navigationShell);
      },
      branches: [
        // ── Branch 0: Séries (tela inicial) ───────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: SwRoutes.series,
              name: 'series',
              builder: (context, state) =>
                  const WatchedListTemplate(mediaType: MediaType.tv),
            ),
          ],
        ),

        // ── Branch 1: Filmes ──────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: SwRoutes.movies,
              name: 'movies',
              builder: (context, state) =>
                  const WatchedListTemplate(mediaType: MediaType.movie),
            ),
          ],
        ),

        // ── Branch 2: Explorar (busca + feed) ─────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: SwRoutes.search,
              name: 'search',
              builder: (context, state) => const SearchTemplate(),
              routes: [
                // Mantido por compatibilidade com links antigos.
                GoRoute(
                  path: 'detail',
                  name: 'search-detail',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final media = state.extra as MediaModel;
                    return MediaDetailTemplate(media: media);
                  },
                ),
              ],
            ),
          ],
        ),

        // ── Branch 3: Perfil ──────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: SwRoutes.profile,
              name: 'profile',
              builder: (context, state) => const ProfileTemplate(),
            ),
          ],
        ),
      ],
    ),
  ],
);
