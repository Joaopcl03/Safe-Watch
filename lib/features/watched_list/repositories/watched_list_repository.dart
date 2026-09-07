import 'package:safe_watch/features/watched_list/models/watched_item_model.dart';
import 'package:safe_watch/features/watched_list/repositories/trakt_repository.dart';
import 'package:safe_watch/features/watched_list/repositories/trakt_repository_interface.dart';
import 'package:safe_watch/features/watched_list/repositories/watched_list_repository_interface.dart';

// ============================================================================
// Safe Watch — Watched List Repository
// ============================================================================
// Coordena armazenamento local (lista em memória) com sync remoto no Trakt.
//
// Estratégia:
//   - Leitura: retorna dados locais imediatamente (sem esperar Trakt)
//   - Escrita: persiste localmente primeiro, sync Trakt em background
//   - Fallback: se Trakt falhar, dados locais permanecem intactos
//
// TODO: Substituir lista em memória por Isar para persistência real:
//   - isar: ^4.0.0-dev.14
//   - isar_flutter_libs: ^4.0.0-dev.14
// ============================================================================

/// Implementação do repositório de lista de assistidos.
///
/// Combina armazenamento local (em memória) com sincronização remota
/// via [TraktRepositoryInterface]. O Trakt é acessado em fire-and-forget:
/// falhas não bloqueiam a experiência local.
class WatchedListRepository implements WatchedListRepositoryInterface {
  WatchedListRepository({TraktRepositoryInterface? traktRepository})
      : _trakt = traktRepository ?? TraktRepository();

  final TraktRepositoryInterface _trakt;

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

    // Sync Trakt em background (fire-and-forget).
    _syncAddToTrakt(item);
  }

  @override
  Future<void> removeWatchedItem(String id) async {
    final item = _items.firstWhere(
      (i) => i.id == id,
      orElse: () => throw Exception('Item não encontrado: $id'),
    );

    _items.removeWhere((i) => i.id == id);

    // Sync Trakt em background.
    _syncRemoveFromTrakt(item);
  }

  @override
  Future<void> updateWatchedItem(WatchedItemModel item) async {
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index == -1) {
      throw Exception('Item não encontrado para atualização: ${item.id}');
    }

    _items[index] = item;

    // Se foi marcado como assistido, sincroniza com Trakt.
    if (item.status == WatchedStatus.watched) {
      _syncAddToTrakt(item);
    }
  }

  // --------------------------------------------------------------------------
  // Sync Trakt (fire-and-forget)
  // --------------------------------------------------------------------------

  /// Sincroniza um item adicionado com o Trakt em background.
  /// Erros são silenciados para não impactar a experiência local.
  void _syncAddToTrakt(WatchedItemModel item) {
    if (item.status != WatchedStatus.watched) return;

    _trakt.syncToHistory([item]).catchError((_) {
      // Sync falhou — dados locais permanecem. Será sincronizado
      // na próxima vez que o usuário abrir o app (TODO: retry queue).
    });
  }

  /// Sincroniza remoção de item com o Trakt em background.
  void _syncRemoveFromTrakt(WatchedItemModel item) {
    _trakt.removeFromHistory([item]).catchError((_) {
      // Silencia erros de sync remoto.
    });
  }
}
