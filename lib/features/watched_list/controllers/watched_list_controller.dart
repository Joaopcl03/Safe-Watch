import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_watch/core/api/clients/trakt_client.dart';
import 'package:safe_watch/core/config/env_config.dart';
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
//       → WatchedListRepository (persistência local)
//       → TraktRepository (sync remoto com Trakt.tv)
//         → TraktClient → Trakt API
//       → WatchedItemModel (modelo)
//
// O controller NÃO contém lógica de UI.
// Ele coordena entre repositório local e sync remoto com Trakt.
// ============================================================================

/// Provider do cliente Trakt.
final traktClientProvider = Provider<TraktClient>((ref) {
  return TraktClient();
});

/// Provider do repositório local de lista de assistidos.
final watchedListRepositoryProvider =
    Provider<WatchedListRepositoryInterface>((ref) {
  return WatchedListRepository();
});

/// Provider do repositório Trakt (nullable se não configurado).
final traktRepositoryProvider = Provider<TraktRepositoryInterface?>((ref) {
  if (!EnvConfig.isTraktConfigured) return null;
  return TraktRepository(traktClient: ref.watch(traktClientProvider));
});

/// Provider do controller de lista de assistidos.
final watchedListControllerProvider = AsyncNotifierProvider<
    WatchedListController, List<WatchedItemModel>>(WatchedListController.new);

/// Controller da lista de assistidos usando Riverpod [AsyncNotifier].
///
/// Coordena entre:
/// - [WatchedListRepository]: persistência local (offline-first)
/// - [TraktRepository]: sync remoto com Trakt.tv (quando autenticado)
///
/// Fluxo:
/// ```
/// WatchedListTemplate
///   └─► ref.read(watchedListControllerProvider.notifier).addToWatched(media)
///         └─► WatchedListRepository.addWatchedItem(item)  // local
///         └─► TraktRepository.addToWatchlist([media])      // remoto (se autenticado)
///         └─► state = AsyncData(updatedList)
///   └─► ref.watch(watchedListControllerProvider) → AsyncValue<List<WatchedItemModel>>
/// ```
class WatchedListController extends AsyncNotifier<List<WatchedItemModel>> {
  late final WatchedListRepositoryInterface _localRepository;
  TraktRepositoryInterface? _traktRepository;

  @override
  Future<List<WatchedItemModel>> build() async {
    _localRepository = ref.watch(watchedListRepositoryProvider);
    _traktRepository = ref.watch(traktRepositoryProvider);
    return _localRepository.getWatchedItems();
  }

  /// Adiciona uma mídia à lista como "quero assistir".
  ///
  /// Salva localmente e sincroniza com Trakt se autenticado.
  Future<void> addToWatched(MediaModel media) async {
    final item = WatchedItemModel.fromMedia(
      media,
      status: WatchedStatus.wantToWatch,
    );

    // 1. Salvar localmente (offline-first).
    await _localRepository.addWatchedItem(item);

    // 2. Sync com Trakt (se configurado e autenticado).
    if (_traktRepository != null) {
      try {
        await _traktRepository!.addToWatchlist([media]);
      } catch (_) {
        // Falha no sync remoto não deve bloquear a operação local.
        // TODO: Enfileirar para retry.
      }
    }

    // 3. Atualizar estado.
    state = AsyncData(await _localRepository.getWatchedItems());
  }

  /// Remove um item da lista.
  Future<void> removeFromWatched(String id) async {
    await _localRepository.removeWatchedItem(id);
    state = AsyncData(await _localRepository.getWatchedItems());
  }

  /// Alterna o status de um item entre assistido e quero assistir.
  ///
  /// Se marcar como assistido, sincroniza com Trakt.syncHistory.
  /// Se desmarcar, sincroniza com Trakt.removeFromHistory.
  Future<void> toggleStatus(String id) async {
    final currentList = state.valueOrNull ?? [];
    final item = currentList.firstWhere((i) => i.id == id);

    final newStatus = item.status == WatchedStatus.watched
        ? WatchedStatus.wantToWatch
        : WatchedStatus.watched;

    final updatedItem = item.copyWith(
      status: newStatus,
      watchedAt: newStatus == WatchedStatus.watched ? DateTime.now() : null,
    );

    // 1. Atualizar localmente.
    await _localRepository.updateWatchedItem(updatedItem);

    // 2. Sync com Trakt.
    if (_traktRepository != null) {
      try {
        if (newStatus == WatchedStatus.watched) {
          await _traktRepository!.syncToHistory([updatedItem]);
        } else {
          await _traktRepository!.removeFromHistory([updatedItem]);
        }
      } catch (_) {
        // TODO: Enfileirar para retry.
      }
    }

    state = AsyncData(await _localRepository.getWatchedItems());
  }

  /// Atualiza o progresso de episódios de uma série.
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

    await _localRepository.updateWatchedItem(updatedItem);
    state = AsyncData(await _localRepository.getWatchedItems());
  }

  /// Realiza check-in no Trakt ("assistindo agora").
  ///
  /// Disponível apenas quando Trakt está configurado e autenticado.
  Future<void> checkin({
    required int tmdbId,
    required MediaType mediaType,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    if (_traktRepository == null) return;

    await _traktRepository!.checkin(
      tmdbId: tmdbId,
      mediaType: mediaType,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }

  /// Cancela check-in ativo no Trakt.
  Future<void> cancelCheckin() async {
    if (_traktRepository == null) return;
    await _traktRepository!.cancelCheckin();
  }
}
