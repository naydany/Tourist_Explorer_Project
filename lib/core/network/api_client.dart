import 'dart:convert' show jsonDecode;

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_exception.dart';

/// The single place that speaks HTTP.
///
/// Wraps [Dio] so the rest of the app never imports it: requests go out with
/// the standard headers and base URL already applied, and every failure comes
/// back as an [ApiException] rather than a [DioException]. Datasources above
/// this layer deal in decoded JSON only.
class ApiClient {
  ApiClient({Dio? dio, String? baseUrl, this.deviceId}) : _dio = dio ?? Dio() {
    _dio.options = _dio.options.copyWith(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      responseType: ResponseType.json,
      headers: <String, String>{
        'Accept': 'application/json',
        'X-Device-Id': ?deviceId,
      },
      // Take every status back as a normal response and decide here, so error
      // bodies stay readable instead of arriving as a thrown DioException.
      validateStatus: (_) => true,
    );
  }

  final Dio _dio;

  /// Identifies the caller to the `/favorites` endpoints, which key their list
  /// on an `X-Device-Id` header rather than an account.
  final String? deviceId;

  /// Escape hatch for interceptors (logging, auth refresh, ETag caching).
  Dio get dio => _dio;

  Future<Object?> get(String path, {Map<String, Object?>? query}) {
    return _send('GET', path, query: query);
  }

  Future<Object?> post(String path, {Object? body}) {
    return _send('POST', path, body: body);
  }

  Future<Object?> patch(String path, {Object? body}) {
    return _send('PATCH', path, body: body);
  }

  Future<Object?> put(String path, {Map<String, Object?>? query}) {
    return _send('PUT', path, query: query);
  }

  Future<Object?> delete(String path, {Map<String, Object?>? query}) {
    return _send('DELETE', path, query: query);
  }

  /// Closes the underlying connection pool. Call from the owner's `dispose`.
  void close() => _dio.close();

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: _query(query),
        options: Options(method: method),
      );
    } on DioException catch (error) {
      throw _networkFailure(error);
    }

    return _decode(response);
  }

  /// Drops nulls so an unset filter is simply absent from the query string.
  /// Dio stringifies the remaining values itself.
  Map<String, Object>? _query(Map<String, Object?>? query) {
    if (query == null || query.isEmpty) return null;
    final params = <String, Object>{
      for (final entry in query.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    return params.isEmpty ? null : params;
  }

  /// `validateStatus` lets everything through, so a [DioException] here is a
  /// transport problem rather than an HTTP error status.
  ApiException _networkFailure(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const NetworkException(
        'The server took too long to respond.',
      ),
      DioExceptionType.cancel => const NetworkException('Request cancelled.'),
      DioExceptionType.badCertificate => const NetworkException(
        'The server certificate could not be trusted.',
      ),
      _ => NetworkException(error.message ?? 'Could not reach the server.'),
    };
  }

  Object? _decode(Response<dynamic> response) {
    final status = response.statusCode ?? 0;

    // 204 (delete) and 304 (unchanged, when ETags are in play) carry no body.
    if (status == 204 || status == 304) return null;

    if (status < 200 || status >= 300) {
      throw ApiStatusException(status, _errorMessage(response.data));
    }

    final data = response.data;
    if (data == null) return null;

    // Dio decodes JSON itself; a String here means the server sent something
    // else, or a content type Dio did not recognise.
    if (data is String) {
      if (data.isEmpty) return null;
      try {
        return jsonDecode(data);
      } on FormatException {
        throw const ParseException();
      }
    }
    return data;
  }

  /// FastAPI reports failures as `{"detail": ...}`; fall back to the raw body
  /// when the error came from somewhere else, such as a proxy.
  String _errorMessage(Object? data) {
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail != null) return '$detail';
    }
    if (data is String && data.isNotEmpty) return data;
    return 'Request failed.';
  }
}
