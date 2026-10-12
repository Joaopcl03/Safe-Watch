// ============================================================================
// Safe Watch — Streaming Source Model
// ============================================================================
// Modelo de dados para fontes de streaming (onde assistir).
// Fluxo: Template → Controller → Repository → Watchmode API → StreamingSourceModel
// ============================================================================

/// Tipo de disponibilidade em streaming.
enum StreamingType {
  /// Assinatura (SVOD) — Netflix, Max, Disney+, etc.
  subscription,

  /// Gratuito com anúncios (AVOD) — Tubi, Pluto TV, etc.
  free,

  /// Aluguel (TVOD).
  rent,

  /// Compra (EST).
  buy,

  /// TV Everywhere (requer login de TV a cabo).
  tve,
}

/// Modelo de dados de uma fonte de streaming.
///
/// Representa onde um título pode ser assistido,
/// com deep links para cada plataforma.
class StreamingSourceModel {
  const StreamingSourceModel({
    required this.sourceId,
    required this.name,
    required this.type,
    this.region = '',
    this.webUrl = '',
    this.iosUrl = '',
    this.androidUrl = '',
    this.format,
    this.price,
  });

  /// Cria [StreamingSourceModel] a partir do JSON do Watchmode.
  ///
  /// ```json
  /// {
  ///   "source_id": 203, "name": "Netflix", "type": "sub",
  ///   "region": "US", "web_url": "https://...", "format": "4K"
  /// }
  /// ```
  factory StreamingSourceModel.fromWatchmodeJson(Map<String, dynamic> json) {
    return StreamingSourceModel(
      sourceId: json['source_id'] as int,
      name: (json['name'] ?? '') as String,
      type: _parseStreamingType(json['type'] as String?),
      region: (json['region'] ?? '') as String,
      webUrl: (json['web_url'] ?? '') as String,
      iosUrl: (json['ios_url'] ?? '') as String,
      androidUrl: (json['android_url'] ?? '') as String,
      format: json['format'] as String?,
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  /// ID da fonte no Watchmode.
  final int sourceId;

  /// Nome do serviço (ex: "Netflix", "Apple TV").
  final String name;

  /// Tipo de disponibilidade.
  final StreamingType type;

  /// Código do país/região (ex: "BR", "US").
  final String region;

  /// URL para assistir no navegador.
  final String webUrl;

  /// Deep link para app iOS.
  final String iosUrl;

  /// Deep link para app Android.
  final String androidUrl;

  /// Formato disponível (ex: "HD", "4K").
  final String? format;

  /// Preço (para rent/buy). Null para subscription/free.
  final double? price;

  /// Se é gratuito (assinatura ou free com ads).
  bool get isFree => type == StreamingType.subscription || type == StreamingType.free;

  /// Label formatado do tipo de streaming.
  String get typeLabel => switch (type) {
        StreamingType.subscription => 'Assinatura',
        StreamingType.free => 'Grátis',
        StreamingType.rent => 'Aluguel',
        StreamingType.buy => 'Compra',
        StreamingType.tve => 'TV',
      };

  /// Converte string da API para [StreamingType].
  static StreamingType _parseStreamingType(String? type) {
    return switch (type) {
      'sub' => StreamingType.subscription,
      'free' => StreamingType.free,
      'rent' => StreamingType.rent,
      'buy' => StreamingType.buy,
      'tve' => StreamingType.tve,
      _ => StreamingType.subscription,
    };
  }

  @override
  String toString() => 'StreamingSource(name: $name, type: $typeLabel, region: $region)';
}
