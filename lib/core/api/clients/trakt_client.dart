import 'package:dio/dio.dart';
import 'package:safe_watch/core/api/api_config.dart';
import 'package:safe_watch/core/api/api_interceptors.dart';
import 'package:safe_watch/core/config/env_config.dart';

// ============================================================================
// Safe Watch — Trakt.tv Client
// ============================================================================
// Cliente Dio para Trakt.tv API v2.
// Documentação: https://trakt.docs.apiary.io/
//
// Responsabilidades:
//   - Sync de histórico (marcar como assistido)
//   - Watchlist (quero assistir)
//   - Check-in ("assistindo agora")
//   - Progresso por série
//   - OAuth token exchange (via TraktAuthService)
// ============================================================================

/// Cliente HTTP para a API Trakt.tv v2.
///
/// Requer que [accessToken] seja definido após o fluxo OAuth.
/// Use [TraktAuthService] para obter e persistir o token.
///
/// Singleton — use [TraktClient.instance].
class TraktClient {
  TraktClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.traktBaseUrl,
        connectTimeout:
            const Duration(seconds: ApiConfig.connectionTimeoutSeconds),
        receiveTimeout:
            const Duration(seconds: ApiConfig.receiveTimeoutSeconds),
        headers: {
          // Headers obrigatórios para todas as requisições Trakt.
          'trakt-api-version': ApiConfig.traktApiVersion,
          'trakt-api-key': EnvConfig.traktClientId,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(this),
      RateLimitInterceptor(),
      const LoggingInterceptor(),
    ]);
  }

  static final TraktClient instance = TraktClient._();

  late final Dio _dio;

  /// Access token OAuth 2.0 atual.
  /// Deve ser setado por [TraktAuthService] após autenticação.
  String? accessToken;

  // --------------------------------------------------------------------------
  // OAuth — Token Exchange
  // --------------------------------------------------------------------------

  /// Troca o código de autorização OAuth por access + refresh token.
  ///
  /// Endpoint: POST /oauth/token
  Future<Map<String, dynamic>> exchangeCode({
    required String code,
    required String redirectUri,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/oauth/token',
      data: {
        'code': code,
        'client_id': EnvConfig.traktClientId,
        'client_secret': EnvConfig.traktClientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
      // Não usa o AuthInterceptor aqui pois ainda não há token.
      options: Options(extra: {'skipAuth': true}),
    );
    return response.data!;
  }

  /// Atualiza o access token usando o refresh token.
  ///
  /// Endpoint: POST /oauth/token (com grant_type refresh_token)
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
    required String redirectUri,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/oauth/token',
      data: {
        'refresh_token': refreshToken,
        'client_id': EnvConfig.traktClientId,
        'client_secret': EnvConfig.traktClientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'refresh_token',
      },
      options: Options(extra: {'skipAuth': true}),
    );
    return response.data!;
  }

  /// Revoga o access token (logout do Trakt).
  ///
  /// Endpoint: POST /oauth/revoke
  Future<void> revokeToken(String token) async {
    await _dio.post<void>(
      '/oauth/revoke',
      data: {
        'token': token,
        'client_id': EnvConfig.traktClientId,
        'client_secret': EnvConfig.traktClientSecret,
      },
      options: Options(extra: {'skipAuth': true}),
    );
  }

  // --------------------------------------------------------------------------
  // Histórico (Watched)
  // --------------------------------------------------------------------------

  /// Adiciona episódios/filmes ao histórico do usuário.
  ///
  /// Endpoint: POST /sync/history
  /// [body] deve seguir o schema Trakt:
  /// ```json
  /// { "episodes": [{ "ids": { "trakt": 123 }, "watched_at": "2024-01-01T00:00:00.000Z" }] }
  /// ```
  Future<Map<String, dynamic>> addToHistory(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sync/history',
      data: body,
    );
    return response.data!;
  }

  /// Remove episódios/filmes do histórico do usuário.
  ///
  /// Endpoint: POST /sync/history/remove
  Future<Map<String, dynamic>> removeFromHistory(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sync/history/remove',
      data: body,
    );
    return response.data!;
  }

  /// Retorna o histórico de assistidos do usuário.
  ///
  /// Endpoint: GET /sync/history/{type}
  /// [type] pode ser: 'movies', 'shows', 'seasons', 'episodes'
  Future<List<dynamic>> getHistory({
    String type = 'episodes',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/sync/history/$type',
      queryParameters: {
        'page': page,
        'limit': limit,
        'extended': 'full',
      },
    );
    return response.data!;
  }

  // --------------------------------------------------------------------------
  // Watchlist (Quero Assistir)
  // --------------------------------------------------------------------------

  /// Adiciona séries/filmes à watchlist do usuário.
  ///
  /// Endpoint: POST /sync/watchlist
  Future<Map<String, dynamic>> addToWatchlist(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sync/watchlist',
      data: body,
    );
    return response.data!;
  }

  /// Remove séries/filmes da watchlist do usuário.
  ///
  /// Endpoint: POST /sync/watchlist/remove
  Future<Map<String, dynamic>> removeFromWatchlist(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sync/watchlist/remove',
      data: body,
    );
    return response.data!;
  }

  /// Retorna a watchlist do usuário.
  ///
  /// Endpoint: GET /sync/watchlist/{type}
  Future<List<dynamic>> getWatchlist({
    String type = 'shows',
    String sort = 'added',
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/sync/watchlist/$type/$sort',
      queryParameters: {'extended': 'full'},
    );
    return response.data!;
  }

  // --------------------------------------------------------------------------
  // Check-in ("assistindo agora")
  // --------------------------------------------------------------------------

  /// Faz check-in em um episódio (marca como "assistindo agora").
  ///
  /// Endpoint: POST /checkin
  /// Automaticamente expira após o runtime do episódio.
  Future<Map<String, dynamic>> checkin(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/checkin',
      data: body,
    );
    return response.data!;
  }

  /// Cancela o check-in ativo.
  ///
  /// Endpoint: DELETE /checkin
  Future<void> cancelCheckin() async {
    await _dio.delete<void>('/checkin');
  }

  // --------------------------------------------------------------------------
  // Progresso de Série
  // --------------------------------------------------------------------------

  /// Retorna o progresso de assistido de uma série para o usuário.
  ///
  /// Endpoint: GET /shows/{id}/progress/watched
  /// [id] é o slug ou ID Trakt da série.
  Future<Map<String, dynamic>> getShowProgress(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/shows/$id/progress/watched',
      queryParameters: {'hidden': false, 'specials': false},
    );
    return response.data!;
  }

  // --------------------------------------------------------------------------
  // IDs / Busca
  // --------------------------------------------------------------------------

  /// Busca uma série/filme pelo ID TMDB para obter os IDs Trakt.
  ///
  /// Endpoint: GET /search/{id_type}/{id}
  /// [idType] pode ser: 'tmdb', 'imdb', 'tvdb'
  Future<List<dynamic>> searchByExternalId({
    required String idType,
    required String id,
    String? type,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/search/$idType/$id',
      queryParameters: {
        if (type != null) 'type': type,
      },
    );
    return response.data!;
  }
}

// ----------------------------------------------------------------------------
// Auth Interceptor interno
// ----------------------------------------------------------------------------

/// Interceptor que injeta o Authorization header nas requisições autenticadas.
class _AuthInterceptor extends Interceptor {
  const _AuthInterceptor(this._client);

  final TraktClient _client;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final skipAuth = options.extra['skipAuth'] as bool? ?? false;

    if (!skipAuth && _client.accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${_client.accessToken}';
    }

    handler.next(options);
  }
}
