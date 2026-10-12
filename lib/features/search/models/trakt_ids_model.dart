// ============================================================================
// Safe Watch — Trakt IDs Model
// ============================================================================
// Cross-reference de IDs entre APIs (TMDB, Trakt, TheTVDB, IMDB).
// Usado para mapear a mesma mídia entre diferentes serviços.
// ============================================================================

/// Modelo para cross-reference de IDs entre APIs.
///
/// Permite identificar a mesma mídia em diferentes serviços:
/// - TMDB (catálogo visual)
/// - Trakt (tracking)
/// - TheTVDB (metadados detalhados)
/// - IMDB (referência universal)
class TraktIds {
  const TraktIds({
    this.trakt,
    this.tmdb,
    this.tvdb,
    this.imdb,
    this.slug,
  });

  /// Cria [TraktIds] a partir do JSON do Trakt.
  factory TraktIds.fromJson(Map<String, dynamic> json) {
    return TraktIds(
      trakt: json['trakt'] as int?,
      tmdb: json['tmdb'] as int?,
      tvdb: json['tvdb'] as int?,
      imdb: json['imdb'] as String?,
      slug: json['slug'] as String?,
    );
  }

  /// Cria [TraktIds] a partir do `external_ids` do TMDB.
  factory TraktIds.fromTmdbExternalIds(Map<String, dynamic> json, {int? tmdbId}) {
    return TraktIds(
      tmdb: tmdbId,
      tvdb: json['tvdb_id'] as int?,
      imdb: json['imdb_id'] as String?,
    );
  }

  /// ID no Trakt.
  final int? trakt;

  /// ID no TMDB.
  final int? tmdb;

  /// ID no TheTVDB.
  final int? tvdb;

  /// ID no IMDB (ex: "tt0903747").
  final String? imdb;

  /// Slug no Trakt (ex: "breaking-bad").
  final String? slug;

  /// Converte para mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      if (trakt != null) 'trakt': trakt,
      if (tmdb != null) 'tmdb': tmdb,
      if (tvdb != null) 'tvdb': tvdb,
      if (imdb != null) 'imdb': imdb,
      if (slug != null) 'slug': slug,
    };
  }

  @override
  String toString() => 'TraktIds(trakt: $trakt, tmdb: $tmdb, tvdb: $tvdb, imdb: $imdb)';
}
