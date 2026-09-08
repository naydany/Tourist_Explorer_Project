import 'dart:convert' show jsonDecode;

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({Dio? dio, String? baseUrl, this.deviceId}) : _dio = dio ?? Dio() {
    _dio.options = _dio.options.copyWith(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      responseType: ResponseType.json,
      headers: <String, String>{
        'Accept': 'application/json',
        'X-Device-Id': ?deviceId,
      },
      validateStatus: (_) => true,
    );

    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(LogInterceptor(requestBody: true));
    }
  }

  final Dio _dio;

  final String? deviceId;

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

  Map<String, Object>? _query(Map<String, Object?>? query) {
    if (query == null || query.isEmpty) return null;
    final params = <String, Object>{
      for (final entry in query.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    return params.isEmpty ? null : params;
  }

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

    if (status == 204 || status == 304) return null;

    if (status < 200 || status >= 300) {
      throw ApiStatusException(status, _errorMessage(response.data));
    }

    final data = response.data;
    if (data == null) return null;

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
