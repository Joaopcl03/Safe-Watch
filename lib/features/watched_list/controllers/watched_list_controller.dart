import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_watch/features/search/models/episode_model.dart';
import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/watched_list/models/watched_item_model.dart';
import 'package:safe_watch/features/watched_list/repositories/trakt_repository.dart';
import 'package:safe_watch/features/watched_list/repositories/trakt_repository_interface.dart';
import 'package:safe_watch/features/watched_list/repositories/watched_list_repository.dart';
import 'package:safe_watch/features/watched_list/repositories/watched_list_repository_interface.dart';

// ============================================================================
// Safe Watch — Watched List Controller (Riverpod)
// ============================================================================
// Fluxo de dados:
//   WatchedListTemplate (UI)
//     → WatchedListController (lógica/estado)
//       → WatchedListRepository (persistência local + sync Trakt)
//         → WatchedItemModel (modelo)
//
// O controller NÃO contém lógica de UI.
// Ele expõe estado via AsyncNotifier e orquestra chamadas ao repository.
// ============================================================================

/// Provider do repositório Trakt.
///
/// Pode ser sobrescrito em testes com `overrides` para injetar mocks.
final traktRepositoryProvider = Provider<TraktRepositoryInterface>((ref) {
  return TraktRepository();
});

/// Provider do repositório de lista de assistidos.
///
/// Injeta o TraktRepository para sincronização remota.
final watchedListRepositoryProvider =
    Provider<WatchedListRepositoryInterface>((ref) {
  final traktRepo = ref.watch(traktRepositoryProvider);
  return WatchedListRepository(traktRepository: traktRepo);
});

/// Provider do controller de lista de assistidos.
///
/// Expõe `AsyncValue<List<WatchedItemModel>>` para a UI.
final watchedListControllerProvider = AsyncNotifierProvider<
    WatchedListController, List<WatchedItemModel>>(WatchedListController.new);

/// Controller da lista de assistidos usando Riverpod [AsyncNotifier].
///
/// Responsável por:
/// - Carregar a lista de itens assistidos do repositório
/// - Adicionar/remover itens com sync automático no Trakt
/// - Alternar status (assistido ↔ quero assistir)
/// - Atualizar progresso de episódios/temporadas
/// - Check-in de episódio via Trakt
/// - Marcar episódio individual como assistido
class WatchedListController extends AsyncNotifier<List<WatchedItemModel>> {
  late final WatchedListRepositoryInterface _repository;
  late final TraktRepositoryInterface _trakt;

  @override
  Future<List<WatchedItemModel>> build() async {
    _repository = ref.watch(watchedListRepositoryProvider);
    _trakt = ref.watch(traktRepositoryProvider);
    return _repository.getWatchedItems();
  }

  // --------------------------------------------------------------------------
  // CRUD básico
  // --------------------------------------------------------------------------

  /// Adiciona uma mídia à lista como "quero assistir".
  ///
  /// Salva localmente e sincroniza a watchlist no Trakt em background.
  Future<void> addToWatched(MediaModel media) async {
    final item = WatchedItemModel.fromMedia(
      media,
      status: WatchedStatus.wantToWatch,
    );

    await _repository.addWatchedItem(item);

    // Sync watchlist Trakt em background.
    _trakt.addToWatchlist([media]).catchError((_) {});

    state = AsyncData(await _repository.getWatchedItems());
  }

  /// Remove um item da lista pelo ID.
  ///
  /// Remove localmente e da watchlist/histórico do Trakt.
  Future<void> removeFromWatched(String id) async {
    await _repository.removeWatchedItem(id);
    state = AsyncData(await _repository.getWatchedItems());
  }

  // --------------------------------------------------------------------------
  // Status
  // --------------------------------------------------------------------------

  /// Alterna o status de um item entre assistido e quero assistir.
  ///
  /// Se o item estiver como "quero assistir", muda para "assistido"
  /// e registra a data + sincroniza o histórico do Trakt.
  /// Se estiver como "assistido", volta para "quero assistir".
  Future<void> toggleStatus(String id) async {
    final currentList = state.valueOrNull ?? [];
    final item = currentList.firstWhere((i) => i.id == id);

    final nowWatched = item.status != WatchedStatus.watched;

    final updatedItem = item.copyWith(
      status: nowWatched ? WatchedStatus.watched : WatchedStatus.wantToWatch,
      watchedAt: nowWatched ? DateTime.now() : null,
    );

    await _repository.updateWatchedItem(updatedItem);
    state = AsyncData(await _repository.getWatchedItems());
  }

  // --------------------------------------------------------------------------
  // Progresso por episódio
  // --------------------------------------------------------------------------

  /// Atualiza o progresso de episódios de uma série.
  ///
  /// [id]: ID do item na lista local.
  /// [season]: temporada atual.
  /// [episode]: episódio atual.
  Future<void> updateProgress({
    required String id,
    required int season,
    required int episode,
  }) async {
    final currentList = state.valueOrNull ?? [];
    final item = currentList.firstWhere((i) => i.id == id);

    final updatedItem = item.copyWith(
      seasonProgress: season,
      episodeProgress: episode,
    );

    await _repository.updateWatchedItem(updatedItem);
    state = AsyncData(await _repository.getWatchedItems());
  }

  /// Marca um episódio específico como assistido via Trakt.
  ///
  /// Atualiza o progresso local e sincroniza o histórico do Trakt
  /// com granularidade de episódio via `/sync/history`.
  ///
  /// [id]: ID do item na lista local.
  /// [episode]: episódio a ser marcado como assistido.
  /// [show]: mídia (série) para obter os IDs Trakt.
  Future<void> markEpisodeWatched({
    required String id,
    required EpisodeModel episode,
    required MediaModel show,
  }) async {
    // Atualiza progresso local.
    await updateProgress(
      id: id,
      season: episode.seasonNumber,
      episode: episode.episodeNumber,
    );

    // Cria item temporário para o sync do histórico de episódio.
    final episodeItem = WatchedItemModel(
      id: 'ep-${show.id}-s${episode.seasonNumber}e${episode.episodeNumber}',
      mediaId: show.id,
      title: '${show.title} ${episode.code}',
      posterPath: show.posterPath,
      mediaType: MediaType.tv,
      status: WatchedStatus.watched,
      watchedAt: DateTime.now(),
    );

    // Sync Trakt com o episódio específico em background.
    _trakt.syncToHistory([episodeItem]).catchError((_) {});
  }

  // --------------------------------------------------------------------------
  // Check-in
  // --------------------------------------------------------------------------

  /// Faz check-in em um episódio no Trakt ("assistindo agora").
  ///
  /// O check-in expira automaticamente após o runtime do episódio.
  /// Retorna true se o check-in foi bem-sucedido, false caso contrário.
  Future<bool> checkin(EpisodeModel episode, MediaModel show) async {
    try {
      await _trakt.checkin(episode, show);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cancela o check-in ativo no Trakt.
  Future<void> cancelCheckin() async {
    await _trakt.cancelCheckin().catchError((_) {});
  }
}
