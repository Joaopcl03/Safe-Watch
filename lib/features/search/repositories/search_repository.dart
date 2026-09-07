import 'package:dio/dio.dart';
import 'package:safe_watch/core/api/api_config.dart';
import 'package:safe_watch/core/api/clients/tmdb_client.dart';
import 'package:safe_watch/core/api/clients/watchmode_client.dart';
import 'package:safe_watch/core/config/env_config.dart';
import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/search/models/season_model.dart';
import 'package:safe_watch/features/search/models/streaming_source_model.dart';
import 'package:safe_watch/features/search/repositories/search_repository_interface.dart';

// ============================================================================
// Safe Watch — Search Repository (TMDB + Watchmode)
// ============================================================================
// Implementação real do repositório de busca usando:
//   - TMDB como fonte primária para busca, detalhes e temporadas
//   - Watchmode como fonte primária para streaming
//   - TMDB /watch/providers como fallback para streaming
// ============================================================================

/// Implementação real do [SearchRepositoryInterface].
///
/// Usa [TmdbClient] para busca e detalhes de mídia,
/// e [WatchmodeClient] para disponibilidade em streaming.
class SearchRepository implements SearchRepositoryInterface {
  SearchRepository({
    TmdbClient? tmdbClient,
    WatchmodeClient? watchmodeClient,
  })  : _tmdb = tmdbClient ?? TmdbClient.instance,
        _watchmode = watchmodeClient ?? WatchmodeClient.instance;

  final TmdbClient _tmdb;
  final WatchmodeClient _watchmode;

  // --------------------------------------------------------------------------
  // Busca
  // --------------------------------------------------------------------------

  @override
  Future<List<MediaModel>> searchMedia(String query) async {
    if (query.trim().isEmpty) return [];
    _assertApiKeyConfigured();

    try {
      final data = await _tmdb.searchMulti(query);
      final results = (data['results'] as List<dynamic>?) ?? [];

      return results
          .cast<Map<String, dynamic>>()
          .where((r) =>
              r['media_type'] == 'tv' || r['media_type'] == 'movie')
          .map(MediaModel.fromTmdbSearchJson)
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<MediaModel>> searchTv(String query) async {
    if (query.trim().isEmpty) return [];
    _assertApiKeyConfigured();

    try {
      final data = await _tmdb.searchTv(query);
      final results = (data['results'] as List<dynamic>?) ?? [];

      return results
          .cast<Map<String, dynamic>>()
          .map((r) => MediaModel.fromTmdbSearchJson(r, forceType: MediaType.tv))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<MediaModel>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];
    _assertApiKeyConfigured();

    try {
      final data = await _tmdb.searchMovie(query);
      final results = (data['results'] as List<dynamic>?) ?? [];

      return results
          .cast<Map<String, dynamic>>()
          .map((r) =>
              MediaModel.fromTmdbSearchJson(r, forceType: MediaType.movie))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // --------------------------------------------------------------------------
  // Detalhes
  // --------------------------------------------------------------------------

  @override
  Future<MediaModel> getMediaDetails(int id, MediaType mediaType) async {
    if (mediaType == MediaType.tv) return getTvDetails(id);
    _assertApiKeyConfigured();

    try {
      final data = await _tmdb.getMovieDetails(
        id,
        appendToResponse: 'external_ids',
      );
      return MediaModel.fromTmdbDetailsJson(data, MediaType.movie);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<MediaModel> getTvDetails(int tmdbId) async {
    _assertApiKeyConfigured();

    try {
      final data = await _tmdb.getTvDetails(
        tmdbId,
        appendToResponse: 'external_ids',
      );
      return MediaModel.fromTmdbDetailsJson(data, MediaType.tv);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<SeasonModel> getSeasonDetails(int tmdbId, int seasonNumber) async {
    _assertApiKeyConfigured();

    try {
      final data = await _tmdb.getSeasonDetails(tmdbId, seasonNumber);
      return SeasonModel.fromTmdbJson(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // --------------------------------------------------------------------------
  // Streaming
  // --------------------------------------------------------------------------

  @override
  Future<List<StreamingSourceModel>> getStreamingSources(
    int tmdbId,
    MediaType mediaType, {
    String region = ApiConfig.tmdbDefaultRegion,
  }) async {
    // Tenta Watchmode primeiro.
    try {
      final sources = await _watchmode.getSourcesByTmdbId(
        tmdbId: tmdbId,
        mediaType: mediaType == MediaType.tv ? 'tv' : 'movie',
        regions: [region],
      );

      if (sources.isNotEmpty) {
        return sources
            .cast<Map<String, dynamic>>()
            .map(StreamingSourceModel.fromWatchmodeJson)
            .toList();
      }
    } catch (_) {
      // Watchmode falhou — usa fallback TMDB.
    }

    // Fallback: TMDB /watch/providers (JustWatch).
    return _getStreamingSourcesFromTmdb(tmdbId, mediaType, region);
  }

  /// Fallback: obtém fontes de streaming via TMDB JustWatch.
  Future<List<StreamingSourceModel>> _getStreamingSourcesFromTmdb(
    int tmdbId,
    MediaType mediaType,
    String region,
  ) async {
    try {
      final Map<String, dynamic> data;
      if (mediaType == MediaType.tv) {
        data = await _tmdb.getTvWatchProviders(tmdbId, region: region);
      } else {
        data = await _tmdb.getMovieWatchProviders(tmdbId, region: region);
      }

      final sources = <StreamingSourceModel>[];

      final typeMap = {
        'flatrate': StreamingType.subscription,
        'free': StreamingType.free,
        'rent': StreamingType.rent,
        'buy': StreamingType.buy,
      };

      for (final entry in typeMap.entries) {
        final providers = (data[entry.key] as List<dynamic>?) ?? [];
        sources.addAll(
          providers.cast<Map<String, dynamic>>().map(
                (p) => StreamingSourceModel.fromTmdbProviderJson(
                  p,
                  providerType: entry.value,
                  region: region,
                ),
              ),
        );
      }

      return sources;
    } on DioException {
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  /// Verifica se a API key do TMDB está configurada e lança erro amigável.
  void _assertApiKeyConfigured() {
    if (EnvConfig.tmdbApiKey.isEmpty) {
      throw const ApiKeyMissingException(
        'API key do TMDB não configurada.\n'
        'Execute o app com:\n'
        'flutter run --dart-define=TMDB_API_KEY=sua_chave',
      );
    }
  }

  /// Converte [DioException] em mensagem de erro legível para o usuário.
  Exception _mapDioError(DioException e) {
    final status = e.response?.statusCode;

    if (status == 401) {
      return const ApiKeyMissingException(
        'Chave da API inválida ou não autorizada.\n'
        'Verifique sua TMDB_API_KEY em:\n'
        'themoviedb.org/settings/api',
      );
    }

    if (status == 404) {
      return Exception('Conteúdo não encontrado.');
    }

    if (status == 429) {
      return Exception('Limite de requisições atingido. Tente novamente em instantes.');
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Tempo de conexão esgotado. Verifique sua internet.');
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception('Sem conexão com a internet.');
    }

    return Exception('Erro ao buscar: ${e.message}');
  }
}

// ----------------------------------------------------------------------------
// Exceções de API
// ----------------------------------------------------------------------------

/// Lançada quando a API key não está configurada ou é inválida (401).
class ApiKeyMissingException implements Exception {
  const ApiKeyMissingException(this.message);
  final String message;

  @override
  String toString() => message;
}
