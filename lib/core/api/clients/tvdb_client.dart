import 'package:dio/dio.dart';
import 'package:safe_watch/core/api/api_config.dart';
import 'package:safe_watch/core/api/api_interceptors.dart';
import 'package:safe_watch/core/config/env_config.dart';

// ============================================================================
// Safe Watch — TheTVDB API v4 Client
// ============================================================================
// Cliente Dio para TheTVDB API v4.
// Responsável por metadados detalhados de séries, season orders alternativas.
//
// Autenticação: JWT Bearer Token (login → token válido por 30 dias).
// Base URL: https://api4.thetvdb.com/v4
// Rate Limit: ~5-100 req/min (depende do plano)
// Docs: https://thetvdb.github.io/v4-api/
// ============================================================================

/// Cliente para TheTVDB API v4.
///
/// Usado como fonte secundária de metadados, especialmente para
/// ordens alternativas de temporadas (DVD, Absolute) e anime.
///
/// Fluxo: Repository → TvdbClient → TheTVDB API → JSON
class TvdbClient {
  TvdbClient() : _dio = _createDio();

  final Dio _dio;

  /// JWT token obtido via /login.
  String? _token;

  /// Data de expiração do token (30 dias após login).
  DateTime? _tokenExpiry;

  /// Cria instância configurada do Dio para TheTVDB.
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.tvdbBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Accept-Language': 'por',
        },
      ),
    );

    dio.interceptors.addAll([
      RateLimitInterceptor(),
      LoggingInterceptor(),
    ]);

    return dio;
  }

  // ── Autenticação ─────────────────────────────────────────────────────────

  /// Realiza login e obtém JWT token.
  ///
  /// O token é válido por 30 dias.
  /// Chamado automaticamente quando necessário.
  Future<void> _ensureAuthenticated() async {
    if (_token != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return; // Token ainda válido.
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/login',
      data: {
        'apikey': ApiConfig.tvdbApiKey,
        if (EnvConfig.tvdbPin.isNotEmpty) 'pin': EnvConfig.tvdbPin,
      },
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    _token = data['token'] as String;
    _tokenExpiry = DateTime.now().add(const Duration(days: 28)); // Margem de segurança.

    // Atualiza header de autorização.
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  // ── Search ──────────────────────────────────────────────────────────────

  /// Busca séries por nome.
  Future<Map<String, dynamic>> searchSeries(String query) async {
    await _ensureAuthenticated();
    final response = await _dio.get<Map<String, dynamic>>(
      '/search',
      queryParameters: {
        'query': query,
        'type': 'series',
      },
    );
    return response.data!;
  }

  /// Busca por ID externo (IMDB, TMDB, etc.).
  Future<Map<String, dynamic>> searchByRemoteId(String remoteId) async {
    await _ensureAuthenticated();
    final response = await _dio.get<Map<String, dynamic>>(
      '/search/remoteid/$remoteId',
    );
    return response.data!;
  }

  // ── Detalhes ─────────────────────────────────────────────────────────────

  /// Retorna detalhes estendidos de uma série, incluindo temporadas e artworks.
  Future<Map<String, dynamic>> getSeriesExtended(int seriesId) async {
    await _ensureAuthenticated();
    final response = await _dio.get<Map<String, dynamic>>(
      '/series/$seriesId/extended',
    );
    return response.data!;
  }

  // ── Episódios por Season Type ────────────────────────────────────────────

  /// Retorna episódios de uma série por tipo de ordem de temporada.
  ///
  /// [seriesId]: ID da série no TheTVDB.
  /// [seasonType]: 'default' (Aired), 'official', 'dvd', 'absolute', 'alternate', 'regional'.
  /// [page]: página de resultados (padrão: 0).
  /// [season]: filtrar por temporada específica.
  Future<Map<String, dynamic>> getEpisodesBySeason(
    int seriesId, {
    String seasonType = 'default',
    int page = 0,
    int? season,
  }) async {
    await _ensureAuthenticated();
    final response = await _dio.get<Map<String, dynamic>>(
      '/series/$seriesId/episodes/$seasonType',
      queryParameters: {
        'page': page,
        if (season != null) 'season': season,
      },
    );
    return response.data!;
  }

  // ── Season & Episode Details ─────────────────────────────────────────────

  /// Retorna detalhes estendidos de uma temporada.
  Future<Map<String, dynamic>> getSeasonExtended(int seasonId) async {
    await _ensureAuthenticated();
    final response = await _dio.get<Map<String, dynamic>>(
      '/seasons/$seasonId/extended',
    );
    return response.data!;
  }

  /// Retorna detalhes estendidos de um episódio.
  Future<Map<String, dynamic>> getEpisodeExtended(int episodeId) async {
    await _ensureAuthenticated();
    final response = await _dio.get<Map<String, dynamic>>(
      '/episodes/$episodeId/extended',
    );
    return response.data!;
  }
}
