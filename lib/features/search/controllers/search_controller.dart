import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_watch/core/api/clients/tmdb_client.dart';
import 'package:safe_watch/core/api/clients/watchmode_client.dart';
import 'package:safe_watch/core/config/env_config.dart';
import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/search/models/season_model.dart';
import 'package:safe_watch/features/search/models/streaming_source_model.dart';
import 'package:safe_watch/features/search/repositories/search_repository.dart';
import 'package:safe_watch/features/search/repositories/search_repository_interface.dart';

// ============================================================================
// Safe Watch — Search Controller (Riverpod)
// ============================================================================
// Fluxo de dados:
//   SearchTemplate (UI)
//     → SearchMediaController (lógica/estado)
//       → SearchRepository (dados)
//         → TmdbClient → TMDB API → JSON
//         → WatchmodeClient → Watchmode API → JSON
//       → MediaModel / SeasonModel / StreamingSourceModel
//
// O controller NÃO contém lógica de UI.
// Ele expõe estado via AsyncNotifier e orquestra chamadas ao repository.
// ============================================================================

/// Provider do cliente TMDB.
final tmdbClientProvider = Provider<TmdbClient>((ref) {
  return TmdbClient();
});

/// Provider do cliente Watchmode (nullable se não configurado).
final watchmodeClientProvider = Provider<WatchmodeClient?>((ref) {
  if (!EnvConfig.isWatchmodeConfigured) return null;
  return WatchmodeClient();
});

/// Provider do repositório de busca.
///
/// Pode ser sobrescrito em testes com `overrides` para injetar mocks.
final searchRepositoryProvider = Provider<SearchRepositoryInterface>((ref) {
  return SearchRepository(
    tmdbClient: ref.watch(tmdbClientProvider),
    watchmodeClient: ref.watch(watchmodeClientProvider),
  );
});

/// Provider do controller de busca.
///
/// Expõe `AsyncValue<List<MediaModel>>` para a UI.
/// A UI reage a loading, data e error automaticamente.
final searchMediaControllerProvider = AsyncNotifierProvider<
    SearchMediaController, List<MediaModel>>(SearchMediaController.new);

// ── Providers de descoberta (Explorar / Em breve) ──────────────────────────

/// Mídias em tendência. `null` = séries e filmes misturados.
final trendingMediaProvider =
    FutureProvider.family<List<MediaModel>, MediaType?>((ref, type) {
  return ref.watch(searchRepositoryProvider).getTrending(mediaType: type);
});

/// Lançamentos em breve (filmes) ou séries no ar (TV).
final upcomingMediaProvider =
    FutureProvider.family<List<MediaModel>, MediaType>((ref, type) {
  return ref.watch(searchRepositoryProvider).getUpcoming(type);
});

/// Mídias populares por tipo.
final popularMediaProvider =
    FutureProvider.family<List<MediaModel>, MediaType>((ref, type) {
  return ref.watch(searchRepositoryProvider).getPopular(type);
});

/// Controller de busca de mídia usando Riverpod [AsyncNotifier].
///
/// Responsável por:
/// - Orquestrar buscas de mídia via [SearchRepositoryInterface]
/// - Buscar detalhes de séries/filmes
/// - Consultar disponibilidade em streaming
/// - Expor resultados como `AsyncValue<List<MediaModel>>`
///
/// Fluxo:
/// ```
/// SearchTemplate
///   └─► ref.read(searchMediaControllerProvider.notifier).searchMedia('query')
///         └─► SearchRepository.searchMedia('query')
///               └─► TmdbClient.searchMulti('query')
///                     └─► TMDB API → JSON
///               └─► retorna List<MediaModel>
///         └─► state = AsyncData(results)
///   └─► ref.watch(searchMediaControllerProvider) → AsyncValue<List<MediaModel>>
///         └─► .when() renderiza loading / data / error
/// ```
class SearchMediaController extends AsyncNotifier<List<MediaModel>> {
  late final SearchRepositoryInterface _repository;

  @override
  Future<List<MediaModel>> build() async {
    _repository = ref.watch(searchRepositoryProvider);
    // Estado inicial: lista vazia (nenhuma busca realizada).
    return [];
  }

  /// Busca mídias (séries + filmes) por título.
  ///
  /// Atualiza o estado para loading durante a busca
  /// e para data ou error ao finalizar.
  Future<void> searchMedia(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.searchMedia(query));
  }

  /// Busca apenas séries de TV.
  Future<void> searchTv(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.searchTv(query));
  }

  /// Busca apenas filmes.
  Future<void> searchMovies(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.searchMovies(query));
  }

  /// Limpa os resultados de busca.
  void clearResults() {
    state = const AsyncData([]);
  }

  /// Busca detalhes completos de uma série (com temporadas e IDs externos).
  ///
  /// Retorna [MediaModel] enriquecido com temporadas e external_ids.
  Future<MediaModel> getTvDetails(int tmdbId) async {
    return _repository.getTvDetails(tmdbId);
  }

  /// Busca detalhes completos de um filme.
  Future<MediaModel> getMovieDetails(int tmdbId) async {
    return _repository.getMovieDetails(tmdbId);
  }

  /// Busca detalhes de uma temporada com episódios.
  Future<SeasonModel> getSeasonDetails(int tmdbId, int seasonNumber) async {
    return _repository.getSeasonDetails(tmdbId, seasonNumber);
  }

  /// Busca fontes de streaming para um título.
  Future<List<StreamingSourceModel>> getStreamingSources(
    int tmdbId,
    MediaType mediaType, {
    String region = 'BR',
  }) async {
    return _repository.getStreamingSources(tmdbId, mediaType, region: region);
  }
}
