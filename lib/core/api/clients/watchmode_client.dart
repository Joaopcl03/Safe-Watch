import 'package:dio/dio.dart';
import 'package:safe_watch/core/api/api_config.dart';
import 'package:safe_watch/core/api/api_interceptors.dart';

// ============================================================================
// Safe Watch — Watchmode API Client
// ============================================================================
// Cliente Dio para Watchmode API.
// Responsável por consultar disponibilidade em streaming por país.
//
// Autenticação: API Key via header X-API-Key.
// Base URL: https://api.watchmode.com/v1
// Rate Limit: Free 1000/mês, ~2-5 req/s
// Docs: https://api.watchmode.com/docs/
// ============================================================================

/// Cliente para a Watchmode API.
///
/// Consulta em quais serviços de streaming um título está disponível,
/// com deep links para cada plataforma.
///
/// Fluxo: SearchRepository → WatchmodeClient → Watchmode API → JSON
class WatchmodeClient {
  WatchmodeClient() : _dio = _createDio();

  final Dio _dio;

  /// Cria instância configurada do Dio para Watchmode.
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.watchmodeBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'X-API-Key': ApiConfig.watchmodeApiKey,
        },
      ),
    );

    dio.interceptors.addAll([
      RateLimitInterceptor(),
      LoggingInterceptor(),
    ]);

    return dio;
  }

  // ── Busca por ID externo ─────────────────────────────────────────────────

  /// Busca o ID Watchmode de um título usando o TMDB ID.
  ///
  /// [tmdbId]: ID do título no TMDB.
  /// [type]: 'tmdb_tv_id' para séries, 'tmdb_movie_id' para filmes.
  ///
  /// Retorna mapa com `title_results` contendo o Watchmode ID.
  Future<Map<String, dynamic>> searchByTmdbId(
    int tmdbId, {
    String type = 'tmdb_tv_id',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search/',
      queryParameters: {
        'apiKey': ApiConfig.watchmodeApiKey,
        'search_field': type,
        'search_value': tmdbId,
      },
    );
    return response.data!;
  }

  // ── Fontes de Streaming ──────────────────────────────────────────────────

  /// Retorna os serviços de streaming onde o título está disponível.
  ///
  /// [titleId]: ID do título no Watchmode.
  /// [regions]: códigos de país (ex: 'BR', 'US').
  ///
  /// Cada fonte inclui: nome, tipo (sub/free/rent/buy), URLs (web/iOS/Android),
  /// formato (HD/4K) e preço.
  Future<List<dynamic>> getSourcesForTitle(
    int titleId, {
    String regions = 'BR',
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/title/$titleId/sources/',
      queryParameters: {
        'apiKey': ApiConfig.watchmodeApiKey,
        'regions': regions,
      },
    );
    return response.data!;
  }

  /// Retorna detalhes do título com fontes de streaming anexadas.
  ///
  /// [titleId]: ID do título no Watchmode.
  /// Combina detalhes + sources em uma única requisição.
  Future<Map<String, dynamic>> getTitleDetailsWithSources(int titleId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/title/$titleId/details/',
      queryParameters: {
        'apiKey': ApiConfig.watchmodeApiKey,
        'append_to_response': 'sources',
      },
    );
    return response.data!;
  }

  // ── Providers ────────────────────────────────────────────────────────────

  /// Retorna a lista de todos os provedores de streaming disponíveis.
  ///
  /// [regions]: filtrar por país (ex: 'BR').
  Future<List<dynamic>> getProviders({String regions = 'BR'}) async {
    final response = await _dio.get<List<dynamic>>(
      '/sources/',
      queryParameters: {
        'apiKey': ApiConfig.watchmodeApiKey,
        'regions': regions,
      },
    );
    return response.data!;
  }
}
