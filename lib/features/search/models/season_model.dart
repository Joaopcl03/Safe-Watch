import 'package:safe_watch/core/api/clients/tmdb_client.dart';
import 'package:safe_watch/features/search/models/episode_model.dart';

// ============================================================================
// Safe Watch — Season Model
// ============================================================================
// Modelo de dados para temporadas de séries de TV.
// Contém metadados da temporada e a lista de episódios.
// ============================================================================

/// Modelo de dados para uma temporada de série de TV.
///
/// Imutável por design — use [copyWith] para criar variantes.
class SeasonModel {
  const SeasonModel({
    required this.id,
    required this.seasonNumber,
    required this.episodeCount,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.airDate,
    this.episodes = const [],
  });

  /// Cria um [SeasonModel] a partir do JSON do TMDB.
  ///
  /// Compatível com o campo `seasons[]` de GET /tv/{id}
  /// e com o endpoint GET /tv/{id}/season/{n}.
  factory SeasonModel.fromTmdbJson(Map<String, dynamic> json) {
    final episodesJson =
        (json['episodes'] as List<dynamic>?) ?? [];

    return SeasonModel(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 0,
      episodeCount: json['episode_count'] as int? ?? episodesJson.length,
      name: (json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: (json['poster_path'] ?? '') as String,
      airDate: (json['air_date'] ?? '') as String,
      episodes: episodesJson
          .cast<Map<String, dynamic>>()
          .map(EpisodeModel.fromTmdbJson)
          .toList(),
    );
  }

  /// Cria um [SeasonModel] a partir do JSON do TheTVDB.
  factory SeasonModel.fromTvdbJson(Map<String, dynamic> json) {
    return SeasonModel(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['number'] as int? ?? 0,
      episodeCount: 0, // TheTVDB retorna episódios separadamente.
      name: (json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: (json['image'] ?? '') as String,
      airDate: '',
    );
  }

  /// ID único da temporada na API.
  final int id;

  /// Número da temporada (0 = especiais/extras).
  final int seasonNumber;

  /// Total de episódios na temporada.
  final int episodeCount;

  /// Título da temporada (ex: "Season 1", "Specials").
  final String name;

  /// Sinopse/descrição da temporada.
  final String overview;

  /// Caminho do poster da temporada.
  /// URL completa: [TmdbClient.posterUrl(posterPath)]
  final String posterPath;

  /// Data de estreia da temporada (formato ISO: "2024-01-01").
  final String airDate;

  /// Lista de episódios desta temporada.
  /// Preenchida quando os dados são carregados via [getSeasonDetails].
  final List<EpisodeModel> episodes;

  /// URL completa do poster na resolução w342.
  String get fullPosterUrl =>
      TmdbClient.posterUrl(posterPath, size: 'w342');

  /// Ano de estreia extraído de [airDate].
  String get airYear {
    if (airDate.isEmpty || airDate.length < 4) return '';
    return airDate.substring(0, 4);
  }

  /// Retorna true se a temporada é de especiais/extras (season 0).
  bool get isSpecials => seasonNumber == 0;

  /// Retorna true se a lista de episódios foi carregada.
  bool get hasEpisodes => episodes.isNotEmpty;

  /// Retorna o episódio pelo número, ou null se não encontrado.
  EpisodeModel? episodeByNumber(int number) {
    try {
      return episodes.firstWhere((e) => e.episodeNumber == number);
    } catch (_) {
      return null;
    }
  }

  /// Cria uma cópia com valores alterados.
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeasonModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SeasonModel(seasonNumber: $seasonNumber, episodeCount: $episodeCount, name: $name)';
}
