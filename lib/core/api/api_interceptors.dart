import 'dart:developer' as developer;
import 'package:dio/dio.dart';

// ============================================================================
// Safe Watch — API Interceptors
// ============================================================================
// Interceptors compartilhados para todos os clientes Dio.
// - RateLimitInterceptor: trata HTTP 429 com retry automático
// - LoggingInterceptor: debug de requests/responses
// ============================================================================

/// Interceptor para lidar com rate limiting (HTTP 429).
///
/// Quando a API retorna 429 (Too Many Requests), espera o tempo
/// indicado no header `Retry-After` e tenta novamente.
class RateLimitInterceptor extends Interceptor {
  /// Número máximo de retries antes de desistir.
  final int maxRetries;

  RateLimitInterceptor({this.maxRetries = 3});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 429) {
      final retryAfter = _getRetryAfterSeconds(err.response!);
      final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

      if (retryCount < maxRetries) {
        developer.log(
          'Rate limited. Retrying after ${retryAfter}s (attempt ${retryCount + 1}/$maxRetries)',
          name: 'RateLimitInterceptor',
        );

        await Future<void>.delayed(Duration(seconds: retryAfter));

        // Incrementa contador de retries.
        err.requestOptions.extra['retryCount'] = retryCount + 1;

        try {
          final dio = Dio();
          final response = await dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          handler.next(err);
          return;
        }
      }
    }
    handler.next(err);
  }

  /// Extrai o tempo de espera do header Retry-After.
  int _getRetryAfterSeconds(Response response) {
    final retryAfter = response.headers.value('retry-after');
    if (retryAfter != null) {
      return int.tryParse(retryAfter) ?? 5;
    }
    return 5; // Default: 5 segundos
  }
}

/// Interceptor de logging para debug.
///
/// Loga requests, responses e erros no console de desenvolvimento.
/// Ativo apenas em modo debug.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '→ ${options.method} ${options.uri}',
      name: 'HTTP',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      '← ${response.statusCode} ${response.requestOptions.uri}',
      name: 'HTTP',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '✗ ${err.response?.statusCode ?? 'UNKNOWN'} ${err.requestOptions.uri}: ${err.message}',
      name: 'HTTP',
      error: err,
    );
    handler.next(err);
  }
}
