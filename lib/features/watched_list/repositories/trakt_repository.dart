import 'package:safe_watch/core/api/auth/trakt_auth_service.dart';
import 'package:safe_watch/core/api/clients/trakt_client.dart';
import 'package:safe_watch/features/search/models/episode_model.dart';
import 'package:safe_watch/features/search/models/media_model.dart';
import 'package:safe_watch/features/search/models/trakt_ids_model.dart';
import 'package:safe_watch/features/watched_list/models/watched_item_model.dart';
import 'package:safe_watch/features/watched_list/repositories/trakt_repository_interface.dart';

// ============================================================================
// Safe Watch — Trakt Repository
// ============================================================================
// Implementação real do TraktRepositoryInterface usando TraktClient.
//
// Verifica autenticação antes de cada operação — se não autenticado,
// as operações são no-ops silenciosos (a UI deve tratar o estado de auth).
// ============================================================================

/// Implementação real do repositório Trakt.tv.
///
/// Coordena [TraktClient] para operações de sync e [TraktAuthService]
/// para verificação de autenticação.
class TraktRepository implements TraktRepositoryInterface {
  TraktRepository({
    TraktClient? traktClient,
    TraktAuthService? authService,
  })  : _client = traktClient ?? TraktClient.instance,
        _auth = authService ?? TraktAuthService.instance;

  final TraktClient _client;
  final TraktAuthService _auth;

  @override
  Future<bool> get isAuthenticated => _auth.isAuthenticated;

  // --------------------------------------------------------------------------
  // Histórico
  // --------------------------------------------------------------------------

  @override
  Future<void> syncToHistory(List<WatchedItemModel> items) async {
    if (!await isAuthenticated) return;
    await _auth.getValidAccessToken();

    final episodes = <Map<String, dynamic>>[];
    final movies = <Map<String, dynamic>>[];

    for (final item in items) {
      final watchedAt = (item.watchedAt ?? DateTime.now())
          .toUtc()
          .toIso8601String();

      if (item.mediaType == MediaType.tv) {
        episodes.add({
          'ids': {'tmdb': item.mediaId},
          'watched_at': watchedAt,
        });
      } else {
        movies.add({
          'ids': {'tmdb': item.mediaId},
          'watched_at': watchedAt,
        });
      }
    }

    final body = <String, dynamic>{};
    if (episodes.isNotEmpty) body['episodes'] = episodes;
    if (movies.isNotEmpty) body['movies'] = movies;

    if (body.isEmpty) return;
    await _client.addToHistory(body);
  }

  @override
  Future<void> removeFromHistory(List<WatchedItemModel> items) async {
    if (!await isAuthenticated) return;
    await _auth.getValidAccessToken();

    final episodes = <Map<String, dynamic>>[];
    final movies = <Map<String, dynamic>>[];

    for (final item in items) {
      if (item.mediaType == MediaType.tv) {
        episodes.add({'ids': {'tmdb': item.mediaId}});
      } else {
        movies.add({'ids': {'tmdb': item.mediaId}});
      }
    }

    final body = <String, dynamic>{};
    if (episodes.isNotEmpty) body['episodes'] = episodes;
    if (movies.isNotEmpty) body['movies'] = movies;

    if (body.isEmpty) return;
    await _client.removeFromHistory(body);
  }

  @override
  Future<List<WatchedItemModel>> getWatchHistory({
    int page = 1,
    int limit = 20,
  }) async {
    if (!await isAuthenticated) return [];
    await _auth.getValidAccessToken();

    final history = await _client.getHistory(
      type: 'movies',
      page: page,
      limit: limit,
    );

    return history
        .cast<Map<String, dynamic>>()
        .map(_watchedItemFromTraktHistory)
        .whereType<WatchedItemModel>()
        .toList();
  }

  // --------------------------------------------------------------------------
  // Watchlist
  // --------------------------------------------------------------------------

  @override
  Future<void> addToWatchlist(List<MediaModel> media) async {
    if (!await isAuthenticated) return;
    await _auth.getValidAccessToken();

    final shows = <Map<String, dynamic>>[];
    final movies = <Map<String, dynamic>>[];

    for (final m in media) {
      final entry = {'ids': {'tmdb': m.id}};
      if (m.isTvShow) {
        shows.add(entry);
      } else {
        movies.add(entry);
      }
    }

    final body = <String, dynamic>{};
    if (shows.isNotEmpty) body['shows'] = shows;
    if (movies.isNotEmpty) body['movies'] = movies;

    if (body.isEmpty) return;
    await _client.addToWatchlist(body);
  }

  @override
  Future<void> removeFromWatchlist(List<MediaModel> media) async {
    if (!await isAuthenticated) return;
    await _auth.getValidAccessToken();

    final shows = <Map<String, dynamic>>[];
    final movies = <Map<String, dynamic>>[];

    for (final m in media) {
      final entry = {'ids': {'tmdb': m.id}};
      if (m.isTvShow) {
        shows.add(entry);
      } else {
        movies.add(entry);
      }
    }

    final body = <String, dynamic>{};
    if (shows.isNotEmpty) body['shows'] = shows;
    if (movies.isNotEmpty) body['movies'] = movies;

    if (body.isEmpty) return;
    await _client.removeFromWatchlist(body);
  }

  @override
  Future<List<MediaModel>> getWatchlist() async {
    if (!await isAuthenticated) return [];
    await _auth.getValidAccessToken();

    final watchlist = await _client.getWatchlist(type: 'shows');

    return watchlist
        .cast<Map<String, dynamic>>()
        .map(_mediaFromTraktWatchlist)
        .whereType<MediaModel>()
        .toList();
  }

  // --------------------------------------------------------------------------
  // Check-in
  // --------------------------------------------------------------------------

  @override
  Future<void> checkin(EpisodeModel episode, MediaModel show) async {
    if (!await isAuthenticated) return;
    await _auth.getValidAccessToken();

    final traktId = show.ids?.trakt;
    final slug = show.ids?.slug;

    await _client.checkin({
      'episode': {
        'season': episode.seasonNumber,
        'number': episode.episodeNumber,
      },
      'show': {
        'ids': {
          if (traktId != null) 'trakt': traktId,
          if (slug != null) 'slug': slug,
          'tmdb': show.id,
        },
      },
    });
  }

  @override
  Future<void> cancelCheckin() async {
    if (!await isAuthenticated) return;
    await _auth.getValidAccessToken();
    await _client.cancelCheckin();
  }

  // --------------------------------------------------------------------------
  // Progresso
  // --------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> getShowProgress(String traktId) async {
    if (!await isAuthenticated) return {};
    await _auth.getValidAccessToken();
    return _client.getShowProgress(traktId);
  }

  // --------------------------------------------------------------------------
  // Helpers de conversão
  // --------------------------------------------------------------------------

  WatchedItemModel? _watchedItemFromTraktHistory(Map<String, dynamic> json) {
    try {
      final type = json['type'] as String?;
      final isMovie = type == 'movie';
      final mediaJson = (isMovie ? json['movie'] : json['episode'])
          as Map<String, dynamic>?;
      if (mediaJson == null) return null;

      final ids = mediaJson['ids'] as Map<String, dynamic>? ?? {};
      final tmdbId = ids['tmdb'] as int?;
      if (tmdbId == null) return null;

      final watchedAt = json['watched_at'] as String?;
      final title = (mediaJson['title'] ?? '') as String;

      return WatchedItemModel(
        id: 'trakt-${isMovie ? 'movie' : 'episode'}-$tmdbId',
        mediaId: tmdbId,
        title: title,
        posterPath: '',
        mediaType: isMovie ? MediaType.movie : MediaType.tv,
        status: WatchedStatus.watched,
        watchedAt: watchedAt != null ? DateTime.tryParse(watchedAt) : null,
      );
    } catch (_) {
      return null;
    }
  }

  MediaModel? _mediaFromTraktWatchlist(Map<String, dynamic> json) {
    try {
      final type = json['type'] as String?;
      final isMovie = type == 'movie';
      final mediaJson = (isMovie ? json['movie'] : json['show'])
          as Map<String, dynamic>?;
      if (mediaJson == null) return null;

      final ids = mediaJson['ids'] as Map<String, dynamic>? ?? {};
      final tmdbId = ids['tmdb'] as int?;
      if (tmdbId == null) return null;

      final traktIds = TraktIds.fromTraktJson(ids);
      final title = (mediaJson['title'] ?? '') as String;
      final overview = (mediaJson['overview'] ?? '') as String;
      final year = mediaJson['year'] as int?;

      return MediaModel(
        id: tmdbId,
        title: title,
        overview: overview,
        posterPath: '',
        releaseDate: year != null ? '$year-01-01' : '',
        mediaType: isMovie ? MediaType.movie : MediaType.tv,
        voteAverage: (mediaJson['rating'] as num?)?.toDouble() ?? 0.0,
        ids: traktIds,
      );
    } catch (_) {
      return null;
    }
  }
}
