import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:safe_watch/core/api/api_config.dart';

// ============================================================================
// Safe Watch — API Interceptors
// ============================================================================
// Interceptors compartilhados entre todos os clientes Dio.
//
// - RateLimitInterceptor : trata HTTP 429 com retry exponencial
// - LoggingInterceptor   : loga requests/responses em modo debug
// - CacheInterceptor     : cache em memória para reduzir chamadas repetidas
// ============================================================================

// ----------------------------------------------------------------------------
// RateLimitInterceptor
// ----------------------------------------------------------------------------

/// Interceptor que trata respostas 429 (Too Many Requests).
///
/// Aguarda o tempo indicado no header `Retry-After` (ou usa backoff
/// exponencial) e reexecuta a requisição automaticamente até
/// [ApiConfig.maxRetryAttempts] tentativas.
class RateLimitInterceptor extends Interceptor {
  RateLimitInterceptor({this.maxAttempts = ApiConfig.maxRetryAttempts});

  final int maxAttempts;

  /// Mapa interno para rastrear tentativas por URL.
  final Map<String, int> _attempts = {};

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Sucesso — limpa contador de tentativas para essa URL.
    final key = _requestKey(response.requestOptions);
    _attempts.remove(key);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 429) {
      handler.next(err);
      return;
    }

    final key = _requestKey(err.requestOptions);
    final attempt = (_attempts[key] ?? 0) + 1;

    if (attempt > maxAttempts) {
      _attempts.remove(key);
      handler.next(err);
      return;
    }

    _attempts[key] = attempt;

    // Calcula delay: prefere Retry-After do header, senão usa backoff.
    final retryAfterHeader =
        err.response?.headers.value('retry-after') ??
        err.response?.headers.value('Retry-After');

    final delayMs = retryAfterHeader != null
        ? (double.tryParse(retryAfterHeader) ?? 1.0) * 1000
        : ApiConfig.retryBaseDelayMs * (1 << (attempt - 1)); // 1s, 2s, 4s

    developer.log(
      '[RateLimit] 429 recebido — aguardando ${delayMs.toInt()}ms '
      '(tentativa $attempt/$maxAttempts) para ${err.requestOptions.uri}',
      name: 'SafeWatch.API',
    );

    await Future<void>.delayed(Duration(milliseconds: delayMs.toInt()));

    // Reexecuta a requisição original.
    try {
      final dio = Dio();
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    }
  }

  String _requestKey(RequestOptions options) =>
      '${options.method}:${options.uri}';
}

// ----------------------------------------------------------------------------
// LoggingInterceptor
// ----------------------------------------------------------------------------

/// Interceptor de logging para debug de requests e responses.
///
/// Só loga em modo debug (assert ativo). Em release, não produz saída.
/// Usa [developer.log] em vez de `print` para integração com DevTools.
class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor({this.logBody = false});

  /// Se verdadeiro, também loga o body da response (pode ser verboso).
  final bool logBody;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      developer.log(
        '→ ${options.method} ${options.uri}',
        name: 'SafeWatch.API',
      );
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      developer.log(
        '← ${response.statusCode} ${response.requestOptions.uri}',
        name: 'SafeWatch.API',
      );
      if (logBody) {
        developer.log(
          '  body: ${response.data}',
          name: 'SafeWatch.API',
        );
      }
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      developer.log(
        '✗ ${err.response?.statusCode ?? 'ERR'} '
        '${err.requestOptions.uri} — ${err.message}',
        name: 'SafeWatch.API',
        error: err,
      );
      return true;
    }());
    handler.next(err);
  }
}

// ----------------------------------------------------------------------------
// CacheInterceptor
// ----------------------------------------------------------------------------

/// Interceptor de cache simples em memória.
///
/// Cacheia respostas GET bem-sucedidas pelo tempo configurado em [maxAge].
/// Útil para reduzir chamadas repetidas a endpoints estáticos como
/// detalhes de séries, temporadas e listas de providers.
///
/// Limitações:
/// - Cache não persiste entre sessões do app (em memória).
/// - Não diferencia parâmetros de query na mesma URL base se a URL completa
///   for igual (mas o Dio inclui query params na URL, então funciona).
class CacheInterceptor extends Interceptor {
  CacheInterceptor({this.maxAge = const Duration(minutes: 10)});

  /// Tempo máximo de validade de um item no cache.
  final Duration maxAge;

  final Map<String, _CacheEntry> _cache = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Só faz cache de requisições GET.
    if (options.method.toUpperCase() != 'GET') {
      handler.next(options);
      return;
    }

    // Verifica se a flag de cache está ativa (default: true para GET).
    final useCache = options.extra['useCache'] as bool? ?? true;
    if (!useCache) {
      handler.next(options);
      return;
    }

    final key = options.uri.toString();
    final entry = _cache[key];

    if (entry != null && !entry.isExpired(maxAge)) {
      // Cache hit — retorna a resposta cacheada sem fazer request.
      assert(() {
        developer.log('⚡ cache hit: $key', name: 'SafeWatch.Cache');
        return true;
      }());
      handler.resolve(
        Response(
          requestOptions: options,
          data: entry.data,
          statusCode: 200,
          extra: {'fromCache': true},
        ),
      );
      return;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Armazena no cache apenas respostas GET com status 2xx.
    final isGet = response.requestOptions.method.toUpperCase() == 'GET';
    final is2xx =
        response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
    final useCache = response.requestOptions.extra['useCache'] as bool? ?? true;
    final fromCache = response.extra['fromCache'] as bool? ?? false;

    if (isGet && is2xx && useCache && !fromCache) {
      final key = response.requestOptions.uri.toString();
      _cache[key] = _CacheEntry(data: response.data);
    }

    handler.next(response);
  }

  /// Remove um item específico do cache pela URL.
  void invalidate(String url) => _cache.remove(url);

  /// Limpa todo o cache.
  void clear() => _cache.clear();
}

/// Entrada individual do cache com timestamp.
class _CacheEntry {
  _CacheEntry({required this.data}) : createdAt = DateTime.now();

  final dynamic data;
  final DateTime createdAt;

  bool isExpired(Duration maxAge) =>
      DateTime.now().difference(createdAt) > maxAge;
}
