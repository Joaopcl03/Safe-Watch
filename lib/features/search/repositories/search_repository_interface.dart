import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/search/models/season_model.dart';
import 'package:safe_watch/features/search/models/streaming_source_model.dart';

// ============================================================================
// Safe Watch — Search Repository Interface
// ============================================================================
// Contrato abstrato para busca de mídia e dados relacionados.
// Permite trocar entre implementações (mock, TMDB API, outras APIs)
// sem alterar o controller ou a UI.
// ============================================================================

/// Interface abstrata do repositório de busca de mídia.
///
/// Qualquer implementação (mock, TMDB real, etc.)
/// deve implementar esta interface.
abstract interface class SearchRepositoryInterface {
  // --------------------------------------------------------------------------
  // Busca
  // --------------------------------------------------------------------------

  /// Busca mídias (séries + filmes) por título.
  ///
  /// Implementação padrão: usa TMDB `/search/multi`.
  /// [query] é o termo de busca.
  Future<List<MediaModel>> searchMedia(String query);

  /// Busca apenas séries de TV por título.
  ///
  /// Usa TMDB `/search/tv`. Retorna resultados com [MediaType.tv].
  Future<List<MediaModel>> searchTv(String query);

  /// Busca apenas filmes por título.
  ///
  /// Usa TMDB `/search/movie`. Retorna resultados com [MediaType.movie].
  Future<List<MediaModel>> searchMovies(String query);

  // --------------------------------------------------------------------------
  // Detalhes
  // --------------------------------------------------------------------------

  /// Retorna os detalhes básicos de uma mídia pelo ID TMDB.
  ///
  /// [id] é o TMDB ID. [mediaType] indica se é filme ou série.
  Future<MediaModel> getMediaDetails(int id, MediaType mediaType);

  /// Retorna os detalhes completos de uma série de TV.
  ///
  /// Inclui temporadas, IDs externos (imdb, tvdb) e status de produção.
  /// Usa TMDB `/tv/{id}?append_to_response=external_ids`.
  Future<MediaModel> getTvDetails(int tmdbId);

  /// Retorna os detalhes de uma temporada específica com todos os episódios.
  ///
  /// Usa TMDB `/tv/{id}/season/{num}`.
  Future<SeasonModel> getSeasonDetails(int tmdbId, int seasonNumber);

  // --------------------------------------------------------------------------
  // Streaming
  // --------------------------------------------------------------------------

  /// Retorna as fontes de streaming disponíveis para um título.
  ///
  /// Usa Watchmode como fonte primária e TMDB `/watch/providers` como fallback.
  /// [region] é o código de país (ex: 'BR', 'US').
  Future<List<StreamingSourceModel>> getStreamingSources(
    int tmdbId,
    MediaType mediaType, {
    String region = 'BR',
  });
}
