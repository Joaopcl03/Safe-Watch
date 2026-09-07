// ============================================================================
// Safe Watch — Streaming Source Model
// ============================================================================
// Modelo de dados para fontes de streaming de um título.
// Representa um provider (Netflix, Prime, etc.) em uma região específica.
// ============================================================================

/// Tipo de acesso ao conteúdo em uma plataforma de streaming.
enum StreamingType {
  /// Incluído na assinatura (ex: Netflix, Prime com assinatura).
  subscription,

  /// Acesso gratuito com anúncios (ex: Pluto TV, Tubi).
  free,

  /// Aluguel (ex: YouTube, Apple TV).
  rent,

  /// Compra permanente (ex: Google Play, Apple TV).
  buy,

  /// Tipo não reconhecido.
  unknown,
}

/// Modelo de dados para uma fonte de streaming disponível.
///
/// Pode ser construído a partir de dados do Watchmode ou do TMDB
/// (JustWatch via `/watch/providers`).
class StreamingSourceModel {
  const StreamingSourceModel({
    required this.sourceId,
    required this.name,
    required this.type,
    required this.region,
    required this.webUrl,
    this.androidUrl = '',
    this.iosUrl = '',
    this.logo = '',
    this.format,
    this.price,
  });

  /// Cria um [StreamingSourceModel] a partir do JSON do Watchmode.
  ///
  /// Estrutura esperada:
  /// ```json
  /// {
  ///   "source_id": 203, "name": "Netflix", "type": "sub",
  ///   "region": "BR", "web_url": "https://...",
  ///   "ios_url": "...", "android_url": "...",
  ///   "format": "HD", "price": null
  /// }
  /// ```
  factory StreamingSourceModel.fromWatchmodeJson(Map<String, dynamic> json) {
    return StreamingSourceModel(
      sourceId: json['source_id'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      type: _parseType(json['type'] as String?),
      region: (json['region'] ?? '') as String,
      webUrl: (json['web_url'] ?? '') as String,
      androidUrl: (json['android_url'] ?? '') as String,
      iosUrl: (json['ios_url'] ?? '') as String,
      format: json['format'] as String?,
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  /// Cria um [StreamingSourceModel] a partir do JSON do TMDB (JustWatch).
  ///
  /// O TMDB retorna providers agrupados por tipo: flatrate, free, rent, buy.
  /// [providerType] deve ser passado externamente (o tipo não está no objeto).
  factory StreamingSourceModel.fromTmdbProviderJson(
    Map<String, dynamic> json, {
    required StreamingType providerType,
    required String region,
  }) {
    return StreamingSourceModel(
      sourceId: json['provider_id'] as int? ?? 0,
      name: (json['provider_name'] ?? '') as String,
      type: providerType,
      region: region,
      webUrl: '',
      logo: (json['logo_path'] ?? '') as String,
    );
  }

  /// ID único da fonte no Watchmode ou TMDB.
  final int sourceId;

  /// Nome do serviço de streaming (ex: "Netflix", "Amazon Prime Video").
  final String name;

  /// Tipo de acesso (assinatura, gratuito, aluguel, compra).
  final StreamingType type;

  /// Código da região (ex: "BR", "US").
  final String region;

  /// URL web para acessar o título neste serviço.
  final String webUrl;

  /// URL deep link para Android.
  final String androidUrl;

  /// URL deep link para iOS.
  final String iosUrl;

  /// Caminho do logo do provider (URL parcial ou completa).
  final String logo;

  /// Formato disponível (ex: "HD", "4K"). Pode ser null.
  final String? format;

  /// Preço para aluguel ou compra. Null para assinatura/gratuito.
  final double? price;

  /// Retorna true se o conteúdo está incluído em assinatura.
  bool get isSubscription => type == StreamingType.subscription;

  /// Retorna true se o conteúdo é gratuito.
  bool get isFree => type == StreamingType.free;

  /// Retorna true se é necessário pagar (aluguel ou compra).
  bool get isPaid =>
      type == StreamingType.rent || type == StreamingType.buy;

  /// URL do logo completa (se for do TMDB, gera a URL completa).
  String get fullLogoUrl {
    if (logo.isEmpty) return '';
    if (logo.startsWith('http')) return logo;
    return 'https://image.tmdb.org/t/p/w92$logo';
  }

  /// Texto do tipo de acesso em português.
  String get typeLabel {
    switch (type) {
      case StreamingType.subscription:
        return 'Assinatura';
      case StreamingType.free:
        return 'Gratuito';
      case StreamingType.rent:
        return price != null
            ? 'Aluguel — R\$ ${price!.toStringAsFixed(2)}'
            : 'Aluguel';
      case StreamingType.buy:
        return price != null
            ? 'Compra — R\$ ${price!.toStringAsFixed(2)}'
            : 'Compra';
      case StreamingType.unknown:
        return 'Disponível';
    }
  }

  static StreamingType _parseType(String? type) {
    switch (type) {
      case 'sub':
      case 'subscription':
        return StreamingType.subscription;
      case 'free':
        return StreamingType.free;
      case 'rent':
        return StreamingType.rent;
      case 'buy':
        return StreamingType.buy;
      default:
        return StreamingType.unknown;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamingSourceModel &&
        other.sourceId == sourceId &&
        other.region == region &&
        other.type == type;
  }

  @override
  int get hashCode => sourceId.hashCode ^ region.hashCode ^ type.hashCode;

  @override
  String toString() =>
      'StreamingSourceModel(name: $name, type: $type, region: $region)';
}
