// ============================================================================
// Safe Watch — API Configuration
// ============================================================================
// Constantes centralizadas de URLs base e configurações das 4 APIs.
// As keys em si ficam em EnvConfig (injetadas via --dart-define).
// ============================================================================

/// Constantes de configuração das 4 APIs integradas ao Safe Watch.
///
/// Centraliza URLs base, versões e parâmetros estáticos de cada API.
/// As chaves de API são gerenciadas por [EnvConfig].
abstract final class ApiConfig {
  // --------------------------------------------------------------------------
  // TMDB — The Movie Database
  // Documentação: https://developer.themoviedb.org/docs
  // --------------------------------------------------------------------------

  /// URL base para todos os endpoints da API TMDB v3.
  static const tmdbBaseUrl = 'https://api.themoviedb.org/3';

  /// URL base para imagens do TMDB.
  /// Uso: '$tmdbImageBaseUrl/w500/caminho_do_poster.jpg'
  static const tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';

  /// Tamanhos de imagem disponíveis no TMDB.
  static const tmdbPosterW185 = 'w185';
  static const tmdbPosterW342 = 'w342';
  static const tmdbPosterW500 = 'w500';
  static const tmdbPosterW780 = 'w780';
  static const tmdbPosterOriginal = 'original';
  static const tmdbBackdropW300 = 'w300';
  static const tmdbBackdropW780 = 'w780';
  static const tmdbBackdropW1280 = 'w1280';
  static const tmdbStillW92 = 'w92';
  static const tmdbStillW185 = 'w185';
  static const tmdbStillW300 = 'w300';

  /// Linguagem padrão para os resultados do TMDB.
  static const tmdbDefaultLanguage = 'pt-BR';

  /// Região padrão para resultados de streaming.
  static const tmdbDefaultRegion = 'BR';

  // --------------------------------------------------------------------------
  // Trakt.tv
  // Documentação: https://trakt.docs.apiary.io/
  // --------------------------------------------------------------------------

  /// URL base para todos os endpoints da API Trakt.tv.
  static const traktBaseUrl = 'https://api.trakt.tv';

  /// Versão da API Trakt (enviada no header `trakt-api-version`).
  static const traktApiVersion = '2';

  /// URL de autorização OAuth 2.0 do Trakt.
  static const traktAuthUrl = 'https://trakt.tv/oauth/authorize';

  /// URL para troca de código por token OAuth.
  static const traktTokenUrl = 'https://api.trakt.tv/oauth/token';

  /// URL para revogar token OAuth.
  static const traktRevokeUrl = 'https://api.trakt.tv/oauth/revoke';

  // --------------------------------------------------------------------------
  // TheTVDB v4
  // Documentação: https://thetvdb.github.io/v4-api/
  // --------------------------------------------------------------------------

  /// URL base para todos os endpoints da API TheTVDB v4.
  static const tvdbBaseUrl = 'https://api4.thetvdb.com/v4';

  /// Endpoint de login para obter JWT do TheTVDB.
  static const tvdbLoginEndpoint = '/login';

  /// Validade do JWT do TheTVDB em dias (30 dias conforme documentação).
  static const tvdbTokenValidityDays = 30;

  // --------------------------------------------------------------------------
  // Watchmode
  // Documentação: https://api.watchmode.com/docs/
  // --------------------------------------------------------------------------

  /// URL base para todos os endpoints da API Watchmode.
  static const watchmodeBaseUrl = 'https://api.watchmode.com/v1';

  // --------------------------------------------------------------------------
  // Timeouts e configurações HTTP compartilhadas
  // --------------------------------------------------------------------------

  /// Timeout de conexão em segundos.
  static const connectionTimeoutSeconds = 10;

  /// Timeout de leitura/resposta em segundos.
  static const receiveTimeoutSeconds = 15;

  /// Máximo de tentativas de retry em caso de rate limit (429).
  static const maxRetryAttempts = 3;

  /// Delay base entre retries em milissegundos (cresce exponencialmente).
  static const retryBaseDelayMs = 1000;
}
