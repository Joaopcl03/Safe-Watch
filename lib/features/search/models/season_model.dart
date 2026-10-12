import 'package:safe_watch/features/search/models/episode_model.dart';

// ============================================================================
// Safe Watch — Season Model
// ============================================================================
// Modelo de dados para temporadas de séries.
// Fluxo: Template → Controller → Repository → TMDB API → SeasonModel
// ============================================================================

/// Modelo de dados de uma temporada de série.
///
/// Contém metadados da temporada e lista de episódios.
class SeasonModel {
  const SeasonModel({
    required this.id,
    required this.seasonNumber,
    required this.episodeCount,
    required this.name,
    this.overview = '',
    this.posterPath = '',
    this.airDate = '',
    this.episodes = const [],
  });

  /// Cria [SeasonModel] a partir do JSON do TMDB.
  ///
  /// JSON da lista de temporadas em `/tv/{id}`:
  /// ```json
  /// {"id": 3572, "name": "Season 1", "season_number": 1, "episode_count": 7}
  /// ```
  factory SeasonModel.fromTmdbJson(Map<String, dynamic> json) {
    return SeasonModel(
      id: json['id'] as int,
      seasonNumber: json['season_number'] as int,
      episodeCount: json['episode_count'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: (json['poster_path'] ?? '') as String,
      airDate: (json['air_date'] ?? '') as String,
      episodes: (json['episodes'] as List<dynamic>?)
              ?.map((e) => EpisodeModel.fromTmdbJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Cria [SeasonModel] a partir do JSON do TheTVDB.
  factory SeasonModel.fromTvdbJson(Map<String, dynamic> json) {
    return SeasonModel(
      id: json['id'] as int,
      seasonNumber: json['number'] as int? ?? 0,
      episodeCount: 0, // TheTVDB não retorna count diretamente na lista
      name: 'Season ${json['number'] ?? 0}',
      posterPath: (json['image'] ?? '') as String,
    );
  }

  /// ID da temporada na API.
  final int id;

  /// Número da temporada (0 = specials).
  final int seasonNumber;

  /// Número total de episódios.
  final int episodeCount;

  /// Nome da temporada (ex: "Season 1").
  final String name;

  /// Sinopse da temporada.
  final String overview;

  /// Caminho do poster da temporada.
  final String posterPath;

  /// Data de estreia da temporada.
  final String airDate;

  /// Lista de episódios (populada ao buscar detalhes da temporada).
  final List<EpisodeModel> episodes;

  /// Ano de estreia extraído de [airDate].
  String get airYear {
    if (airDate.isEmpty || airDate.length < 4) return '';
    return airDate.substring(0, 4);
  }

  /// Cria cópia com valores alterados.
  SeasonModel copyWith({
    int? id,
    int? seasonNumber,
    int? episodeCount,
    String? name,
    String? overview,
    String? posterPath,
    String? airDate,
    List<EpisodeModel>? episodes,
  }) {
    return SeasonModel(
      id: id ?? this.id,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeCount: episodeCount ?? this.episodeCount,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      airDate: airDate ?? this.airDate,
      episodes: episodes ?? this.episodes,
    );
  }

  @override
  String toString() => 'SeasonModel(id: $id, season: $seasonNumber, episodes: $episodeCount)';
}
