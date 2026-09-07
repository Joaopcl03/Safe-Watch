import 'package:dio/dio.dart';
import 'package:safe_watch/core/api/api_config.dart';
import 'package:safe_watch/core/api/api_interceptors.dart';
import 'package:safe_watch/core/config/env_config.dart';

// ============================================================================
// Safe Watch — Watchmode Client
// ============================================================================
// Cliente Dio para Watchmode API v1.
// Documentação: https://api.watchmode.com/docs/
//
// Responsabilidades:
//   - Localizar títulos por ID TMDB
//   - Retornar fontes de streaming disponíveis por região
//   - Listar providers disponíveis
//
// Plano gratuito: 1000 req/mês — use cache agressivo.
// ============================================================================

/// Cliente HTTP para a API Watchmode v1.
///
/// Singleton — use [WatchmodeClient.instance].
/// Usa cache de 24h por padrão para economizar cota do plano gratuito.
class WatchmodeClient {
  WatchmodeClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.watchmodeBaseUrl,
        connectTimeout:
            const Duration(seconds: ApiConfig.connectionTimeoutSeconds),
        receiveTimeout:
            const Duration(seconds: ApiConfig.receiveTimeoutSeconds),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _WatchmodeApiKeyInterceptor(),
      RateLimitInterceptor(),
      const LoggingInterceptor(),
      // Cache mais longo (24h) para economizar cota do plano gratuito.
      CacheInterceptor(maxAge: const Duration(hours: 24)),
    ]);
  }

  static final WatchmodeClient instance = WatchmodeClient._();

  late final Dio _dio;

  // --------------------------------------------------------------------------
  // Busca de Títulos
  // --------------------------------------------------------------------------

  /// Busca um título no Watchmode pelo ID do TMDB.
  ///
  /// Endpoint: GET /search/
  /// Retorna o Watchmode ID que pode ser usado para buscar as fontes.
  ///
  /// [tmdbId] é o ID do TMDB.
  /// [titleType] pode ser: 'movie' ou 'tv_movie', 'tv_series', 'tv_miniseries',
  ///             'tv_special', 'tv_short', 'short_film', 'documentary'
  Future<Map<String, dynamic>> searchByTmdbId({
    required int tmdbId,
    required String titleType,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search/',
      queryParameters: {
        'search_field': 'tmdb_id',
        'search_value': tmdbId.toString(),
        'types': titleType,
      },
    );
    return response.data!;
  }

  /// Busca um título por texto.
  ///
  /// Endpoint: GET /search/
  Future<Map<String, dynamic>> searchByText(
    String query, {
    String? titleType,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search/',
      queryParameters: {
        'search_field': 'name',
        'search_value': query,
        if (titleType != null) 'types': titleType,
      },
    );
    return response.data!;
  }

  // --------------------------------------------------------------------------
  // Fontes de Streaming
  // --------------------------------------------------------------------------

  /// Retorna as fontes de streaming disponíveis para um título.
  ///
  /// Endpoint: GET /title/{id}/sources/
  /// [watchmodeId] é obtido via [searchByTmdbId].
  /// [regions] filtra por país (ex: 'BR', 'US'). Padrão: todos os países.
  Future<List<dynamic>> getSourcesForTitle(
    int watchmodeId, {
    List<String>? regions,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/title/$watchmodeId/sources/',
      queryParameters: {
        if (regions != null && regions.isNotEmpty)
          'regions': regions.join(','),
      },
    );
    return response.data!;
  }

  /// Busca as fontes de streaming a partir de um TMDB ID diretamente.
  ///
  /// Combina [searchByTmdbId] + [getSourcesForTitle] em uma única chamada
  /// conveniente. Retorna lista vazia se o título não for encontrado.
  ///
  /// [mediaType] deve ser 'movie' ou 'tv_series'.
  Future<List<dynamic>> getSourcesByTmdbId({
    required int tmdbId,
    required String mediaType,
    List<String>? regions,
  }) async {
    try {
      final searchResult = await searchByTmdbId(
        tmdbId: tmdbId,
        titleType: mediaType == 'tv' ? 'tv_series' : 'movie',
      );

      final titleResults =
          searchResult['title_results'] as List<dynamic>? ?? [];
      if (titleResults.isEmpty) return [];

      final watchmodeId = titleResults.first['id'] as int?;
      if (watchmodeId == null) return [];

      return getSourcesForTitle(watchmodeId, regions: regions);
    } on DioException {
      // Retorna lista vazia em caso de erro (Watchmode é fallback).
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // Providers
  // --------------------------------------------------------------------------

  /// Lista todos os providers disponíveis no Watchmode.
  ///
  /// Endpoint: GET /sources/
  /// Retorna nome, logo, tipo e países disponíveis.
  Future<List<dynamic>> getProviders({String? region}) async {
    final response = await _dio.get<List<dynamic>>(
      '/sources/',
      queryParameters: {
        if (region != null) 'regions': region,
      },
      options: Options(extra: {'useCache': true}),
    );
    return response.data!;
  }

  // --------------------------------------------------------------------------
  // Detalhes de Título
  // --------------------------------------------------------------------------

  /// Retorna os detalhes completos de um título no Watchmode.
  ///
  /// Endpoint: GET /title/{id}/details/
  Future<Map<String, dynamic>> getTitleDetails(
    int watchmodeId, {
    bool appendToResponse = true,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/title/$watchmodeId/details/',
      queryParameters: {
        if (appendToResponse) 'append_to_response': 'sources',
      },
    );
    return response.data!;
  }
}

// ----------------------------------------------------------------------------
// API Key Interceptor
// ----------------------------------------------------------------------------

/// Interceptor que injeta a API key do Watchmode em todas as requisições.
///
/// A Watchmode aceita a key via query parameter ou header X-API-Key.
/// Usamos query parameter pois é o método mais comum para esta API.
class _WatchmodeApiKeyInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.queryParameters['apiKey'] = EnvConfig.watchmodeApiKey;
    handler.next(options);
  }
}
