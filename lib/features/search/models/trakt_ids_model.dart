// ============================================================================
// Safe Watch — Trakt IDs Model
// ============================================================================
// Modelo para cross-reference de IDs entre as 4 APIs integradas.
// Permite localizar o mesmo título em TMDB, Trakt, TheTVDB e IMDb.
// ============================================================================

/// Conjunto de IDs de um título em diferentes APIs.
///
/// Campos opcionais pois nem todo título terá ID em todas as bases.
/// Use [hasTrakt], [hasTmdb], etc. para verificar disponibilidade antes
/// de fazer chamadas nas respectivas APIs.
class TraktIds {
  const TraktIds({
    this.trakt,
    this.slug,
    this.tmdb,
    this.tvdb,
    this.imdb,
  });

  /// Cria [TraktIds] a partir do objeto `ids` retornado pela API Trakt.
  ///
  /// Estrutura esperada:
  /// ```json
  /// { "trakt": 1390, "slug": "breaking-bad", "tvdb": 81189, "imdb": "tt0903747", "tmdb": 1396 }
  /// ```
  factory TraktIds.fromTraktJson(Map<String, dynamic> json) {
    return TraktIds(
      trakt: json['trakt'] as int?,
      slug: json['slug'] as String?,
      tmdb: json['tmdb'] as int?,
      tvdb: json['tvdb'] as int?,
      imdb: json['imdb'] as String?,
    );
  }

  /// Cria [TraktIds] a partir do objeto `external_ids` retornado pelo TMDB.
  ///
  /// Estrutura esperada:
  /// ```json
  /// { "imdb_id": "tt0903747", "tvdb_id": 81189 }
  /// ```
  factory TraktIds.fromTmdbExternalIds(Map<String, dynamic> json) {
    return TraktIds(
      imdb: (json['imdb_id'] ?? json['imdb']) as String?,
      tvdb: json['tvdb_id'] as int?,
      tmdb: json['id'] as int?,
    );
  }

  /// ID do título no Trakt.tv.
  final int? trakt;

  /// Slug do título no Trakt.tv (ex: "breaking-bad").
  /// Usado nas URLs da API Trakt como alternativa ao ID numérico.
  final String? slug;

  /// ID do título no TMDB.
  final int? tmdb;

  /// ID do título no TheTVDB.
  final int? tvdb;

  /// ID do título no IMDb (ex: "tt0903747").
  final String? imdb;

  /// Retorna true se o ID do Trakt está disponível.
  bool get hasTrakt => trakt != null;

  /// Retorna true se o ID do TMDB está disponível.
  bool get hasTmdb => tmdb != null;

  /// Retorna true se o ID do TheTVDB está disponível.
  bool get hasTvdb => tvdb != null;

  /// Retorna true se o ID do IMDb está disponível.
  bool get hasImdb => imdb != null && imdb!.isNotEmpty;

  /// Identificador preferencial para uso na API Trakt (slug ou ID numérico).
  String? get traktIdentifier => slug ?? trakt?.toString();

  /// Mescla dois [TraktIds], preenchendo campos nulos com os do outro.
  ///
  /// Útil para combinar IDs vindos de APIs diferentes no mesmo modelo.
  TraktIds merge(TraktIds other) {
    return TraktIds(
      trakt: trakt ?? other.trakt,
      slug: slug ?? other.slug,
      tmdb: tmdb ?? other.tmdb,
      tvdb: tvdb ?? other.tvdb,
      imdb: imdb ?? other.imdb,
    );
  }

  /// Converte para mapa JSON (estrutura Trakt).
  Map<String, dynamic> toJson() => {
        if (trakt != null) 'trakt': trakt,
        if (slug != null) 'slug': slug,
        if (tmdb != null) 'tmdb': tmdb,
        if (tvdb != null) 'tvdb': tvdb,
        if (imdb != null) 'imdb': imdb,
      };

  @override
  String toString() =>
      'TraktIds(trakt: $trakt, slug: $slug, tmdb: $tmdb, tvdb: $tvdb, imdb: $imdb)';
}
