import 'package:safe_watch/features/search/models/media_model.dart';

// ============================================================================
// Safe Watch — Watched Item Model
// ============================================================================
// Modelo de dados para itens na lista de assistidos/quero assistir.
// Fluxo: WatchedListTemplate → WatchedListController → WatchedListRepository → WatchedItemModel
// ============================================================================

/// Status de um item na lista do usuário.
enum WatchedStatus {
  /// Item marcado como já assistido.
  watched,

  /// Item marcado como "quero assistir".
  wantToWatch,
}

/// Modelo de dados para um item na lista de assistidos.
///
/// Contém referência à mídia original ([mediaId]) e informações
/// de progresso (temporadas/episódios para séries).
///
/// Campos:
/// - [id]: ID único do item na lista local.
/// - [mediaId]: ID da mídia na API (ex: TMDB ID).
/// - [title]: Título da mídia.
/// - [posterPath]: Caminho do poster.
/// - [mediaType]: Tipo (filme/série).
/// - [status]: Status do item (assistido/quero assistir).
/// - [watchedAt]: Data em que foi marcado como assistido.
/// - [seasonProgress]: Temporada atual (para séries).
/// - [episodeProgress]: Episódio atual (para séries).
/// - [totalSeasons]: Total de temporadas (para séries).
/// - [voteAverage]: Nota média da mídia.
class WatchedItemModel {
  const WatchedItemModel({
    required this.id,
    required this.mediaId,
    required this.title,
    required this.posterPath,
    required this.mediaType,
    required this.status,
    this.watchedAt,
    this.seasonProgress = 0,
    this.episodeProgress = 0,
    this.totalSeasons = 0,
    this.voteAverage = 0.0,
  });

  /// Cria um [WatchedItemModel] a partir de um [MediaModel].
  ///
  /// Útil para adicionar um resultado de busca à lista de assistidos.
  /// O [status] padrão é [WatchedStatus.wantToWatch].
  factory WatchedItemModel.fromMedia(
    MediaModel media, {
    WatchedStatus status = WatchedStatus.wantToWatch,
  }) {
    return WatchedItemModel(
      id: 'watched-${media.id}-${media.mediaType.name}',
      mediaId: media.id,
      title: media.title,
      posterPath: media.posterPath,
      mediaType: media.mediaType,
      status: status,
      watchedAt: status == WatchedStatus.watched ? DateTime.now() : null,
      voteAverage: media.voteAverage,
    );
  }

  /// ID único do item na lista local.
  final String id;

  /// ID da mídia na API original (TMDB, etc.).
  final int mediaId;

  /// Título da mídia.
  final String title;

  /// Caminho do poster.
  final String posterPath;

  /// Tipo de mídia: filme ou série.
  final MediaType mediaType;

  /// Status: assistido ou quero assistir.
  final WatchedStatus status;

  /// Data em que foi marcado como assistido.
  final DateTime? watchedAt;

  /// Temporada atual no progresso (para séries).
  final int seasonProgress;

  /// Episódio atual no progresso (para séries).
  final int episodeProgress;

  /// Total de temporadas da série.
  final int totalSeasons;

  /// Nota média da mídia.
  final double voteAverage;

  /// URL completa do poster na resolução w500.
  String get fullPosterUrl {
    if (posterPath.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  /// Se o item é uma série de TV.
  bool get isTvShow => mediaType == MediaType.tv;

  /// Se o item já foi completamente assistido (para séries).
  bool get isCompleted =>
      status == WatchedStatus.watched &&
      (!isTvShow || (totalSeasons > 0 && seasonProgress >= totalSeasons));

  /// Texto de progresso formatado (para séries).
  /// Ex: "T2 E5" (Temporada 2, Episódio 5).
  String get progressText {
    if (!isTvShow) return '';
    if (seasonProgress == 0 && episodeProgress == 0) return 'Não iniciado';
    return 'T$seasonProgress E$episodeProgress';
  }

  /// Cria uma cópia com valores alterados.
  WatchedItemModel copyWith({
    String? id,
    int? mediaId,
    String? title,
    String? posterPath,
    MediaType? mediaType,
    WatchedStatus? status,
    DateTime? watchedAt,
    int? seasonProgress,
    int? episodeProgress,
    int? totalSeasons,
    double? voteAverage,
  }) {
    return WatchedItemModel(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      watchedAt: watchedAt ?? this.watchedAt,
      seasonProgress: seasonProgress ?? this.seasonProgress,
      episodeProgress: episodeProgress ?? this.episodeProgress,
      totalSeasons: totalSeasons ?? this.totalSeasons,
      voteAverage: voteAverage ?? this.voteAverage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WatchedItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WatchedItemModel(id: $id, title: $title, status: $status)';
}
