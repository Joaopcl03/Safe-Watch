import 'package:safe_watch/features/search/models/season_model.dart';
import 'package:safe_watch/features/search/models/trakt_ids_model.dart';

// ============================================================================
// Safe Watch — Media Model
// ============================================================================
// Modelo de dados para séries e filmes.
// Suporta dados do TMDB, TheTVDB e Trakt via IDs cruzados.
// Fluxo: SearchTemplate → SearchController → SearchRepository → MediaModel
// ============================================================================

/// Tipo de mídia: filme ou série de TV.
enum MediaType {
  /// Filme.
  movie,

  /// Série de TV.
  tv,
}

/// Modelo de dados de uma mídia (filme ou série).
///
/// Representa dados consolidados de múltiplas APIs.
/// Imutável por design — crie novas instâncias ao invés de modificar.
///
/// IDs cruzados permitem identificar a mesma mídia em:
/// - TMDB (catálogo, imagens, busca)
/// - Trakt (tracking, histórico)
/// - TheTVDB (metadados detalhados, season orders)
/// - IMDB (referência universal)
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
    this.numberOfSeasons = 0,
    this.numberOfEpisodes = 0,
    this.status = '',
    this.externalIds,
    this.seasons = const [],
  });

  /// Cria um [MediaModel] a partir do JSON de busca do TMDB.
  ///
  /// Compatível com `/search/tv`, `/search/movie` e `/search/multi`.
  factory MediaModel.fromTmdbJson(Map<String, dynamic> json, {MediaType? forceType}) {
    final type = forceType ?? (json['media_type'] == 'tv' ? MediaType.tv : MediaType.movie);
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
    );
  }

  /// Cria um [MediaModel] a partir do JSON de detalhes do TMDB.
  ///
  /// Compatível com `/tv/{id}` e `/movie/{id}` (com append_to_response).
  factory MediaModel.fromTmdbDetailsJson(Map<String, dynamic> json, {required MediaType type}) {
    // Extrair external_ids se disponível.
    TraktIds? externalIds;
    if (json.containsKey('external_ids')) {
      externalIds = TraktIds.fromTmdbExternalIds(
        json['external_ids'] as Map<String, dynamic>,
        tmdbId: json['id'] as int,
      );
    }

    // Extrair temporadas se disponível.
    final seasons = (json['seasons'] as List<dynamic>?)
            ?.map((s) => SeasonModel.fromTmdbJson(s as Map<String, dynamic>))
            .toList() ??
        const [];

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
      numberOfSeasons: json['number_of_seasons'] as int? ?? 0,
      numberOfEpisodes: json['number_of_episodes'] as int? ?? 0,
      status: (json['status'] ?? '') as String,
      externalIds: externalIds,
      seasons: seasons,
    );
  }

  /// Cria um [MediaModel] a partir do JSON de busca do TheTVDB.
  factory MediaModel.fromTvdbJson(Map<String, dynamic> json) {
    return MediaModel(
      id: int.tryParse(json['tvdb_id']?.toString() ?? '') ?? 0,
      title: (json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: (json['thumbnail'] ?? '') as String,
      releaseDate: (json['year'] ?? '') as String,
      mediaType: json['type'] == 'movie' ? MediaType.movie : MediaType.tv,
      voteAverage: 0.0,
    );
  }

  /// ID da mídia na API primária (TMDB por padrão).
  final int id;

  /// Título da mídia.
  final String title;

  /// Sinopse / descrição.
  final String overview;

  /// Caminho do poster (relativo ao TMDB image base URL).
  final String posterPath;

  /// Caminho do backdrop (relativo ao TMDB image base URL).
  final String backdropPath;

  /// Data de lançamento (formato ISO: "2024-01-01").
  final String releaseDate;

  /// Tipo de mídia: filme ou série.
  final MediaType mediaType;

  /// Nota média dos usuários (0.0 a 10.0).
  final double voteAverage;

  /// Número de temporadas (apenas para séries).
  final int numberOfSeasons;

  /// Número total de episódios (apenas para séries).
  final int numberOfEpisodes;

  /// Status da série (ex: "Returning Series", "Ended", "In Production").
  final String status;

  /// IDs cruzados para outras APIs (Trakt, TheTVDB, IMDB).
  final TraktIds? externalIds;

  /// Lista de temporadas (populada nos detalhes).
  final List<SeasonModel> seasons;

  /// URL completa do poster na resolução w500.
  String get fullPosterUrl {
    if (posterPath.isEmpty) return '';
    // TheTVDB retorna URL completa, TMDB retorna path relativo.
    if (posterPath.startsWith('http')) return posterPath;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  /// URL completa do backdrop.
  String get fullBackdropUrl {
    if (backdropPath.isEmpty) return '';
    if (backdropPath.startsWith('http')) return backdropPath;
    return 'https://image.tmdb.org/t/p/w780$backdropPath';
  }

  /// Ano de lançamento extraído de [releaseDate].
  String get releaseYear {
    if (releaseDate.isEmpty || releaseDate.length < 4) return '';
    return releaseDate.substring(0, 4);
  }

  /// Se é uma série de TV.
  bool get isTvShow => mediaType == MediaType.tv;

  /// Converte o modelo para mapa JSON compatível com TMDB.
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
      'status': status,
      if (externalIds != null) 'external_ids': externalIds!.toJson(),
    };
  }

  /// Cria cópia com valores alterados.
  MediaModel copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    String? releaseDate,
    MediaType? mediaType,
    double? voteAverage,
    int? numberOfSeasons,
    int? numberOfEpisodes,
    String? status,
    TraktIds? externalIds,
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
      numberOfSeasons: numberOfSeasons ?? this.numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes ?? this.numberOfEpisodes,
      status: status ?? this.status,
      externalIds: externalIds ?? this.externalIds,
      seasons: seasons ?? this.seasons,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaModel && other.id == id && other.mediaType == mediaType;
  }

  @override
  int get hashCode => id.hashCode ^ mediaType.hashCode;

  @override
  String toString() => 'MediaModel(id: $id, title: $title, type: $mediaType)';
}
