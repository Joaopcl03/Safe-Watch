import 'package:safe_watch/core/config/env_config.dart';

// ============================================================================
// Safe Watch — API Configuration
// ============================================================================
// Constantes de URLs base e configuração de cada API.
// ============================================================================

/// Configuração centralizada de todas as APIs externas.
abstract final class ApiConfig {
  // ── TMDB ──────────────────────────────────────────────────────────────────

  /// URL base da TMDB API v3.
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';

  /// URL base para imagens do TMDB.
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';

  /// API key do TMDB (Bearer token).
  static String get tmdbApiKey => EnvConfig.tmdbApiKey;

  /// Constrói URL completa de poster.
  /// [path] é o posterPath retornado pela API (ex: "/abc123.jpg").
  /// [size] é a resolução desejada (w92, w154, w185, w342, w500, w780, original).
  static String tmdbImageUrl(String path, {String size = 'w500'}) {
    if (path.isEmpty) return '';
    return '$tmdbImageBaseUrl/$size$path';
  }

  /// Constrói URL de backdrop.
  static String tmdbBackdropUrl(String path, {String size = 'w780'}) {
    if (path.isEmpty) return '';
    return '$tmdbImageBaseUrl/$size$path';
  }

  /// Constrói URL de still (episódio).
  static String tmdbStillUrl(String path, {String size = 'w300'}) {
    if (path.isEmpty) return '';
    return '$tmdbImageBaseUrl/$size$path';
  }

  // ── Trakt.tv ─────────────────────────────────────────────────────────────

  /// URL base da Trakt.tv API.
  static const String traktBaseUrl = 'https://api.trakt.tv';

  /// Versão da API do Trakt (header obrigatório).
  static const String traktApiVersion = '2';

  /// Client ID do Trakt (header trakt-api-key).
  static String get traktClientId => EnvConfig.traktClientId;

  /// Client Secret do Trakt (OAuth token exchange).
  static String get traktClientSecret => EnvConfig.traktClientSecret;

  /// Redirect URI para OAuth do Trakt.
  static String get traktRedirectUri => EnvConfig.traktRedirectUri;

  /// URL de autorização OAuth do Trakt.
  static String get traktAuthUrl =>
      'https://trakt.tv/oauth/authorize?response_type=code'
      '&client_id=$traktClientId'
      '&redirect_uri=${Uri.encodeComponent(traktRedirectUri)}';

  // ── TheTVDB ──────────────────────────────────────────────────────────────

  /// URL base da TheTVDB API v4.
  static const String tvdbBaseUrl = 'https://api4.thetvdb.com/v4';

  /// API key do TheTVDB.
  static String get tvdbApiKey => EnvConfig.tvdbApiKey;

  // ── Watchmode ────────────────────────────────────────────────────────────

  /// URL base da Watchmode API.
  static const String watchmodeBaseUrl = 'https://api.watchmode.com/v1';

  /// API key do Watchmode.
  static String get watchmodeApiKey => EnvConfig.watchmodeApiKey;
}
