import 'package:dio/dio.dart';

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
          logPrint: (obj) => _networkLogs.add(obj.toString()),
        ),
      );
    }
  }

  final Dio _dio;
  final String baseUrl;
  final bool logNetworkTraffic;
  final List<String> _networkLogs = [];

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

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _mapError(error);
    }
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
