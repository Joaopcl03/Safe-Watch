import 'package:safe_watch/core/api/clients/tmdb_client.dart';
import 'package:safe_watch/features/search/models/season_model.dart';
import 'package:safe_watch/features/search/models/trakt_ids_model.dart';

// ============================================================================
// Safe Watch — Media Model
// ============================================================================
// Modelo de dados para séries e filmes vindos da API (ex: TMDB).
// Fluxo: SearchTemplate → SearchController → SearchRepository → MediaModel
// ============================================================================

/// Tipo de mídia: filme ou série de TV.
enum MediaType {
  /// Filme.
  movie,

  /// Série de TV.
  tv,
}

/// Status de produção de uma série ou filme.
enum MediaStatus {
  /// Em exibição / retornando para nova temporada.
  returning,

  /// Encerrado.
  ended,

  /// Em produção (ainda não estreou).
  inProduction,

  /// Cancelado.
  canceled,

  /// Piloto.
  pilot,

  /// Status desconhecido.
  unknown,
}

/// Modelo de dados de uma mídia (filme ou série).
///
/// Representa os dados completos retornados pelas APIs de busca e detalhes.
/// Imutável por design — crie novas instâncias ao invés de modificar.
///
/// Campos básicos (busca):
/// - [id]: ID TMDB da mídia.
/// - [title]: Título da mídia.
/// - [overview]: Sinopse.
/// - [posterPath]: Caminho do poster.
/// - [backdropPath]: Caminho do backdrop (imagem de fundo).
/// - [releaseDate]: Data de lançamento.
/// - [mediaType]: Tipo ([MediaType.movie] ou [MediaType.tv]).
/// - [voteAverage]: Nota média (0.0–10.0).
///
/// Campos de cross-reference (detalhes):
/// - [ids]: IDs nas diferentes APIs ([TraktIds]).
/// - [numberOfSeasons]: Total de temporadas (séries).
/// - [numberOfEpisodes]: Total de episódios (séries).
/// - [status]: Status de produção.
/// - [seasons]: Lista de temporadas com detalhes.
class MediaModel {
  const MediaModel({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.releaseDate,
    required this.mediaType,
    required this.voteAverage,
    this.backdropPath = '',
    this.ids,
    this.numberOfSeasons = 0,
    this.numberOfEpisodes = 0,
    this.status = MediaStatus.unknown,
    this.genres = const [],
    this.seasons = const [],
    this.originalLanguage = '',
    this.popularity = 0.0,
  });

  // --------------------------------------------------------------------------
  // Factories
  // --------------------------------------------------------------------------

  /// Cria um [MediaModel] a partir de um resultado de busca do TMDB.
  ///
  /// Compatível com `/search/multi`, `/search/tv` e `/search/movie`.
  /// Para resultados de `/search/tv` e `/search/movie`, passe [forceType].
  factory MediaModel.fromTmdbSearchJson(
    Map<String, dynamic> json, {
    MediaType? forceType,
  }) {
    final typeStr = json['media_type'] as String?;
    final type = forceType ??
        (typeStr == 'tv' ? MediaType.tv : MediaType.movie);

    return MediaModel(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: (json['poster_path'] ?? '') as String,
      backdropPath: (json['backdrop_path'] ?? '') as String,
      releaseDate:
          (json['release_date'] ?? json['first_air_date'] ?? '') as String,
      mediaType: type,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      originalLanguage: (json['original_language'] ?? '') as String,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Cria um [MediaModel] a partir dos detalhes completos do TMDB.
  ///
  /// Compatível com `/tv/{id}?append_to_response=external_ids`
  /// e `/movie/{id}?append_to_response=external_ids`.
  factory MediaModel.fromTmdbDetailsJson(
    Map<String, dynamic> json,
    MediaType mediaType,
  ) {
    // Extrai IDs externos se disponíveis (append_to_response=external_ids).
    final externalIds =
        json['external_ids'] as Map<String, dynamic>? ?? {};

    final ids = TraktIds(
      tmdb: json['id'] as int?,
      imdb: (externalIds['imdb_id'] ?? externalIds['imdb']) as String?,
      tvdb: externalIds['tvdb_id'] as int?,
    );

    // Extrai temporadas (séries).
    final seasonsJson =
        (json['seasons'] as List<dynamic>?) ?? [];
    final seasons = seasonsJson
        .cast<Map<String, dynamic>>()
        .map(SeasonModel.fromTmdbJson)
        .toList();

    // Extrai gêneros.
    final genresJson = (json['genres'] as List<dynamic>?) ?? [];
    final genres = genresJson
        .cast<Map<String, dynamic>>()
        .map((g) => (g['name'] ?? '') as String)
        .where((g) => g.isNotEmpty)
        .toList();

    return MediaModel(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: (json['poster_path'] ?? '') as String,
      backdropPath: (json['backdrop_path'] ?? '') as String,
      releaseDate:
          (json['release_date'] ?? json['first_air_date'] ?? '') as String,
      mediaType: mediaType,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      ids: ids,
      numberOfSeasons: json['number_of_seasons'] as int? ?? 0,
      numberOfEpisodes: json['number_of_episodes'] as int? ?? 0,
      status: _parseStatus(json['status'] as String?),
      genres: genres,
      seasons: seasons,
      originalLanguage: (json['original_language'] ?? '') as String,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Cria um [MediaModel] a partir do JSON do TheTVDB.
  factory MediaModel.fromTvdbJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] as int? ?? 0,
      title: (json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: (json['image'] ?? '') as String,
      releaseDate: (json['firstAired'] ?? '') as String,
      mediaType: MediaType.tv,
      voteAverage: (json['score'] as num?)?.toDouble() ?? 0.0,
      ids: TraktIds(tvdb: json['id'] as int?),
      status: _parseStatus(json['status']?['name'] as String?),
    );
  }

  /// Cria um [MediaModel] com IDs Trakt mesclados.
  ///
  /// Usado após fazer cross-reference na API Trakt para adicionar
  /// o `traktId` e `slug` ao modelo existente.
  MediaModel withTraktIds(TraktIds traktIds) {
    final merged = (ids ?? const TraktIds()).merge(traktIds);
    return copyWith(ids: merged);
  }

  // --------------------------------------------------------------------------
  // Campos básicos
  // --------------------------------------------------------------------------

  /// ID TMDB da mídia (chave principal).
  final int id;

  /// Título da mídia.
  final String title;

  /// Sinopse / descrição.
  final String overview;

  /// Caminho do poster (ex: "/abc123.jpg").
  final String posterPath;

  /// Caminho do backdrop/imagem de fundo.
  final String backdropPath;

  /// Data de lançamento (formato ISO: "2024-01-01").
  final String releaseDate;

  /// Tipo de mídia: filme ou série.
  final MediaType mediaType;

  /// Nota média dos usuários (0.0 a 10.0).
  final double voteAverage;

  /// Idioma original da produção (ex: "en", "pt").
  final String originalLanguage;

  /// Score de popularidade TMDB.
  final double popularity;

  // --------------------------------------------------------------------------
  // Campos de detalhe / cross-reference
  // --------------------------------------------------------------------------

  /// IDs nas diferentes APIs (Trakt, TMDB, TVDB, IMDb).
  final TraktIds? ids;

  /// Total de temporadas (séries de TV).
  final int numberOfSeasons;

  /// Total de episódios (séries de TV).
  final int numberOfEpisodes;

  /// Status de produção da série/filme.
  final MediaStatus status;

  /// Lista de gêneros.
  final List<String> genres;

  /// Lista de temporadas com metadados.
  /// Preenchida após chamada a [getSeasonDetails].
  final List<SeasonModel> seasons;

  // --------------------------------------------------------------------------
  // Getters computados
  // --------------------------------------------------------------------------

  /// URL completa do poster na resolução w500.
  String get fullPosterUrl => TmdbClient.posterUrl(posterPath);

  /// URL completa do backdrop na resolução w1280.
  String get fullBackdropUrl => TmdbClient.backdropUrl(backdropPath);

  /// Ano de lançamento extraído de [releaseDate].
  String get releaseYear {
    if (releaseDate.isEmpty || releaseDate.length < 4) return '';
    return releaseDate.substring(0, 4);
  }

  /// Se o item é uma série de TV.
  bool get isTvShow => mediaType == MediaType.tv;

  /// Gêneros formatados como string (ex: "Drama, Thriller").
  String get genresText => genres.join(', ');

  /// Retorna true se os detalhes completos foram carregados
  /// (tem IDs externos e temporadas).
  bool get hasFullDetails => ids != null;

  // --------------------------------------------------------------------------
  // Helpers de status
  // --------------------------------------------------------------------------

  static MediaStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'returning series':
      case 'continuing':
        return MediaStatus.returning;
      case 'ended':
        return MediaStatus.ended;
      case 'in production':
        return MediaStatus.inProduction;
      case 'canceled':
      case 'cancelled':
        return MediaStatus.canceled;
      case 'pilot':
        return MediaStatus.pilot;
      default:
        return MediaStatus.unknown;
    }
  }

  // --------------------------------------------------------------------------
  // Serialização (compatibilidade com código existente)
  // --------------------------------------------------------------------------

  /// Mantém compatibilidade com a factory original usada no mock.
  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel.fromTmdbSearchJson(json);
  }

  /// Converte o modelo para mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'release_date': releaseDate,
      'media_type': mediaType == MediaType.tv ? 'tv' : 'movie',
      'vote_average': voteAverage,
      'number_of_seasons': numberOfSeasons,
      'number_of_episodes': numberOfEpisodes,
    };
  }

  // --------------------------------------------------------------------------
  // copyWith
  // --------------------------------------------------------------------------

  /// Cria uma cópia com valores alterados.
  MediaModel copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    String? releaseDate,
    MediaType? mediaType,
    double? voteAverage,
    String? originalLanguage,
    double? popularity,
    TraktIds? ids,
    int? numberOfSeasons,
    int? numberOfEpisodes,
    MediaStatus? status,
    List<String>? genres,
    List<SeasonModel>? seasons,
  }) {
    return MediaModel(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      releaseDate: releaseDate ?? this.releaseDate,
      mediaType: mediaType ?? this.mediaType,
      voteAverage: voteAverage ?? this.voteAverage,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      popularity: popularity ?? this.popularity,
      ids: ids ?? this.ids,
      numberOfSeasons: numberOfSeasons ?? this.numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes ?? this.numberOfEpisodes,
      status: status ?? this.status,
      genres: genres ?? this.genres,
      seasons: seasons ?? this.seasons,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaModel &&
        other.id == id &&
        other.mediaType == mediaType;
  }

  @override
  int get hashCode => id.hashCode ^ mediaType.hashCode;

  @override
  String toString() =>
      'MediaModel(id: $id, title: $title, type: $mediaType)';
}
