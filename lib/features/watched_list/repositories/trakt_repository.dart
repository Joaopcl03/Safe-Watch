import 'package:safe_watch/core/api/clients/trakt_client.dart';
import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/watched_list/models/watched_item_model.dart';
import 'package:safe_watch/features/watched_list/repositories/trakt_repository_interface.dart';

// ============================================================================
// Safe Watch — Trakt Repository
// ============================================================================
// Implementação do repositório de sync com Trakt.tv.
// Usa TraktClient para comunicação com a API.
//
// Fluxo de dados:
//   WatchedListController → TraktRepository → TraktClient → Trakt API
//
// IDs cruzados: usa TMDB IDs para identificar mídia no Trakt,
// eliminando a necessidade de lookup prévio.
// ============================================================================

/// Implementação do [TraktRepositoryInterface] usando [TraktClient].
///
/// Sincroniza histórico e watchlist do usuário com o Trakt.tv.
/// Usa TMDB IDs para cross-reference (Trakt aceita IDs de múltiplas fontes).
class TraktRepository implements TraktRepositoryInterface {
  TraktRepository({required TraktClient traktClient})
      : _traktClient = traktClient;

  final TraktClient _traktClient;

  @override
  Future<void> syncToHistory(List<WatchedItemModel> items) async {
    if (items.isEmpty) return;

    // Agrupa por tipo (show vs movie) para o payload do Trakt.
    final shows = <Map<String, dynamic>>[];
    final movies = <Map<String, dynamic>>[];

    for (final item in items) {
      final watchedAt = item.watchedAt?.toUtc().toIso8601String() ??
          DateTime.now().toUtc().toIso8601String();

      if (item.mediaType == MediaType.tv) {
        shows.add({
          'ids': {'tmdb': item.mediaId},
          'seasons': [
            if (item.seasonProgress > 0)
              {
                'number': item.seasonProgress,
                'episodes': [
                  if (item.episodeProgress > 0)
                    {
                      'number': item.episodeProgress,
                      'watched_at': watchedAt,
                    },
                ],
              },
          ],
        });
      } else {
        movies.add({
          'ids': {'tmdb': item.mediaId},
          'watched_at': watchedAt,
        });
      }
    }

    await _traktClient.syncHistory({
      if (shows.isNotEmpty) 'shows': shows,
      if (movies.isNotEmpty) 'movies': movies,
    });
  }

  @override
  Future<void> removeFromHistory(List<WatchedItemModel> items) async {
    if (items.isEmpty) return;

    final shows = <Map<String, dynamic>>[];
    final movies = <Map<String, dynamic>>[];

    for (final item in items) {
      final entry = {
        'ids': {'tmdb': item.mediaId},
      };
      if (item.mediaType == MediaType.tv) {
        shows.add(entry);
      } else {
        movies.add(entry);
      }
    }

    await _traktClient.removeFromHistory({
      if (shows.isNotEmpty) 'shows': shows,
      if (movies.isNotEmpty) 'movies': movies,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getWatchHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _traktClient.getHistory(
      page: page,
      limit: limit,
    );
    return response.cast<Map<String, dynamic>>();
  }

  @override
  Future<void> addToWatchlist(List<MediaModel> media) async {
    if (media.isEmpty) return;

    final shows = <Map<String, dynamic>>[];
    final movies = <Map<String, dynamic>>[];

    for (final item in media) {
      final entry = {
        'title': item.title,
        'ids': {'tmdb': item.id},
      };
      if (item.mediaType == MediaType.tv) {
        shows.add(entry);
      } else {
        movies.add(entry);
      }
    }

    await _traktClient.addToWatchlist({
      if (shows.isNotEmpty) 'shows': shows,
      if (movies.isNotEmpty) 'movies': movies,
    });
  }

  @override
  Future<void> removeFromWatchlist(List<MediaModel> media) async {
    if (media.isEmpty) return;

    final shows = <Map<String, dynamic>>[];
    final movies = <Map<String, dynamic>>[];

    for (final item in media) {
      final entry = {
        'ids': {'tmdb': item.id},
      };
      if (item.mediaType == MediaType.tv) {
        shows.add(entry);
      } else {
        movies.add(entry);
      }
    }

    await _traktClient.removeFromWatchlist({
      if (shows.isNotEmpty) 'shows': shows,
      if (movies.isNotEmpty) 'movies': movies,
    });
  }

  @override
  Future<void> checkin({
    required int tmdbId,
    required MediaType mediaType,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    final data = <String, dynamic>{};

    if (mediaType == MediaType.tv && seasonNumber != null && episodeNumber != null) {
      data['show'] = {
        'ids': {'tmdb': tmdbId},
      };
      data['episode'] = {
        'season': seasonNumber,
        'number': episodeNumber,
      };
    } else {
      data['movie'] = {
        'ids': {'tmdb': tmdbId},
      };
    }

    await _traktClient.checkin(data);
  }

  @override
  Future<void> cancelCheckin() async {
    await _traktClient.cancelCheckin();
  }

  @override
  Future<Map<String, dynamic>> getShowProgress(String showId) async {
    return _traktClient.getShowProgress(showId);
  }

  @override
  Future<List<Map<String, dynamic>>> getWatchlist() async {
    final response = await _traktClient.getWatchlist();
    return response.cast<Map<String, dynamic>>();
  }
}
