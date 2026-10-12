import 'package:dio/dio.dart';
import 'package:safe_watch/core/api/api_config.dart';
import 'package:safe_watch/core/api/api_interceptors.dart';

// ============================================================================
// Safe Watch — Trakt.tv API Client
// ============================================================================
// Cliente Dio para Trakt.tv API v2.
// Responsável por tracking de usuário: histórico, watchlist, check-in.
//
// Autenticação: OAuth 2.0 (Bearer token) + Client ID header.
// Base URL: https://api.trakt.tv
// Headers obrigatórios: trakt-api-version, trakt-api-key, Authorization
// Rate Limit: GET 1000/5min, POST/PUT/DELETE 1/s
// Docs: https://trakt.docs.apiary.io/
// ============================================================================

/// Cliente para a Trakt.tv API v2.
///
/// Gerencia tracking de episódios, watchlist, check-in e progresso.
/// Requer autenticação OAuth 2.0 para endpoints de usuário.
///
/// Fluxo: WatchedListRepository → TraktClient → Trakt API → JSON
class TraktClient {
  TraktClient({String? accessToken})
      : _accessToken = accessToken,
        _dio = _createDio(accessToken);

  String? _accessToken;
  Dio _dio;

  /// Atualiza o access token (após login ou refresh).
  void updateAccessToken(String token) {
    _accessToken = token;
    _dio = _createDio(token);
  }

  /// Se o cliente tem um token de autenticação válido.
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  /// Cria instância configurada do Dio para Trakt.
  static Dio _createDio(String? accessToken) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.traktBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'trakt-api-version': ApiConfig.traktApiVersion,
          'trakt-api-key': ApiConfig.traktClientId,
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    dio.interceptors.addAll([
      RateLimitInterceptor(),
      LoggingInterceptor(),
    ]);

    return dio;
  }

  // ── OAuth ────────────────────────────────────────────────────────────────

  /// Troca o código de autorização por access token.
  ///
  /// [code]: código recebido após o usuário autorizar no browser.
  /// Retorna mapa com access_token, refresh_token, expires_in, etc.
  Future<Map<String, dynamic>> exchangeCodeForToken(String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/oauth/token',
      data: {
        'code': code,
        'client_id': ApiConfig.traktClientId,
        'client_secret': ApiConfig.traktClientSecret,
        'redirect_uri': ApiConfig.traktRedirectUri,
        'grant_type': 'authorization_code',
      },
    );
    return response.data!;
  }

  /// Renova o access token usando o refresh token.
  ///
  /// [refreshToken]: refresh token atual (single-use, rotativo).
  /// Retorna novo par access_token + refresh_token.
  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/oauth/token',
      data: {
        'refresh_token': refreshToken,
        'client_id': ApiConfig.traktClientId,
        'client_secret': ApiConfig.traktClientSecret,
        'redirect_uri': ApiConfig.traktRedirectUri,
        'grant_type': 'refresh_token',
      },
    );
    return response.data!;
  }

  /// Revoga o access token (logout).
  Future<void> revokeToken(String token) async {
    await _dio.post<void>(
      '/oauth/revoke',
      data: {
        'token': token,
        'client_id': ApiConfig.traktClientId,
        'client_secret': ApiConfig.traktClientSecret,
      },
    );
  }

  // ── Sync History (Marcar como assistido) ─────────────────────────────────

  /// Marca itens como assistidos no histórico.
  ///
  /// Aceita shows, seasons e episodes com IDs cruzados (tmdb, tvdb, imdb).
  /// [data] segue o formato:
  /// ```json
  /// {
  ///   "shows": [{"ids": {"tmdb": 1396}, "seasons": [{"number": 1, "episodes": [...]}]}],
  ///   "episodes": [{"ids": {"tmdb": 62085}, "watched_at": "2024-01-01T00:00:00.000Z"}]
  /// }
  /// ```
  Future<Map<String, dynamic>> syncHistory(Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sync/history',
      data: data,
    );
    return response.data!;
  }

  /// Remove itens do histórico de assistidos.
  Future<Map<String, dynamic>> removeFromHistory(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sync/history/remove',
      data: data,
    );
    return response.data!;
  }

  /// Retorna o histórico de assistidos do usuário.
  ///
  /// [type]: 'shows', 'seasons', 'episodes'.
  /// [page]: página (padrão: 1).
  /// [limit]: itens por página (padrão: 20).
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
      },
    );
    return response.data!;
  }

  // ── Watchlist ────────────────────────────────────────────────────────────

  /// Adiciona itens à watchlist (quero assistir).
  Future<Map<String, dynamic>> addToWatchlist(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sync/watchlist',
      data: data,
    );
    return response.data!;
  }

  /// Remove itens da watchlist.
  Future<Map<String, dynamic>> removeFromWatchlist(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sync/watchlist/remove',
      data: data,
    );
    return response.data!;
  }

  /// Retorna a watchlist do usuário.
  ///
  /// [type]: 'shows', 'movies' ou 'episodes'.
  /// [sort]: 'rank', 'added', 'title', 'released'.
  Future<List<dynamic>> getWatchlist({
    String type = 'shows',
    String sort = 'added',
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/sync/watchlist/$type/$sort',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return response.data!;
  }

  // ── Check-in ────────────────────────────────────────────────────────────

  /// Realiza check-in ("assistindo agora").
  ///
  /// Só é possível ter um check-in ativo por vez.
  /// Retorna 409 Conflict se já houver um check-in ativo.
  Future<Map<String, dynamic>> checkin(Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/checkin',
      data: data,
    );
    return response.data!;
  }

  /// Cancela o check-in ativo.
  Future<void> cancelCheckin() async {
    await _dio.delete<void>('/checkin');
  }

  // ── Progresso ────────────────────────────────────────────────────────────

  /// Retorna progresso de uma série (episódios assistidos vs total).
  ///
  /// [showId]: ID ou slug da série no Trakt.
  Future<Map<String, dynamic>> getShowProgress(
    String showId, {
    bool hidden = false,
    bool specials = false,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/shows/$showId/progress/watched',
      queryParameters: {
        'hidden': hidden,
        'specials': specials,
      },
    );
    return response.data!;
  }

  // ── Search ──────────────────────────────────────────────────────────────

  /// Busca no Trakt por ID externo (TMDB, TVDB, IMDB).
  ///
  /// [idType]: 'tmdb', 'tvdb', 'imdb'.
  /// [type]: 'show', 'movie', 'episode'.
  Future<List<dynamic>> searchByExternalId(
    String id, {
    String idType = 'tmdb',
    String type = 'show',
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/search/$idType/$id',
      queryParameters: {'type': type},
    );
    return response.data!;
  }
}
