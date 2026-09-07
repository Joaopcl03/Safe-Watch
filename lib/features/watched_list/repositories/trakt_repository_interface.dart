import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/search/models/episode_model.dart';
import 'package:safe_watch/features/watched_list/models/watched_item_model.dart';

// ============================================================================
// Safe Watch — Trakt Repository Interface
// ============================================================================
// Contrato abstrato para sincronização de dados com o Trakt.tv.
// Permite trocar entre implementação real e mock em testes.
// ============================================================================

/// Interface abstrata do repositório Trakt.tv.
///
/// Gerencia histórico de assistidos, watchlist e check-ins
/// usando a API Trakt.tv como backend remoto.
abstract interface class TraktRepositoryInterface {
  // --------------------------------------------------------------------------
  // Histórico (Watched)
  // --------------------------------------------------------------------------

  /// Adiciona uma lista de itens ao histórico do Trakt.
  ///
  /// Deve ser chamado após marcar itens como assistidos localmente.
  Future<void> syncToHistory(List<WatchedItemModel> items);

  /// Remove uma lista de itens do histórico do Trakt.
  Future<void> removeFromHistory(List<WatchedItemModel> items);

  /// Retorna o histórico de assistidos do usuário no Trakt.
  ///
  /// [page] e [limit] para paginação.
  Future<List<WatchedItemModel>> getWatchHistory({
    int page = 1,
    int limit = 20,
  });

  // --------------------------------------------------------------------------
  // Watchlist (Quero Assistir)
  // --------------------------------------------------------------------------

  /// Adiciona mídias à watchlist do Trakt.
  Future<void> addToWatchlist(List<MediaModel> media);

  /// Remove mídias da watchlist do Trakt.
  Future<void> removeFromWatchlist(List<MediaModel> media);

  /// Retorna a watchlist do usuário no Trakt.
  Future<List<MediaModel>> getWatchlist();

  // --------------------------------------------------------------------------
  // Check-in
  // --------------------------------------------------------------------------

  /// Faz check-in em um episódio no Trakt ("assistindo agora").
  ///
  /// O check-in expira automaticamente após o runtime do episódio.
  /// [show] é necessário para fornecer o Trakt ID da série.
  Future<void> checkin(EpisodeModel episode, MediaModel show);

  /// Cancela o check-in ativo no Trakt.
  Future<void> cancelCheckin();

  // --------------------------------------------------------------------------
  // Progresso
  // --------------------------------------------------------------------------

  /// Retorna o progresso de assistido de uma série.
  ///
  /// [traktId] é o ID ou slug da série no Trakt.
  /// Retorna mapa com: aired, completed, last_episode, next_episode.
  Future<Map<String, dynamic>> getShowProgress(String traktId);

  // --------------------------------------------------------------------------
  // Sincronização
  // --------------------------------------------------------------------------

  /// Verifica se o usuário está autenticado no Trakt.
  Future<bool> get isAuthenticated;
}
