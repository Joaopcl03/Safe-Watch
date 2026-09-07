import 'package:dio/dio.dart';
import 'package:safe_watch/core/api/api_config.dart';
import 'package:safe_watch/core/api/api_interceptors.dart';
import 'package:safe_watch/core/config/env_config.dart';

// ============================================================================
// Safe Watch — TheTVDB Client
// ============================================================================
// Cliente Dio para TheTVDB API v4.
// Documentação: https://thetvdb.github.io/v4-api/
//
// Responsabilidades:
//   - Login JWT (POST /login) com cache de 30 dias
//   - Busca de séries
//   - Detalhes estendidos de série
//   - Episódios por temporada com ordens alternativas (DVD, Absolute)
//   - Artworks (posters, backdrops, banners)
// ============================================================================

/// Cliente HTTP para a API TheTVDB v4.
///
/// Gerencia automaticamente o JWT: faz login quando necessário e
/// recicla o token antes da expiração de 30 dias.
///
/// Singleton — use [TvdbClient.instance].
class TvdbClient {
  TvdbClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.tvdbBaseUrl,
        connectTimeout:
            const Duration(seconds: ApiConfig.connectionTimeoutSeconds),
        receiveTimeout:
            const Duration(seconds: ApiConfig.receiveTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _TvdbAuthInterceptor(this),
      RateLimitInterceptor(),
      const LoggingInterceptor(),
      CacheInterceptor(maxAge: const Duration(hours: 6)),
    ]);
  }

  static final TvdbClient instance = TvdbClient._();

  late final Dio _dio;

  /// JWT atual do TheTVDB.
  String? _jwtToken;

  /// Timestamp da última obtenção do JWT.
  DateTime? _tokenObtainedAt;

  // --------------------------------------------------------------------------
  // Autenticação JWT
  // --------------------------------------------------------------------------

  /// Verifica se o token atual está válido (menos de 30 dias).
  bool get _isTokenValid {
    if (_jwtToken == null || _tokenObtainedAt == null) return false;
    final age = DateTime.now().difference(_tokenObtainedAt!);
    return age.inDays < ApiConfig.tvdbTokenValidityDays;
  }

  /// Faz login no TheTVDB e obtém/renova o JWT.
  ///
  /// Endpoint: POST /login
  /// O token é válido por 30 dias.
  Future<void> ensureAuthenticated() async {
    if (_isTokenValid) return;

    final response = await _dio.post<Map<String, dynamic>>(
      ApiConfig.tvdbLoginEndpoint,
      data: {'apikey': EnvConfig.tvdbApiKey},
      options: Options(extra: {'skipAuth': true}),
    );

    final data = response.data?['data'] as Map<String, dynamic>?;
    _jwtToken = data?['token'] as String?;
    _tokenObtainedAt = DateTime.now();
  }

  // --------------------------------------------------------------------------
  // Busca
  // --------------------------------------------------------------------------

  /// Busca séries por título.
  ///
  /// Endpoint: GET /search
  Future<List<dynamic>> searchSeries(
    String query, {
    String? language,
    int? limit,
  }) async {
    await ensureAuthenticated();
    final response = await _dio.get<Map<String, dynamic>>(
      '/search',
      queryParameters: {
        'query': query,
        'type': 'series',
        if (language != null) 'language': language,
        if (limit != null) 'limit': limit,
      },
    );
    return (response.data?['data'] as List<dynamic>?) ?? [];
  }

  /// Busca por ID remoto (TMDB, IMDB, etc.).
  ///
  /// Endpoint: GET /search/remoteid/{remoteId}
  /// Útil para cross-reference: dado um TMDB ID, encontrar o TVDB ID.
  Future<List<dynamic>> searchByRemoteId(String remoteId) async {
    await ensureAuthenticated();
    final response = await _dio.get<Map<String, dynamic>>(
      '/search/remoteid/$remoteId',
    );
    return (response.data?['data'] as List<dynamic>?) ?? [];
  }

  // --------------------------------------------------------------------------
  // Detalhes de Série
  // --------------------------------------------------------------------------

  /// Retorna os detalhes básicos de uma série pelo ID TheTVDB.
  ///
  /// Endpoint: GET /series/{id}
  Future<Map<String, dynamic>> getSeriesById(int id) async {
    await ensureAuthenticated();
    final response = await _dio.get<Map<String, dynamic>>('/series/$id');
    return (response.data?['data'] as Map<String, dynamic>?) ?? {};
  }

  /// Retorna os detalhes estendidos de uma série (com temporadas, artworks, etc.).
  ///
  /// Endpoint: GET /series/{id}/extended
  Future<Map<String, dynamic>> getSeriesExtended(
    int id, {
    String? meta,
    bool short = false,
  }) async {
    await ensureAuthenticated();
    final response = await _dio.get<Map<String, dynamic>>(
      '/series/$id/extended',
      queryParameters: {
        if (meta != null) 'meta': meta,
        if (short) 'short': 'true',
      },
    );
    return (response.data?['data'] as Map<String, dynamic>?) ?? {};
  }

  // --------------------------------------------------------------------------
  // Episódios
  // --------------------------------------------------------------------------

  /// Retorna os episódios de uma série pela ordem padrão (aired order).
  ///
  /// Endpoint: GET /series/{id}/episodes/default
  Future<Map<String, dynamic>> getEpisodesByDefault(
    int seriesId, {
    int page = 0,
    String? language,
  }) async {
    await ensureAuthenticated();
    final response = await _dio.get<Map<String, dynamic>>(
      '/series/$seriesId/episodes/default',
      queryParameters: {
        'page': page,
        if (language != null) 'lang': language,
      },
    );
    return (response.data?['data'] as Map<String, dynamic>?) ?? {};
  }

  /// Retorna os episódios de uma série em uma ordem alternativa.
  ///
  /// Endpoint: GET /series/{id}/episodes/{season-type}
  /// [seasonType] pode ser: 'default', 'dvd', 'absolute', 'alternate',
  ///              'regional', 'altdvd', 'officialrating', 'pilot'
  Future<Map<String, dynamic>> getEpisodesBySeasonType(
    int seriesId,
    String seasonType, {
    int page = 0,
    String? language,
    int? season,
  }) async {
    await ensureAuthenticated();
    final response = await _dio.get<Map<String, dynamic>>(
      '/series/$seriesId/episodes/$seasonType',
      queryParameters: {
        'page': page,
        if (language != null) 'lang': language,
        if (season != null) 'season': season,
      },
    );
    return (response.data?['data'] as Map<String, dynamic>?) ?? {};
  }

  // --------------------------------------------------------------------------
  // Artworks
  // --------------------------------------------------------------------------

  /// Retorna os artworks (imagens) de uma série.
  ///
  /// Endpoint: GET /series/{id}/artworks
  /// [type] filtra por tipo: 1=banner, 2=poster, 3=background, 22=icon
  Future<List<dynamic>> getSeriesArtworks(
    int seriesId, {
    int? type,
    String? language,
  }) async {
    await ensureAuthenticated();
    final response = await _dio.get<Map<String, dynamic>>(
      '/series/$seriesId/artworks',
      queryParameters: {
        if (type != null) 'type': type,
        if (language != null) 'lang': language,
      },
    );
    return (response.data?['data'] as List<dynamic>?) ?? [];
  }
}

// ----------------------------------------------------------------------------
// Auth Interceptor interno
// ----------------------------------------------------------------------------

/// Interceptor que injeta o JWT do TheTVDB nas requisições autenticadas.
class _TvdbAuthInterceptor extends Interceptor {
  const _TvdbAuthInterceptor(this._client);

  final TvdbClient _client;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final skipAuth = options.extra['skipAuth'] as bool? ?? false;

    if (!skipAuth && _client._jwtToken != null) {
      options.headers['Authorization'] = 'Bearer ${_client._jwtToken}';
    }

    handler.next(options);
  }
}
