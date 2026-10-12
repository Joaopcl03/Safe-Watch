// ============================================================================
// Safe Watch — Episode Model
// ============================================================================
// Modelo de dados para episódios individuais.
// Fluxo: Template → Controller → Repository → TMDB API → EpisodeModel
// ============================================================================

/// Modelo de dados de um episódio.
///
/// Contém metadados do episódio como título, sinopse, duração e nota.
class EpisodeModel {
  const EpisodeModel({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.name,
    this.overview = '',
    this.stillPath = '',
    this.airDate = '',
    this.runtime = 0,
    this.voteAverage = 0.0,
    this.voteCount = 0,
  });

  /// Cria [EpisodeModel] a partir do JSON do TMDB.
  ///
  /// JSON do endpoint `/tv/{id}/season/{num}`:
  /// ```json
  /// {
  ///   "id": 62085, "episode_number": 1, "season_number": 1,
  ///   "name": "Pilot", "runtime": 58, "still_path": "/ydlY3i..."
  /// }
  /// ```
  factory EpisodeModel.fromTmdbJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'] as int,
      episodeNumber: json['episode_number'] as int,
      seasonNumber: json['season_number'] as int,
      name: (json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      stillPath: (json['still_path'] ?? '') as String,
      airDate: (json['air_date'] ?? '') as String,
      runtime: json['runtime'] as int? ?? 0,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
    );
  }

  /// Cria [EpisodeModel] a partir do JSON do TheTVDB.
  factory EpisodeModel.fromTvdbJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'] as int,
      episodeNumber: json['number'] as int? ?? 0,
      seasonNumber: json['seasonNumber'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      stillPath: (json['image'] ?? '') as String,
      airDate: (json['aired'] ?? '') as String,
      runtime: json['runtime'] as int? ?? 0,
    );
  }

  /// ID do episódio na API.
  final int id;

  /// Número do episódio na temporada.
  final int episodeNumber;

  /// Número da temporada.
  final int seasonNumber;

  /// Título do episódio.
  final String name;

  /// Sinopse do episódio.
  final String overview;

  /// Caminho da imagem still do episódio.
  final String stillPath;

  /// Data de exibição do episódio.
  final String airDate;

  /// Duração em minutos.
  final int runtime;

  /// Nota média dos usuários.
  final double voteAverage;

  /// Número de votos.
  final int voteCount;

  /// Código formatado do episódio (ex: "S01E05").
  String get episodeCode =>
      'S${seasonNumber.toString().padLeft(2, '0')}E${episodeNumber.toString().padLeft(2, '0')}';

  /// Duração formatada (ex: "58 min").
  String get runtimeFormatted => runtime > 0 ? '$runtime min' : '';

  @override
  String toString() => 'EpisodeModel(id: $id, $episodeCode: $name)';
}
