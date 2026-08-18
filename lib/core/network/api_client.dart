import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../utils/app_logger.dart';
import 'token_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({required TokenInterceptor tokenInterceptor}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      tokenInterceptor,
      // Full raw request/response detail (headers + bodies) for deep debugging.
      if (kDebugMode) PrettyDioLogger(requestBody: true, responseBody: true),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      _logSuccess('GET', path, response);
      return response;
    } on DioException catch (e) {
      throw _handleDioError('GET', path, e);
    }
  }

  Future<Response> post(String path,
      {dynamic data, Map<String, dynamic>? queryParams}) async {
    try {
      final response =
          await _dio.post(path, data: data, queryParameters: queryParams);
      _logSuccess('POST', path, response);
      return response;
    } on DioException catch (e) {
      throw _handleDioError('POST', path, e);
    }
  }

  Future<Response> put(String path,
      {dynamic data, Map<String, dynamic>? queryParams}) async {
    try {
      final response =
          await _dio.put(path, data: data, queryParameters: queryParams);
      _logSuccess('PUT', path, response);
      return response;
    } on DioException catch (e) {
      throw _handleDioError('PUT', path, e);
    }
  }

  Future<Response> patch(String path,
      {dynamic data, Map<String, dynamic>? queryParams}) async {
    try {
      final response =
          await _dio.patch(path, data: data, queryParameters: queryParams);
      _logSuccess('PATCH', path, response);
      return response;
    } on DioException catch (e) {
      throw _handleDioError('PATCH', path, e);
    }
  }

  Future<Response> delete(String path,
      {Map<String, dynamic>? queryParams}) async {
    try {
      final response =
          await _dio.delete(path, queryParameters: queryParams);
      _logSuccess('DELETE', path, response);
      return response;
    } on DioException catch (e) {
      throw _handleDioError('DELETE', path, e);
    }
  }

  // One guaranteed single-line log per call, independent of PrettyDioLogger —
  // a quick scan-able audit trail even if that's ever disabled/misconfigured.
  void _logSuccess(String method, String path, Response response) {
    AppLogger.api('$method $path -> ${response.statusCode}');
  }

  Exception _handleDioError(String method, String path, DioException e) {
    final exception = _toException(e);
    AppLogger.error(
      '$method $path -> ${e.response?.statusCode ?? e.type} '
      '(${exception.runtimeType}): ${_messageOf(exception)}',
    );
    return exception;
  }

  Exception _toException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkException('Connection timed out');
      case DioExceptionType.connectionError:
        return NetworkException('No internet connection');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = _extractErrorMessage(e.response);
        if (statusCode == 401) return UnauthorizedException(message);
        return ServerException(message, statusCode: statusCode);
      default:
        return ServerException('An unexpected error occurred');
    }
  }

  String _messageOf(Exception e) => switch (e) {
        NetworkException(:final message) => message,
        UnauthorizedException(:final message) => message,
        ServerException(:final message) => message,
        _ => e.toString(),
      };

  String _extractErrorMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map) {
        // ASP.NET ValidationProblemDetails: {"errors": {"Field": ["msg", ...]}}
        final errors = data['errors'];
        if (errors is Map) {
          final messages = errors.values
              .whereType<List>()
              .expand((list) => list.whereType<String>())
              .toList();
          if (messages.isNotEmpty) return messages.join(' ');
        }
        return data['title'] as String? ??
            data['message'] as String? ??
            data['error'] as String? ??
            'Server error';
      }
      if (data is String && data.trim().isNotEmpty) return data.trim();
    } catch (_) {}
    return 'Server error (${response?.statusCode})';
  }
}
