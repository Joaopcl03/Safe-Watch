import 'package:safe_watch/features/watched_list/models/watched_item_model.dart';

// ============================================================================
// Safe Watch — Watched List Repository Interface
// ============================================================================
// Contrato abstrato para persistência da lista de assistidos.
// Permite trocar entre implementações (mock, Isar, SQLite)
// sem alterar o controller ou a UI.
// ============================================================================

/// Interface abstrata do repositório de lista de assistidos.
///
/// Qualquer implementação (mock em memória, Isar, Drift)
/// deve implementar esta interface.
abstract interface class WatchedListRepositoryInterface {
  /// Retorna todos os itens da lista de assistidos.
  Future<List<WatchedItemModel>> getWatchedItems();

  /// Retorna itens filtrados por status.
  Future<List<WatchedItemModel>> getItemsByStatus(WatchedStatus status);

  /// Adiciona um item à lista.
  ///
  /// Se o item já existir (mesmo [mediaId] e [mediaType]),
  /// atualiza o existente.
  Future<void> addWatchedItem(WatchedItemModel item);

  /// Remove um item da lista pelo ID.
  Future<void> removeWatchedItem(String id);

  /// Atualiza um item existente.
  Future<void> updateWatchedItem(WatchedItemModel item);

  /// Verifica se uma mídia já está na lista.
  Future<bool> isMediaInList(int mediaId);
}
