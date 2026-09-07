import 'package:safe_watch/core/api/clients/tmdb_client.dart';

// ============================================================================
// Safe Watch — Episode Model
// ============================================================================
// Modelo de dados para episódios de séries de TV.
// Fluxo: SearchRepository → SeasonModel → EpisodeModel
// ============================================================================

/// Modelo de dados para um episódio de série de TV.
///
/// Imutável por design — use [copyWith] para criar variantes.
class EpisodeModel {
  const EpisodeModel({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.name,
    required this.overview,
    required this.stillPath,
    required this.airDate,
    required this.runtime,
    required this.voteAverage,
  });

  /// Cria um [EpisodeModel] a partir do JSON do TMDB.
  ///
  /// Compatível com os endpoints:
  /// - GET /tv/{id}/season/{n} (campo `episodes[]`)
  /// - GET /tv/{id}/season/{n}/episode/{n}
  factory EpisodeModel.fromTmdbJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'] as int? ?? 0,
      episodeNumber: json['episode_number'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      stillPath: (json['still_path'] ?? '') as String,
      airDate: (json['air_date'] ?? '') as String,
      runtime: json['runtime'] as int? ?? 0,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Cria um [EpisodeModel] a partir do JSON do TheTVDB.
  factory EpisodeModel.fromTvdbJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'] as int? ?? 0,
      episodeNumber: json['number'] as int? ?? 0,
      seasonNumber: json['seasonNumber'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      stillPath: (json['image'] ?? '') as String,
      airDate: (json['aired'] ?? '') as String,
      runtime: json['runtime'] as int? ?? 0,
      voteAverage: 0.0, // TheTVDB não retorna rating por episódio.
    );
  }

  /// ID único do episódio na API.
  final int id;

  /// Número do episódio dentro da temporada (começa em 1).
  final int episodeNumber;

  /// Número da temporada a que pertence.
  final int seasonNumber;

  /// Título do episódio.
  final String name;

  /// Sinopse do episódio.
  final String overview;

  /// Caminho do still (frame de capa do episódio).
  /// URL completa: [TmdbClient.stillUrl(stillPath)]
  final String stillPath;

  /// Data de exibição original (formato ISO: "2024-01-01").
  final String airDate;

  /// Duração em minutos.
  final int runtime;

  /// Nota média dos usuários (0.0 a 10.0).
  final double voteAverage;

  /// URL completa do still na resolução w300.
  String get fullStillUrl => TmdbClient.stillUrl(stillPath);

  /// Ano de exibição extraído de [airDate].
  String get airYear {
    if (airDate.isEmpty || airDate.length < 4) return '';
    return airDate.substring(0, 4);
  }

  /// Identificador de exibição do episódio (ex: "S01E03").
  String get code =>
      'S${seasonNumber.toString().padLeft(2, '0')}'
      'E${episodeNumber.toString().padLeft(2, '0')}';

  /// Texto de duração formatado (ex: "45 min").
  String get runtimeText => runtime > 0 ? '$runtime min' : '';

  /// Converte para o formato de body esperado pelo Trakt /sync/history.
  Map<String, dynamic> toTraktHistoryBody({
    DateTime? watchedAt,
    int? traktId,
  }) {
    return {
      'episodes': [
        {
          if (traktId != null) 'ids': {'trakt': traktId},
          'watched_at': (watchedAt ?? DateTime.now()).toUtc().toIso8601String(),
        },
      ],
    };
  }

  /// Cria uma cópia com valores alterados.
  EpisodeModel copyWith({
    int? id,
    int? episodeNumber,
    int? seasonNumber,
    String? name,
    String? overview,
    String? stillPath,
    String? airDate,
    int? runtime,
    double? voteAverage,
  }) {
    return EpisodeModel(
      id: id ?? this.id,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      stillPath: stillPath ?? this.stillPath,
      airDate: airDate ?? this.airDate,
      runtime: runtime ?? this.runtime,
      voteAverage: voteAverage ?? this.voteAverage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpisodeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'EpisodeModel($code, name: $name, id: $id)';
}
