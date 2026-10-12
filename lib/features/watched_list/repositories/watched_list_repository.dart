import 'package:safe_watch/features/watched_list/models/watched_item_model.dart';
import 'package:safe_watch/features/watched_list/repositories/watched_list_repository_interface.dart';

// ============================================================================
// Safe Watch — Watched List Repository (Local Storage)
// ============================================================================
// Repositório de persistência local para a lista de assistidos.
// A sincronização com Trakt é gerenciada pelo WatchedListController.
//
// Estratégia offline-first:
//   - Leitura/Escrita: dados locais imediatos
//   - Sync remoto: controlado pelo controller, não pelo repository
//
// TODO: Substituir lista em memória por Isar para persistência real.
// ============================================================================

/// Implementação local do repositório de lista de assistidos.
///
/// Armazena dados em memória (mock). Substituir por Isar para produção.
/// Sync remoto com Trakt é gerenciado pelo [WatchedListController].
class WatchedListRepository implements WatchedListRepositoryInterface {
  WatchedListRepository();

  /// Armazenamento em memória.
  /// TODO: Substituir por Isar collection.
  final List<WatchedItemModel> _items = [];

  // --------------------------------------------------------------------------
  // Leitura
  // --------------------------------------------------------------------------

  @override
  Future<List<WatchedItemModel>> getWatchedItems() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<List<WatchedItemModel>> getItemsByStatus(
    WatchedStatus status,
  ) async {
    return _items.where((item) => item.status == status).toList();
  }

  @override
  Future<bool> isMediaInList(int mediaId) async {
    return _items.any((item) => item.mediaId == mediaId);
  }

  // --------------------------------------------------------------------------
  // Escrita
  // --------------------------------------------------------------------------

  @override
  Future<void> addWatchedItem(WatchedItemModel item) async {
    final existingIndex = _items.indexWhere(
      (existing) =>
          existing.mediaId == item.mediaId &&
          existing.mediaType == item.mediaType,
    );

    if (existingIndex != -1) {
      _items[existingIndex] = item;
    } else {
      _items.add(item);
    }
  }

  @override
  Future<void> removeWatchedItem(String id) async {
    _items.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> updateWatchedItem(WatchedItemModel item) async {
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index == -1) {
      throw Exception('Item não encontrado para atualização: ${item.id}');
    }

    _items[index] = item;
  }
}
