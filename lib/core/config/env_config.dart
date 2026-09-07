// ============================================================================
// Safe Watch — Environment Configuration
// ============================================================================
// Gerenciamento seguro de API keys via --dart-define.
//
// Como usar durante o desenvolvimento:
//   flutter run \
//     --dart-define=TMDB_API_KEY=seu_key \
//     --dart-define=TRAKT_CLIENT_ID=seu_id \
//     --dart-define=TRAKT_CLIENT_SECRET=seu_secret \
//     --dart-define=TVDB_API_KEY=seu_key \
//     --dart-define=WATCHMODE_API_KEY=seu_key
//
// Em produção, configure as variáveis no CI/CD ou via launch.json no VS Code:
// {
//   "configurations": [{
//     "name": "SafeWatch Dev",
//     "request": "launch",
//     "type": "dart",
//     "args": ["--dart-define=TMDB_API_KEY=xxx"]
//   }]
// }
// ============================================================================

/// Configuração de variáveis de ambiente para API keys.
///
/// Todas as keys são injetadas via `--dart-define` no build,
/// nunca hardcoded no código-fonte ou commitadas no repositório.
abstract final class EnvConfig {
  // --------------------------------------------------------------------------
  // TMDB — The Movie Database
  // Obtenha em: https://www.themoviedb.org/settings/api (gratuito)
  // --------------------------------------------------------------------------

  /// API Key do TMDB (read access token).
  static const tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

  // --------------------------------------------------------------------------
  // Trakt.tv
  // Crie um app em: https://trakt.tv/oauth/applications/new (gratuito)
  // --------------------------------------------------------------------------

  /// Client ID do app Trakt.tv.
  static const traktClientId = String.fromEnvironment('TRAKT_CLIENT_ID');

  /// Client Secret do app Trakt.tv.
  static const traktClientSecret =
      String.fromEnvironment('TRAKT_CLIENT_SECRET');

  /// URI de redirecionamento OAuth registrado no app Trakt.tv.
  /// Deve ser registrado exatamente como configurado no painel do Trakt.
  static const traktRedirectUri =
      String.fromEnvironment('TRAKT_REDIRECT_URI', defaultValue: 'safewatch://trakt/callback');

  // --------------------------------------------------------------------------
  // TheTVDB v4
  // Crie uma key em: https://thetvdb.com/dashboard/account/apikeys
  // Plano gratuito: 200 req/mês
  // --------------------------------------------------------------------------

  /// API Key do TheTVDB v4.
  static const tvdbApiKey = String.fromEnvironment('TVDB_API_KEY');

  // --------------------------------------------------------------------------
  // Watchmode
  // Registre-se em: https://api.watchmode.com/ (plano gratuito: 1000 req/mês)
  // --------------------------------------------------------------------------

  /// API Key do Watchmode.
  static const watchmodeApiKey = String.fromEnvironment('WATCHMODE_API_KEY');

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  /// Verifica se as keys essenciais (TMDB e Trakt) estão configuradas.
  ///
  /// Útil para exibir avisos durante o desenvolvimento quando as keys
  /// não foram fornecidas via --dart-define.
  static bool get hasRequiredKeys =>
      tmdbApiKey.isNotEmpty && traktClientId.isNotEmpty;

  /// Verifica se a integração com TheTVDB está configurada.
  static bool get hasTvdbKey => tvdbApiKey.isNotEmpty;

  /// Verifica se a integração com Watchmode está configurada.
  static bool get hasWatchmodeKey => watchmodeApiKey.isNotEmpty;
}
