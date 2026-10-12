import 'package:safe_watch/core/api/clients/tmdb_client.dart';
import 'package:safe_watch/core/api/clients/watchmode_client.dart';
import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/search/models/season_model.dart';
import 'package:safe_watch/features/search/models/streaming_source_model.dart';
import 'package:safe_watch/features/search/repositories/search_repository_interface.dart';

// ============================================================================
// Safe Watch — Search Repository (TMDB + Watchmode)
// ============================================================================
// Implementação real do repositório de busca usando:
//   - TMDB API: catálogo, busca, detalhes, temporadas
//   - Watchmode API: disponibilidade em streaming
//
// Fluxo de dados:
//   SearchTemplate → SearchController → SearchRepository
//     → TmdbClient / WatchmodeClient → API → JSON → Model
// ============================================================================

/// Implementação do [SearchRepositoryInterface] usando TMDB + Watchmode.
///
/// Usa [TmdbClient] para busca e metadados de catálogo,
/// e [WatchmodeClient] para disponibilidade em streaming.
class SearchRepository implements SearchRepositoryInterface {
  SearchRepository({
    required TmdbClient tmdbClient,
    WatchmodeClient? watchmodeClient,
  })  : _tmdbClient = tmdbClient,
        _watchmodeClient = watchmodeClient;

  final TmdbClient _tmdbClient;
  final WatchmodeClient? _watchmodeClient;

  @override
  Future<List<MediaModel>> searchMedia(String query) async {
    if (query.trim().isEmpty) return [];

    // Busca multi no TMDB (séries + filmes + pessoas).
    // Filtra apenas TV e Movie (ignora Person).
    final response = await _tmdbClient.searchMulti(query);
    final results = response['results'] as List<dynamic>;

    return results
        .where((item) {
          final type = item['media_type'] as String?;
          return type == 'tv' || type == 'movie';
        })
        .map((item) => MediaModel.fromTmdbJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MediaModel>> searchTv(String query) async {
    if (query.trim().isEmpty) return [];

    final response = await _tmdbClient.searchTv(query);
    final results = response['results'] as List<dynamic>;

    return results
        .map((item) => MediaModel.fromTmdbJson(
              item as Map<String, dynamic>,
              forceType: MediaType.tv,
            ))
        .toList();
  }

  @override
  Future<List<MediaModel>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];

    final response = await _tmdbClient.searchMovie(query);
    final results = response['results'] as List<dynamic>;

    return results
        .map((item) => MediaModel.fromTmdbJson(
              item as Map<String, dynamic>,
              forceType: MediaType.movie,
            ))
        .toList();
  }

  @override
  Future<MediaModel> getTvDetails(int tmdbId) async {
    // Busca detalhes com external_ids para cross-reference.
    final response = await _tmdbClient.getTvDetails(
      tmdbId,
      appendToResponse: 'external_ids',
    );

    return MediaModel.fromTmdbDetailsJson(response, type: MediaType.tv);
  }

  @override
  Future<MediaModel> getMovieDetails(int tmdbId) async {
    final response = await _tmdbClient.getMovieDetails(
      tmdbId,
      appendToResponse: 'external_ids',
    );

    return MediaModel.fromTmdbDetailsJson(response, type: MediaType.movie);
  }

  @override
  Future<SeasonModel> getSeasonDetails(int tmdbId, int seasonNumber) async {
    final response = await _tmdbClient.getSeasonDetails(tmdbId, seasonNumber);
    return SeasonModel.fromTmdbJson(response);
  }

  @override
  Future<List<StreamingSourceModel>> getStreamingSources(
    int tmdbId,
    MediaType mediaType, {
    String region = 'BR',
  }) async {
    // Se Watchmode não está configurado, retorna lista vazia.
    if (_watchmodeClient == null) return [];

    try {
      // 1. Buscar o Watchmode ID usando o TMDB ID.
      final searchType =
          mediaType == MediaType.tv ? 'tmdb_tv_id' : 'tmdb_movie_id';
      final searchResult = await _watchmodeClient.searchByTmdbId(
        tmdbId,
        type: searchType,
      );

      final titleResults = searchResult['title_results'] as List<dynamic>?;
      if (titleResults == null || titleResults.isEmpty) return [];

      final watchmodeId =
          (titleResults.first as Map<String, dynamic>)['id'] as int;

      // 2. Buscar fontes de streaming para o título.
      final sources = await _watchmodeClient.getSourcesForTitle(
        watchmodeId,
        regions: region,
      );

      return sources
          .map((s) => StreamingSourceModel.fromWatchmodeJson(
                s as Map<String, dynamic>,
              ))
          .toList();
    } catch (e) {
      // Fallback: retornar lista vazia se Watchmode falhar.
      return [];
    }
  }

  @override
  Future<List<MediaModel>> getTrending({MediaType? mediaType}) async {
    final typePath = switch (mediaType) {
      MediaType.tv => 'tv',
      MediaType.movie => 'movie',
      null => 'all',
    };
    final response = await _tmdbClient.getTrending(mediaType: typePath);
    return _parseResults(response, forceType: mediaType);
  }

  @override
  Future<List<MediaModel>> getUpcoming(MediaType mediaType) async {
    final response = mediaType == MediaType.movie
        ? await _tmdbClient.getUpcomingMovies()
        : await _tmdbClient.getOnTheAirTv();
    return _parseResults(response, forceType: mediaType);
  }

  @override
  Future<List<MediaModel>> getPopular(MediaType mediaType) async {
    final response = await _tmdbClient.getPopular(
      mediaType: mediaType == MediaType.tv ? 'tv' : 'movie',
    );
    return _parseResults(response, forceType: mediaType);
  }

  /// Converte a lista `results` do TMDB em [MediaModel], ignorando pessoas.
  List<MediaModel> _parseResults(
    Map<String, dynamic> response, {
    MediaType? forceType,
  }) {
    final results = response['results'] as List<dynamic>? ?? const [];
    return results
        .cast<Map<String, dynamic>>()
        .where((item) {
          if (forceType != null) return true;
          final type = item['media_type'] as String?;
          return type == 'tv' || type == 'movie';
        })
        .map((item) => MediaModel.fromTmdbJson(item, forceType: forceType))
        .toList();
  }
}
