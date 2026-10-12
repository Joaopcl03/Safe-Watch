// ============================================================================
// Safe Watch — Environment Configuration
// ============================================================================
// Gerenciamento seguro de API keys via --dart-define.
//
// Para rodar o app com as keys:
//   flutter run \
//     --dart-define=TMDB_API_KEY=sua_key \
//     --dart-define=TRAKT_CLIENT_ID=sua_key \
//     --dart-define=TRAKT_CLIENT_SECRET=sua_key \
//     --dart-define=TVDB_API_KEY=sua_key \
//     --dart-define=WATCHMODE_API_KEY=sua_key
// ============================================================================

/// Configuração de ambiente do Safe Watch.
///
/// API keys são injetadas em tempo de compilação via `--dart-define`.
/// Nunca commite keys diretamente no código.
abstract final class EnvConfig {
  /// TMDB API Read Access Token (Bearer).
  /// Obter em: https://www.themoviedb.org/settings/api
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

  /// Trakt.tv Client ID (usada como trakt-api-key header).
  /// Criar app em: https://trakt.tv/oauth/applications/new
  static const String traktClientId = String.fromEnvironment('TRAKT_CLIENT_ID');

  /// Trakt.tv Client Secret (usada no OAuth token exchange).
  static const String traktClientSecret =
      String.fromEnvironment('TRAKT_CLIENT_SECRET');

  /// Trakt.tv OAuth Redirect URI.
  static const String traktRedirectUri =
      String.fromEnvironment('TRAKT_REDIRECT_URI', defaultValue: 'safewatch://auth/callback');

  /// TheTVDB API Key.
  /// Obter em: https://thetvdb.com/dashboard/account/apikeys
  static const String tvdbApiKey = String.fromEnvironment('TVDB_API_KEY');

  /// TheTVDB Subscriber PIN (opcional, para planos pagos).
  static const String tvdbPin = String.fromEnvironment('TVDB_PIN');

  /// Watchmode API Key.
  /// Obter em: https://api.watchmode.com/
  static const String watchmodeApiKey =
      String.fromEnvironment('WATCHMODE_API_KEY');

  /// Verifica se todas as keys obrigatórias estão configuradas.
  static bool get isConfigured =>
      tmdbApiKey.isNotEmpty && traktClientId.isNotEmpty;

  /// Verifica se TMDB está configurado.
  static bool get isTmdbConfigured => tmdbApiKey.isNotEmpty;

  /// Verifica se Trakt está configurado.
  static bool get isTraktConfigured =>
      traktClientId.isNotEmpty && traktClientSecret.isNotEmpty;

  /// Verifica se TheTVDB está configurado.
  static bool get isTvdbConfigured => tvdbApiKey.isNotEmpty;

  /// Verifica se Watchmode está configurado.
  static bool get isWatchmodeConfigured => watchmodeApiKey.isNotEmpty;
}
