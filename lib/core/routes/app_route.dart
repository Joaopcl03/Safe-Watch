import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_watch/features/auth/templates/login_template.dart';
import 'package:safe_watch/features/search/templates/search_template.dart';
import 'package:safe_watch/features/watched_list/templates/watched_list_template.dart';

// ============================================================================
// Safe Watch — Rotas do Aplicativo (go_router)
// ============================================================================
// Configuração centralizada de todas as rotas nomeadas.
// Fluxo de navegação:
//   /login         → Tela de autenticação
//   /search        → Busca de séries/filmes
//   /watched-list  → Lista de assistidos / quero assistir
// ============================================================================

/// Nomes de rotas centralizados para evitar strings mágicas.
abstract final class SwRoutes {
  static const String login = '/login';
  static const String search = '/search';
  static const String watchedList = '/watched-list';
}

/// Configuração do [GoRouter] do aplicativo.
///
/// Rota inicial é [SwRoutes.search] (busca).
/// O redirect pode ser usado para redirecionar usuários
/// não autenticados para o login.
final GoRouter appRouter = GoRouter(
  initialLocation: SwRoutes.search,
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    // ── Login ──────────────────────────────────────────────────────────
    GoRoute(
      path: SwRoutes.login,
      name: 'login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginTemplate();
      },
    ),

    // ── Search ─────────────────────────────────────────────────────────
    GoRoute(
      path: SwRoutes.search,
      name: 'search',
      builder: (BuildContext context, GoRouterState state) {
        return const SearchTemplate();
      },
    ),

    // ── Watched List ───────────────────────────────────────────────────
    GoRoute(
      path: SwRoutes.watchedList,
      name: 'watched-list',
      builder: (BuildContext context, GoRouterState state) {
        return const WatchedListTemplate();
      },
    ),
  ],

  // Redirect global de autenticação (placeholder).
  // TODO: Implementar verificação de autenticação via AuthController.
  // redirect: (BuildContext context, GoRouterState state) {
  //   final isLoggedIn = /* verificar auth state */;
  //   final isLoggingIn = state.matchedLocation == SwRoutes.login;
  //   if (!isLoggedIn && !isLoggingIn) return SwRoutes.login;
  //   if (isLoggedIn && isLoggingIn) return SwRoutes.search;
  //   return null;
  // },
);
