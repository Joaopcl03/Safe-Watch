import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_watch/core/api/api_config.dart';
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
//       → SearchRepository (dados/API)
//         → MediaModel (modelo)
//
// O controller NÃO contém lógica de UI.
// Ele expõe estado via AsyncNotifier e orquestra chamadas ao repository.
// ============================================================================

/// Provider do repositório de busca.
///
/// Pode ser sobrescrito em testes com `overrides` para injetar mocks.
final searchRepositoryProvider = Provider<SearchRepositoryInterface>((ref) {
  return SearchRepository();
});

/// Provider do controller de busca.
///
/// Expõe `AsyncValue<List<MediaModel>>` para a UI.
final searchMediaControllerProvider = AsyncNotifierProvider<
    SearchMediaController, List<MediaModel>>(SearchMediaController.new);

/// Provider para o estado de detalhes de uma mídia selecionada.
///
/// Expõe `AsyncValue<MediaModel?>` — null quando nenhuma mídia está selecionada.
final mediaDetailsControllerProvider =
    AsyncNotifierProvider<MediaDetailsController, MediaModel?>(
  MediaDetailsController.new,
);

/// Provider para o estado das fontes de streaming.
///
/// Expõe `AsyncValue<List<StreamingSourceModel>>`.
final streamingSourcesControllerProvider = AsyncNotifierProvider<
    StreamingSourcesController,
    List<StreamingSourceModel>>(StreamingSourcesController.new);

// ============================================================================
// SearchMediaController
// ============================================================================

/// Controller de busca de mídia usando Riverpod [AsyncNotifier].
///
/// Responsável por:
/// - Orquestrar buscas de mídia via [SearchRepositoryInterface]
/// - Expor resultados como `AsyncValue<List<MediaModel>>`
/// - Suportar busca multi, somente TV, somente filmes
class SearchMediaController extends AsyncNotifier<List<MediaModel>> {
  late final SearchRepositoryInterface _repository;

  @override
  Future<List<MediaModel>> build() async {
    _repository = ref.watch(searchRepositoryProvider);
    return [];
  }

  /// Busca séries e filmes por título (multi-search).
  ///
  /// [query]: termo de busca informado pelo usuário.
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
}

// ============================================================================
// MediaDetailsController
// ============================================================================

/// Controller para carregamento de detalhes completos de uma mídia.
///
/// Responsável por:
/// - Carregar detalhes via [SearchRepositoryInterface.getTvDetails] ou [getMediaDetails]
/// - Expor o [MediaModel] completo (com temporadas e IDs externos)
class MediaDetailsController extends AsyncNotifier<MediaModel?> {
  late final SearchRepositoryInterface _repository;

  @override
  Future<MediaModel?> build() async {
    _repository = ref.watch(searchRepositoryProvider);
    return null;
  }

  /// Carrega os detalhes completos de uma série de TV pelo TMDB ID.
  ///
  /// Inclui temporadas, IDs externos (imdb, tvdb) e status de produção.
  Future<void> loadTvDetails(int tmdbId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.getTvDetails(tmdbId),
    );
  }

  /// Carrega os detalhes de qualquer mídia pelo TMDB ID e tipo.
  Future<void> loadDetails(int tmdbId, MediaType mediaType) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.getMediaDetails(tmdbId, mediaType),
    );
  }

  /// Carrega os detalhes de uma temporada específica.
  ///
  /// Atualiza o [MediaModel] atual com os episódios da temporada carregada.
  Future<void> loadSeasonDetails(int tmdbId, int seasonNumber) async {
    final currentMedia = state.valueOrNull;
    if (currentMedia == null) return;

    state = const AsyncLoading();

    final season = await AsyncValue.guard<SeasonModel>(
      () => _repository.getSeasonDetails(tmdbId, seasonNumber),
    );

    state = season.when(
      data: (loadedSeason) {
        // Substitui a temporada na lista com os episódios carregados.
        final updatedSeasons = currentMedia.seasons.map((s) {
          return s.seasonNumber == seasonNumber ? loadedSeason : s;
        }).toList();

        return AsyncData(currentMedia.copyWith(seasons: updatedSeasons));
      },
      loading: () => const AsyncLoading(),
      error: (e, st) => AsyncError(e, st),
    );
  }

  /// Limpa os detalhes carregados.
  void clear() {
    state = const AsyncData(null);
  }
}

// ============================================================================
// StreamingSourcesController
// ============================================================================

/// Controller para carregamento de fontes de streaming.
///
/// Responsável por:
/// - Buscar disponibilidade via Watchmode (primário) + TMDB (fallback)
/// - Expor `AsyncValue<List<StreamingSourceModel>>`
class StreamingSourcesController
    extends AsyncNotifier<List<StreamingSourceModel>> {
  late final SearchRepositoryInterface _repository;

  @override
  Future<List<StreamingSourceModel>> build() async {
    _repository = ref.watch(searchRepositoryProvider);
    return [];
  }

  /// Carrega as fontes de streaming para uma mídia.
  ///
  /// [tmdbId]: ID TMDB da mídia.
  /// [mediaType]: tipo da mídia (filme ou série).
  /// [region]: código de país (padrão: 'BR').
  Future<void> loadSources(
    int tmdbId,
    MediaType mediaType, {
    String region = ApiConfig.tmdbDefaultRegion,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.getStreamingSources(tmdbId, mediaType, region: region),
    );
  }

  /// Limpa as fontes carregadas.
  void clear() {
    state = const AsyncData([]);
  }
}
