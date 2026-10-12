import 'package:dio/dio.dart';
import 'package:safe_watch/core/api/api_config.dart';
import 'package:safe_watch/core/api/api_interceptors.dart';

// ============================================================================
// Safe Watch — TMDB API Client
// ============================================================================
// Cliente Dio para The Movie Database (TMDB) API v3.
// Responsável por busca de catálogo, detalhes, temporadas e episódios.
//
// Autenticação: Bearer Token via header Authorization.
// Base URL: https://api.themoviedb.org/3
// Rate Limit: ~50 req/s (429 com Retry-After)
// Docs: https://developer.themoviedb.org/docs
// ============================================================================

/// Cliente para a TMDB API v3.
///
/// Fornece métodos para busca, detalhes de séries/filmes,
/// temporadas, episódios e providers de streaming.
///
/// Fluxo: SearchRepository → TmdbClient → TMDB API → JSON → Model
class TmdbClient {
  TmdbClient() : _dio = _createDio();

  final Dio _dio;

  /// Cria instância configurada do Dio para TMDB.
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.tmdbBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.tmdbApiKey}',
        },
      ),
    );

    dio.interceptors.addAll([
      RateLimitInterceptor(),
      LoggingInterceptor(),
    ]);

    return dio;
  }

  // ── Busca ────────────────────────────────────────────────────────────────

  /// Busca séries de TV por título.
  ///
  /// [query]: termo de busca.
  /// [page]: página de resultados (padrão: 1).
  /// [language]: idioma dos resultados (padrão: pt-BR).
  ///
  /// Retorna mapa JSON com `results`, `page`, `total_pages`, `total_results`.
  Future<Map<String, dynamic>> searchTv(
    String query, {
    int page = 1,
    String language = 'pt-BR',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search/tv',
      queryParameters: {
        'query': query,
        'page': page,
        'language': language,
        'include_adult': false,
      },
    );
    return response.data!;
  }

  /// Busca filmes por título.
  Future<Map<String, dynamic>> searchMovie(
    String query, {
    int page = 1,
    String language = 'pt-BR',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search/movie',
      queryParameters: {
        'query': query,
        'page': page,
        'language': language,
        'include_adult': false,
      },
    );
    return response.data!;
  }

  /// Busca multi (séries + filmes + pessoas).
  Future<Map<String, dynamic>> searchMulti(
    String query, {
    int page = 1,
    String language = 'pt-BR',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search/multi',
      queryParameters: {
        'query': query,
        'page': page,
        'language': language,
        'include_adult': false,
      },
    );
    return response.data!;
  }

  // ── Detalhes ─────────────────────────────────────────────────────────────

  /// Retorna detalhes completos de uma série de TV.
  ///
  /// [seriesId]: ID da série no TMDB.
  /// [appendToResponse]: dados adicionais (ex: 'external_ids,aggregate_credits,content_ratings').
  Future<Map<String, dynamic>> getTvDetails(
    int seriesId, {
    String? appendToResponse,
    String language = 'pt-BR',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/tv/$seriesId',
      queryParameters: {
        'language': language,
        if (appendToResponse != null) 'append_to_response': appendToResponse,
      },
    );
    return response.data!;
  }

  /// Retorna detalhes de um filme.
  Future<Map<String, dynamic>> getMovieDetails(
    int movieId, {
    String? appendToResponse,
    String language = 'pt-BR',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/movie/$movieId',
      queryParameters: {
        'language': language,
        if (appendToResponse != null) 'append_to_response': appendToResponse,
      },
    );
    return response.data!;
  }

  // ── Temporadas e Episódios ───────────────────────────────────────────────

  /// Retorna detalhes de uma temporada específica, incluindo lista de episódios.
  ///
  /// [seriesId]: ID da série no TMDB.
  /// [seasonNumber]: número da temporada.
  Future<Map<String, dynamic>> getSeasonDetails(
    int seriesId,
    int seasonNumber, {
    String language = 'pt-BR',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/tv/$seriesId/season/$seasonNumber',
      queryParameters: {
        'language': language,
      },
    );
    return response.data!;
  }

  /// Retorna detalhes de um episódio específico.
  Future<Map<String, dynamic>> getEpisodeDetails(
    int seriesId,
    int seasonNumber,
    int episodeNumber, {
    String language = 'pt-BR',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/tv/$seriesId/season/$seasonNumber/episode/$episodeNumber',
      queryParameters: {
        'language': language,
      },
    );
    return response.data!;
  }

  // ── Streaming Providers ──────────────────────────────────────────────────

  /// Retorna providers de streaming para uma série.
  ///
  /// Usa a integração nativa com JustWatch do TMDB.
  Future<Map<String, dynamic>> getTvWatchProviders(int seriesId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/tv/$seriesId/watch/providers',
    );
    return response.data!;
  }

  /// Retorna providers de streaming para um filme.
  Future<Map<String, dynamic>> getMovieWatchProviders(int movieId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/movie/$movieId/watch/providers',
    );
    return response.data!;
  }

  // ── Trending ─────────────────────────────────────────────────────────────

  /// Retorna séries em tendência.
  ///
  /// [timeWindow]: 'day' ou 'week'.
  Future<Map<String, dynamic>> getTrendingTv({
    String timeWindow = 'week',
    String language = 'pt-BR',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/trending/tv/$timeWindow',
      queryParameters: {'language': language},
    );
    return response.data!;
  }

  /// Retorna mídias em tendência de um tipo específico.
  ///
  /// [mediaType]: 'all', 'tv' ou 'movie'.
  /// [timeWindow]: 'day' ou 'week'.
  Future<Map<String, dynamic>> getTrending({
    String mediaType = 'all',
    String timeWindow = 'week',
    int page = 1,
    String language = 'pt-BR',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/trending/$mediaType/$timeWindow',
      queryParameters: {'language': language, 'page': page},
    );
    return response.data!;
  }

  // ── Listas (Em breve / Populares) ────────────────────────────────────────

  /// Retorna filmes que serão lançados em breve.
  Future<Map<String, dynamic>> getUpcomingMovies({
    int page = 1,
    String language = 'pt-BR',
    String region = 'BR',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/movie/upcoming',
      queryParameters: {'language': language, 'page': page, 'region': region},
    );
    return response.data!;
  }

  /// Retorna séries com episódios indo ao ar nos próximos 7 dias.
  Future<Map<String, dynamic>> getOnTheAirTv({
    int page = 1,
    String language = 'pt-BR',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/tv/on_the_air',
      queryParameters: {'language': language, 'page': page},
    );
    return response.data!;
  }

  /// Retorna mídias populares.
  ///
  /// [mediaType]: 'tv' ou 'movie'.
  Future<Map<String, dynamic>> getPopular({
    required String mediaType,
    int page = 1,
    String language = 'pt-BR',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/$mediaType/popular',
      queryParameters: {'language': language, 'page': page},
    );
    return response.data!;
  }
}
