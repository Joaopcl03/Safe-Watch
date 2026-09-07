# Integração de APIs — TMDB, Trakt.tv, TheTVDB, Watchmode

Integrar as 4 APIs no projeto Safe Watch seguindo a estratégia recomendada: **TMDB para catálogo/busca** + **Trakt.tv para tracking de usuário** + **TheTVDB para metadados detalhados** + **Watchmode para disponibilidade em streaming**.

## Mapa de Responsabilidades das APIs

| Funcionalidade | API Primária | Fallback |
|:---|:---|:---|
| Busca de séries/filmes | **TMDB** `/search/tv`, `/search/movie` | TheTVDB `/search` |
| Posters, backdrops, stills | **TMDB** `image.tmdb.org/t/p/w500/...` | TheTVDB artworks |
| Detalhes de série + temporadas | **TMDB** `/tv/{id}?append_to_response=external_ids` | TheTVDB `/series/{id}/extended` |
| Lista de episódios por temporada | **TMDB** `/tv/{id}/season/{num}` | TheTVDB `/series/{id}/episodes/default` |
| Ordens alternativas (DVD/Absolute) | **TheTVDB** `/series/{id}/episodes/{season-type}` | — |
| Marcar como assistido / histórico | **Trakt.tv** `/sync/history` | Local DB (Isar) |
| Watchlist (quero assistir) | **Trakt.tv** `/sync/watchlist` | Local DB (Isar) |
| Check-in ("assistindo agora") | **Trakt.tv** `/checkin` | — |
| Progresso por série | **Trakt.tv** `/shows/{id}/progress/watched` | — |
| Onde assistir (streaming) | **Watchmode** `/title/{id}/sources` | TMDB `/tv/{id}/watch/providers` |
| Cross-reference de IDs | **TMDB** `external_ids` + **Trakt** `ids` | TheTVDB `/search/remoteid` |

---

## Proposed Changes

### 1. Core — API Configuration & Clients

#### [NEW] [api_config.dart](file:///d:/SafeWatch/lib/core/api/api_config.dart)
Constantes de configuração das 4 APIs:
```dart
abstract final class ApiConfig {
  // TMDB
  static const tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';
  static String tmdbApiKey = ''; // Setar no main.dart ou via env

  // Trakt.tv  
  static const traktBaseUrl = 'https://api.trakt.tv';
  static const traktApiVersion = '2';
  static String traktClientId = '';
  static String traktClientSecret = '';

  // TheTVDB
  static const tvdbBaseUrl = 'https://api4.thetvdb.com/v4';
  static String tvdbApiKey = '';

  // Watchmode
  static const watchmodeBaseUrl = 'https://api.watchmode.com/v1';
  static String watchmodeApiKey = '';
}
```

#### [NEW] [tmdb_client.dart](file:///d:/SafeWatch/lib/core/api/clients/tmdb_client.dart)
Cliente Dio para TMDB com:
- Bearer token via interceptor
- Métodos: `searchTv()`, `searchMovie()`, `getTvDetails()`, `getSeasonDetails()`, `getEpisodeDetails()`, `getWatchProviders()`
- Rate limit handling (429 → retry com `Retry-After`)

#### [NEW] [trakt_client.dart](file:///d:/SafeWatch/lib/core/api/clients/trakt_client.dart)
Cliente Dio para Trakt.tv com:
- Headers obrigatórios: `trakt-api-version: 2`, `trakt-api-key`, `Authorization: Bearer`
- OAuth 2.0 flow (authorize → token exchange → refresh)
- Métodos: `syncHistory()`, `removeHistory()`, `getWatchlist()`, `addToWatchlist()`, `checkin()`, `getShowProgress()`

#### [NEW] [tvdb_client.dart](file:///d:/SafeWatch/lib/core/api/clients/tvdb_client.dart)
Cliente Dio para TheTVDB v4 com:
- JWT login (`POST /login`) + token caching (30 dias)
- Métodos: `searchSeries()`, `getSeriesExtended()`, `getEpisodesBySeason()`

#### [NEW] [watchmode_client.dart](file:///d:/SafeWatch/lib/core/api/clients/watchmode_client.dart)
Cliente Dio para Watchmode com:
- Header `X-API-Key`
- Métodos: `searchByTmdbId()`, `getSourcesForTitle()`, `getProviders()`

#### [NEW] [api_interceptors.dart](file:///d:/SafeWatch/lib/core/api/api_interceptors.dart)
Interceptors compartilhados:
- `RateLimitInterceptor` — trata 429 com retry automático
- `LoggingInterceptor` — debug de requests/responses
- `CacheInterceptor` — cache básico para imagens e detalhes (reduz chamadas)

---

### 2. Models — Expandir para suportar dados reais das APIs

#### [MODIFY] [media_model.dart](file:///d:/SafeWatch/lib/features/search/models/media_model.dart)
Adicionar campos para IDs cruzados e metadados expandidos:
- `tmdbId`, `tvdbId`, `imdbId`, `traktId` (cross-reference)
- `backdropPath`, `numberOfSeasons`, `numberOfEpisodes`
- `status` (Returning, Ended, In Production)
- Factory `fromTmdbJson()`, `fromTvdbJson()`

#### [NEW] [season_model.dart](file:///d:/SafeWatch/lib/features/search/models/season_model.dart)
```dart
class SeasonModel {
  final int id, seasonNumber, episodeCount;
  final String name, overview, posterPath, airDate;
  final List<EpisodeModel> episodes;
}
```

#### [NEW] [episode_model.dart](file:///d:/SafeWatch/lib/features/search/models/episode_model.dart)
```dart
class EpisodeModel {
  final int id, episodeNumber, seasonNumber, runtime;
  final String name, overview, stillPath, airDate;
  final double voteAverage;
}
```

#### [NEW] [streaming_source_model.dart](file:///d:/SafeWatch/lib/features/search/models/streaming_source_model.dart)
```dart
class StreamingSourceModel {
  final int sourceId;
  final String name, type; // sub, free, rent, buy
  final String region, webUrl, iosUrl, androidUrl;
  final String? format; // HD, 4K
  final double? price;
}
```

#### [NEW] [trakt_ids_model.dart](file:///d:/SafeWatch/lib/features/search/models/trakt_ids_model.dart)
Modelo para cross-reference de IDs entre APIs:
```dart
class TraktIds {
  final int? trakt, tmdb, tvdb;
  final String? imdb, slug;
}
```

---

### 3. Repositories — Implementações reais com APIs

#### [MODIFY] [search_repository_interface.dart](file:///d:/SafeWatch/lib/features/search/repositories/search_repository_interface.dart)
Expandir interface com novos métodos:
- `searchTv(query)` / `searchMovies(query)` (separar buscas)
- `getTvDetails(tmdbId)` → retorna `MediaModel` com temporadas
- `getSeasonDetails(tmdbId, seasonNumber)` → retorna `SeasonModel` com episódios
- `getStreamingSources(tmdbId, mediaType, region)` → retorna `List<StreamingSourceModel>`

#### [MODIFY] [search_repository.dart](file:///d:/SafeWatch/lib/features/search/repositories/search_repository.dart)
Substituir mock por implementação real usando `TmdbClient` + `WatchmodeClient`:
- `searchMedia()` → `TmdbClient.searchTv()` + `TmdbClient.searchMovie()`
- `getMediaDetails()` → `TmdbClient.getTvDetails(appendToResponse: 'external_ids')`
- `getStreamingSources()` → `WatchmodeClient.searchByTmdbId()` → `getSourcesForTitle()`

#### [NEW] [trakt_repository_interface.dart](file:///d:/SafeWatch/lib/features/watched_list/repositories/trakt_repository_interface.dart)
Nova interface para o tracking via Trakt:
```dart
abstract interface class TraktRepositoryInterface {
  Future<void> syncToHistory(List<WatchedItemModel> items);
  Future<void> removeFromHistory(List<WatchedItemModel> items);
  Future<List<WatchedItemModel>> getWatchHistory({int page, int limit});
  Future<void> addToWatchlist(List<MediaModel> media);
  Future<void> removeFromWatchlist(List<MediaModel> media);
  Future<List<MediaModel>> getWatchlist();
  Future<void> checkin(EpisodeModel episode, MediaModel show);
  Future<Map<String, dynamic>> getShowProgress(int traktId);
}
```

#### [NEW] [trakt_repository.dart](file:///d:/SafeWatch/lib/features/watched_list/repositories/trakt_repository.dart)
Implementação real usando `TraktClient`.

#### [MODIFY] [watched_list_repository.dart](file:///d:/SafeWatch/lib/features/watched_list/repositories/watched_list_repository.dart)
Coordenar entre Trakt (sync remoto) + cache local:
- `addWatchedItem()` → salva local + `TraktRepository.syncToHistory()`
- `getWatchedItems()` → lê local, sincroniza com Trakt em background

---

### 4. Auth — Trakt OAuth 2.0

#### [NEW] [trakt_auth_service.dart](file:///d:/SafeWatch/lib/core/api/auth/trakt_auth_service.dart)
Fluxo OAuth completo:
1. Gerar URL de autorização → abrir no browser
2. Capturar callback com `code`
3. Trocar `code` por `access_token` + `refresh_token`
4. Persistir tokens (shared_preferences)
5. Auto-refresh quando token expirar (3 meses)

#### [MODIFY] [auth_controller.dart](file:///d:/SafeWatch/lib/features/auth/controllers/auth_controller.dart)
Adicionar método `signInWithTrakt()` que inicia o fluxo OAuth do Trakt.

---

### 5. Core — Environment / API Keys

#### [NEW] [env_config.dart](file:///d:/SafeWatch/lib/core/config/env_config.dart)
Gerenciamento seguro de API keys via `--dart-define` ou `.env`:
```dart
abstract final class EnvConfig {
  static const tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');
  static const traktClientId = String.fromEnvironment('TRAKT_CLIENT_ID');
  static const traktClientSecret = String.fromEnvironment('TRAKT_CLIENT_SECRET');
  static const tvdbApiKey = String.fromEnvironment('TVDB_API_KEY');
  static const watchmodeApiKey = String.fromEnvironment('WATCHMODE_API_KEY');
}
```

---

### 6. Controllers — Atualizar para novos repositories

#### [MODIFY] [search_controller.dart](file:///d:/SafeWatch/lib/features/search/controllers/search_controller.dart)
- Adicionar `getDetails(tmdbId)` para detalhes completos de série
- Adicionar `getStreamingSources(tmdbId)` para onde assistir

#### [MODIFY] [watched_list_controller.dart](file:///d:/SafeWatch/lib/features/watched_list/controllers/watched_list_controller.dart)
- `addToWatched()` → sync com Trakt
- `markEpisodeWatched()` → granular por episódio via Trakt `/sync/history`
- `checkin()` → "assistindo agora" via Trakt `/checkin`

---

## Estrutura de pastas resultante (novos arquivos)

```
lib/
├── core/
│   ├── api/
│   │   ├── api_config.dart                    # [NEW] Constantes de URL/keys
│   │   ├── api_interceptors.dart              # [NEW] Rate limit, logging, cache
│   │   ├── auth/
│   │   │   └── trakt_auth_service.dart        # [NEW] OAuth 2.0 do Trakt
│   │   └── clients/
│   │       ├── tmdb_client.dart               # [NEW] Cliente Dio para TMDB
│   │       ├── trakt_client.dart              # [NEW] Cliente Dio para Trakt.tv
│   │       ├── tvdb_client.dart               # [NEW] Cliente Dio para TheTVDB v4
│   │       └── watchmode_client.dart          # [NEW] Cliente Dio para Watchmode
│   └── config/
│       └── env_config.dart                    # [NEW] API keys via dart-define
├── features/
│   ├── search/
│   │   ├── models/
│   │   │   ├── media_model.dart               # [MODIFY] + IDs cruzados
│   │   │   ├── season_model.dart              # [NEW]
│   │   │   ├── episode_model.dart             # [NEW]
│   │   │   ├── streaming_source_model.dart    # [NEW]
│   │   │   └── trakt_ids_model.dart           # [NEW]
│   │   └── repositories/
│   │       ├── search_repository.dart         # [MODIFY] → TMDB real
│   │       └── search_repository_interface.dart # [MODIFY] + novos métodos
│   └── watched_list/
│       └── repositories/
│           ├── trakt_repository_interface.dart # [NEW]
│           ├── trakt_repository.dart          # [NEW]
│           └── watched_list_repository.dart   # [MODIFY] → sync local+Trakt
```

---

## Open Questions

> [!IMPORTANT]
> **API Keys**: Você já possui API keys para alguma dessas APIs? Se não, será necessário criar contas de desenvolvedor em:
> - TMDB: https://www.themoviedb.org/settings/api (grátis)
> - Trakt.tv: https://trakt.tv/oauth/applications/new (grátis)
> - TheTVDB: https://thetvdb.com/dashboard/account/apikeys (200 req/mês grátis)
> - Watchmode: https://api.watchmode.com/ (1000 req/mês grátis)

> [!IMPORTANT]
> **Prioridade de implementação**: Quer que eu implemente todas as 4 APIs de uma vez, ou prefere começar com **TMDB + Trakt** (o par essencial) e adicionar TheTVDB e Watchmode depois?

> [!NOTE]
> **Dependência adicional**: Será necessário adicionar `shared_preferences` ao pubspec para persistir os tokens OAuth do Trakt.tv e o JWT do TheTVDB.

---

## Verification Plan

### Automated Tests
```bash
flutter analyze
flutter test
```

### Manual Verification
- Testar busca com TMDB API key real
- Testar fluxo OAuth do Trakt no browser
- Verificar cross-reference de IDs (TMDB ↔ Trakt ↔ TheTVDB)
- Testar fallback quando uma API estiver indisponível
