import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.logNetworkTraffic = false,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    if (logNetworkTraffic) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: _handleLog,
        ),
      );
    }
  }

  final Dio _dio;
  final String baseUrl;
  final bool logNetworkTraffic;
  final List<String> _networkLogs = [];

  void _handleLog(Object obj) {
    final message = obj.toString();
    _networkLogs.add(message);
    debugPrint('[API] $message'); // Mostra no Logcat/console quando habilitado
  }

  List<String> drainLogs() {
    final copy = List<String>.from(_networkLogs);
    _networkLogs.clear();
    return copy;
  }

  void updateAuthToken(String? token) {
    if (token == null) {
      _dio.options.headers.remove('Authorization');
      return;
    }
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<dynamic> _getRaw(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _getRaw(path, queryParameters: queryParameters);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _getRaw(path, queryParameters: queryParameters);
    if (data is List<dynamic>) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final values = data[r'$values'];
      if (values is List<dynamic>) {
        return values;
      }
    }
    return const [];
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? data,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? data,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> putJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? data,
  }) async {
    try {
      await _dio.put<void>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  ApiException _mapError(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = error.response?.data is Map<String, dynamic>
        ? (error.response!.data['message'] as String?) ?? error.message
        : error.message;

    return ApiException(
      message ?? 'Erro de comunicação com o servidor',
      statusCode: statusCode,
      details: error.response?.data,
    );
  }
}
