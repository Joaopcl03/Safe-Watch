import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/search/models/season_model.dart';
import 'package:safe_watch/features/search/models/streaming_source_model.dart';

// ============================================================================
// Safe Watch — Search Repository Interface
// ============================================================================
// Contrato abstrato para busca e consulta de mídia.
// Primário: TMDB (catálogo, imagens, busca)
// Secundário: TheTVDB (metadados detalhados), Watchmode (streaming)
// ============================================================================

/// Interface abstrata do repositório de busca de mídia.
///
/// Define o contrato para busca, detalhes, temporadas
/// e disponibilidade em streaming.
abstract interface class SearchRepositoryInterface {
  /// Busca séries e filmes por título.
  ///
  /// [query] é o termo de busca.
  /// Retorna lista combinada de séries e filmes.
  Future<List<MediaModel>> searchMedia(String query);

  /// Busca apenas séries de TV por título.
  Future<List<MediaModel>> searchTv(String query);

  /// Busca apenas filmes por título.
  Future<List<MediaModel>> searchMovies(String query);

  /// Retorna detalhes completos de uma série, incluindo temporadas e IDs externos.
  ///
  /// [tmdbId] é o ID da série no TMDB.
  Future<MediaModel> getTvDetails(int tmdbId);

  /// Retorna detalhes completos de um filme.
  Future<MediaModel> getMovieDetails(int tmdbId);

  /// Retorna detalhes de uma temporada com lista de episódios.
  ///
  /// [tmdbId] é o ID da série no TMDB.
  /// [seasonNumber] é o número da temporada.
  Future<SeasonModel> getSeasonDetails(int tmdbId, int seasonNumber);

  /// Retorna as fontes de streaming disponíveis para um título.
  ///
  /// [tmdbId] é o ID no TMDB.
  /// [mediaType] indica se é filme ou série.
  /// [region] é o código do país (ex: 'BR').
  Future<List<StreamingSourceModel>> getStreamingSources(
    int tmdbId,
    MediaType mediaType, {
    String region,
  });

  /// Retorna mídias em tendência.
  ///
  /// [mediaType] nulo retorna séries e filmes misturados.
  Future<List<MediaModel>> getTrending({MediaType? mediaType});

  /// Retorna lançamentos em breve (filmes) ou séries no ar (TV).
  Future<List<MediaModel>> getUpcoming(MediaType mediaType);

  /// Retorna mídias populares do tipo informado.
  Future<List<MediaModel>> getPopular(MediaType mediaType);
}
