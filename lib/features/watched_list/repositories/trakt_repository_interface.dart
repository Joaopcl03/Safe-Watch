import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/watched_list/models/watched_item_model.dart';

// ============================================================================
// Safe Watch — Trakt Repository Interface
// ============================================================================
// Contrato abstrato para sincronização com Trakt.tv.
// Gerencia histórico de assistidos, watchlist e check-in.
// ============================================================================

/// Interface abstrata do repositório de sync com Trakt.tv.
///
/// Define o contrato para sincronização de histórico,
/// watchlist e check-in do usuário.
abstract interface class TraktRepositoryInterface {
  /// Sincroniza itens como assistidos no histórico do Trakt.
  Future<void> syncToHistory(List<WatchedItemModel> items);

  /// Remove itens do histórico do Trakt.
  Future<void> removeFromHistory(List<WatchedItemModel> items);

  /// Retorna o histórico de assistidos do Trakt.
  Future<List<Map<String, dynamic>>> getWatchHistory({
    int page = 1,
    int limit = 20,
  });

  /// Adiciona mídias à watchlist (quero assistir) do Trakt.
  Future<void> addToWatchlist(List<MediaModel> media);

  /// Remove mídias da watchlist do Trakt.
  Future<void> removeFromWatchlist(List<MediaModel> media);

  /// Retorna a watchlist do Trakt.
  Future<List<Map<String, dynamic>>> getWatchlist();

  /// Realiza check-in ("assistindo agora").
  Future<void> checkin({
    required int tmdbId,
    required MediaType mediaType,
    int? seasonNumber,
    int? episodeNumber,
  });

  /// Cancela check-in ativo.
  Future<void> cancelCheckin();

  /// Retorna progresso de uma série no Trakt.
  Future<Map<String, dynamic>> getShowProgress(String showId);
}
