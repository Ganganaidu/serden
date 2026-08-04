import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';
import '../utils/app_logger.dart';

/// Attaches the Bearer token to every request and transparently refreshes
/// an expired access token on a 401, retrying the original request once.
class TokenInterceptor extends Interceptor {
  final SecureStorage _storage;

  /// A bare Dio with no TokenInterceptor, used only for the refresh call and
  /// the retried request — going through the main Dio here would re-enter
  /// this same interceptor and loop. PrettyDioLogger is safe to attach
  /// though (it's just a logger, not part of the auth chain), since this
  /// traffic would otherwise be completely invisible in debug logs.
  final Dio _plainDio;

  Completer<String?>? _refreshCompleter;

  TokenInterceptor(this._storage)
      : _plainDio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl)) {
    if (kDebugMode) {
      _plainDio.interceptors
          .add(PrettyDioLogger(requestBody: true, responseBody: true));
    }
  }

  static const _authFreePaths = [
    '/Users/login',
    '/Users/register',
    '/Users/refresh',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    final isAuthFreeCall = _authFreePaths.any(path.contains);

    if (err.response?.statusCode == 401 && !isAuthFreeCall) {
      AppLogger.auth('401 on $path — attempting token refresh');
      final newToken = await _refreshAccessToken();
      if (newToken != null) {
        try {
          final retryOptions = err.requestOptions
            ..headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _plainDio.fetch(retryOptions);
          AppLogger.auth('Refresh succeeded — retried $path -> '
              '${retryResponse.statusCode}');
          return handler.resolve(retryResponse);
        } catch (_) {
          AppLogger.error('Retry of $path failed even after refresh');
          // Retry failed too — fall through and propagate the original error.
        }
      } else {
        AppLogger.auth(
            'Refresh failed (or nothing to refresh) — clearing session');
        // Refresh failed (or there was nothing to refresh) — fully log out
        // so the app's redirect logic sends the user back to onboarding.
        await _storage.deleteAll();
      }
    }
    handler.next(err);
  }

  /// Single-flight refresh: concurrent 401s share one in-flight request
  /// instead of each triggering their own refresh call.
  Future<String?> _refreshAccessToken() {
    if (_refreshCompleter != null) return _refreshCompleter!.future;

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    () async {
      try {
        final refreshToken = await _storage.read(AppConstants.refreshTokenKey);
        if (refreshToken == null) {
          AppLogger.auth('No refresh token stored — cannot refresh');
          completer.complete(null);
          return;
        }
        final response = await _plainDio.post(
          '/Users/refresh',
          data: {'refreshToken': refreshToken},
        );
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;
        if (newAccessToken == null) {
          AppLogger.error('Refresh response had no accessToken');
          completer.complete(null);
          return;
        }
        await _storage.write(AppConstants.accessTokenKey, newAccessToken);
        if (newRefreshToken != null) {
          await _storage.write(AppConstants.refreshTokenKey, newRefreshToken);
        }
        if (data['user'] != null) {
          await _storage.write(AppConstants.userKey, jsonEncode(data['user']));
        }
        completer.complete(newAccessToken);
      } catch (e) {
        AppLogger.error('Refresh call threw: $e');
        completer.complete(null);
      } finally {
        _refreshCompleter = null;
      }
    }();

    return completer.future;
  }
}
