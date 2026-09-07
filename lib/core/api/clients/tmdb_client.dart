import 'package:dio/dio.dart';
import 'package:safe_watch/core/api/api_config.dart';
import 'package:safe_watch/core/api/api_interceptors.dart';
import 'package:safe_watch/core/config/env_config.dart';

// ============================================================================
// Safe Watch — TMDB Client
// ============================================================================
// Cliente Dio para The Movie Database (TMDB) API v3.
// Documentação: https://developer.themoviedb.org/docs
//
// Responsabilidades:
//   - Busca de séries e filmes
//   - Detalhes de série com temporadas
//   - Detalhes de episódios
//   - Providers de streaming por região
//   - Cross-reference de IDs externos (imdb, tvdb, trakt)
// ============================================================================

/// Cliente HTTP para a API TMDB v3.
///
/// Singleton — use [TmdbClient.instance] para acesso.
/// Configura automaticamente o Bearer token e os interceptors.
class TmdbClient {
  TmdbClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.tmdbBaseUrl,
        connectTimeout:
            const Duration(seconds: ApiConfig.connectionTimeoutSeconds),
        receiveTimeout:
            const Duration(seconds: ApiConfig.receiveTimeoutSeconds),
        headers: {
          // TMDB usa Bearer token no header Authorization.
          'Authorization': 'Bearer ${EnvConfig.tmdbApiKey}',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      RateLimitInterceptor(),
      const LoggingInterceptor(),
      CacheInterceptor(maxAge: const Duration(minutes: 30)),
    ]);
  }

  static final TmdbClient instance = TmdbClient._();

  late final Dio _dio;

  // --------------------------------------------------------------------------
  // Busca
  // --------------------------------------------------------------------------

  /// Busca séries de TV pelo título.
  ///
  /// Endpoint: GET /search/tv
  /// Retorna lista de resultados da busca com paginação.
  Future<Map<String, dynamic>> searchTv(
    String query, {
    int page = 1,
    String language = ApiConfig.tmdbDefaultLanguage,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search/tv',
      queryParameters: {
        'query': query,
        'page': page,
        'language': language,
      },
    );
    return response.data!;
  }

  /// Busca filmes pelo título.
  ///
  /// Endpoint: GET /search/movie
  Future<Map<String, dynamic>> searchMovie(
    String query, {
    int page = 1,
    String language = ApiConfig.tmdbDefaultLanguage,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search/movie',
      queryParameters: {
        'query': query,
        'page': page,
        'language': language,
      },
    );
    return response.data!;
  }

  /// Busca séries e filmes simultaneamente (multi-search).
  ///
  /// Endpoint: GET /search/multi
  /// Retorna mix de filmes, séries e pessoas.
  Future<Map<String, dynamic>> searchMulti(
    String query, {
    int page = 1,
    String language = ApiConfig.tmdbDefaultLanguage,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search/multi',
      queryParameters: {
        'query': query,
        'page': page,
        'language': language,
      },
    );
    return response.data!;
  }

  // --------------------------------------------------------------------------
  // Detalhes de Série
  // --------------------------------------------------------------------------

  /// Retorna detalhes completos de uma série de TV.
  ///
  /// Endpoint: GET /tv/{series_id}
  /// [appendToResponse] permite incluir dados extras em uma única chamada.
  /// Exemplo: `appendToResponse: 'external_ids,credits,videos'`
  Future<Map<String, dynamic>> getTvDetails(
    int seriesId, {
    String language = ApiConfig.tmdbDefaultLanguage,
    String appendToResponse = 'external_ids',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/tv/$seriesId',
      queryParameters: {
        'language': language,
        'append_to_response': appendToResponse,
      },
    );
    return response.data!;
  }

  /// Retorna detalhes de uma temporada específica com todos os episódios.
  ///
  /// Endpoint: GET /tv/{series_id}/season/{season_number}
  Future<Map<String, dynamic>> getSeasonDetails(
    int seriesId,
    int seasonNumber, {
    String language = ApiConfig.tmdbDefaultLanguage,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/tv/$seriesId/season/$seasonNumber',
      queryParameters: {'language': language},
    );
    return response.data!;
  }

  /// Retorna detalhes de um episódio específico.
  ///
  /// Endpoint: GET /tv/{series_id}/season/{season_number}/episode/{episode_number}
  Future<Map<String, dynamic>> getEpisodeDetails(
    int seriesId,
    int seasonNumber,
    int episodeNumber, {
    String language = ApiConfig.tmdbDefaultLanguage,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/tv/$seriesId/season/$seasonNumber/episode/$episodeNumber',
      queryParameters: {'language': language},
    );
    return response.data!;
  }

  // --------------------------------------------------------------------------
  // Detalhes de Filme
  // --------------------------------------------------------------------------

  /// Retorna detalhes completos de um filme.
  ///
  /// Endpoint: GET /movie/{movie_id}
  Future<Map<String, dynamic>> getMovieDetails(
    int movieId, {
    String language = ApiConfig.tmdbDefaultLanguage,
    String appendToResponse = 'external_ids',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/movie/$movieId',
      queryParameters: {
        'language': language,
        'append_to_response': appendToResponse,
      },
    );
    return response.data!;
  }

  // --------------------------------------------------------------------------
  // IDs Externos
  // --------------------------------------------------------------------------

  /// Retorna os IDs externos de uma série (imdb, tvdb, trakt, etc.).
  ///
  /// Endpoint: GET /tv/{series_id}/external_ids
  Future<Map<String, dynamic>> getTvExternalIds(int seriesId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/tv/$seriesId/external_ids',
    );
    return response.data!;
  }

  /// Retorna os IDs externos de um filme.
  ///
  /// Endpoint: GET /movie/{movie_id}/external_ids
  Future<Map<String, dynamic>> getMovieExternalIds(int movieId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/movie/$movieId/external_ids',
    );
    return response.data!;
  }

  // --------------------------------------------------------------------------
  // Streaming / Watch Providers
  // --------------------------------------------------------------------------

  /// Retorna os providers de streaming disponíveis para uma série por região.
  ///
  /// Endpoint: GET /tv/{series_id}/watch/providers
  /// Retorna dados do JustWatch por país.
  Future<Map<String, dynamic>> getTvWatchProviders(
    int seriesId, {
    String region = ApiConfig.tmdbDefaultRegion,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/tv/$seriesId/watch/providers',
      options: Options(extra: {'useCache': true}),
    );
    // Filtra pelo país/região desejada.
    final results =
        (response.data!['results'] as Map<String, dynamic>?) ?? {};
    return results[region] as Map<String, dynamic>? ?? {};
  }

  /// Retorna os providers de streaming disponíveis para um filme por região.
  ///
  /// Endpoint: GET /movie/{movie_id}/watch/providers
  Future<Map<String, dynamic>> getMovieWatchProviders(
    int movieId, {
    String region = ApiConfig.tmdbDefaultRegion,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/movie/$movieId/watch/providers',
      options: Options(extra: {'useCache': true}),
    );
    final results =
        (response.data!['results'] as Map<String, dynamic>?) ?? {};
    return results[region] as Map<String, dynamic>? ?? {};
  }

  // --------------------------------------------------------------------------
  // Helpers de URL de Imagem
  // --------------------------------------------------------------------------

  /// Gera a URL completa de um poster a partir do caminho parcial.
  ///
  /// [size] pode ser: w185, w342, w500, w780, original.
  static String posterUrl(
    String? path, {
    String size = ApiConfig.tmdbPosterW500,
  }) {
    if (path == null || path.isEmpty) return '';
    return '${ApiConfig.tmdbImageBaseUrl}/$size$path';
  }

  /// Gera a URL completa de um backdrop (imagem de fundo).
  static String backdropUrl(
    String? path, {
    String size = ApiConfig.tmdbBackdropW1280,
  }) {
    if (path == null || path.isEmpty) return '';
    return '${ApiConfig.tmdbImageBaseUrl}/$size$path';
  }

  /// Gera a URL completa de um still (frame de episódio).
  static String stillUrl(
    String? path, {
    String size = ApiConfig.tmdbStillW300,
  }) {
    if (path == null || path.isEmpty) return '';
    return '${ApiConfig.tmdbImageBaseUrl}/$size$path';
  }
}
