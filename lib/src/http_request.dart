import 'package:dio/dio.dart';
import 'http_request_impl.dart';

abstract class HttpRequest {
  factory HttpRequest(String serverUrl, String apiKey,
      [Duration connectTimeout]) = HttpRequestImpl;

  /// Meilisearch server URL.
  String get serverUrl;

  /// API key for authenticating with Meilisearch server.
  String? get apiKey;

  /// Timeout for opening a url.
  Duration? get connectTimeout;

  /// Retrieve all headers used when Http calls are made.
  Map<String, Object?> headers();

  /// GET method
  Future<Response<T>> getMethod<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
  });

  /// PATCH method
  Future<Response<T>> patchMethod<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
  });

  /// POST method
  Future<Response<T>> postMethod<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
  });

  /// PUT method
  Future<Response<T>> putMethod<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
  });

  /// DELETE method
  Future<Response<T>> deleteMethod<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
  });
}
