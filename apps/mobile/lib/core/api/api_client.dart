import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/token_store.dart';
import 'api_exception.dart';
import 'generated/export.dart';
import 'http_adapter.dart';

/// Builds the Dio stack shared by every generated client:
/// platform/version headers, bearer auth with single-flight refresh (mobile),
/// cookie credentials + CSRF header (web), and force-update detection.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this.tokens,
    required String platform,
    required String appVersion,
    required this.useCookies,
    this.onSessionExpired,
    this.onUpdateRequired,
    HttpClientAdapter? adapter,
  }) {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'X-App-Platform': platform,
        'X-App-Version': appVersion,
        if (useCookies) 'X-Requested-With': 'XMLHttpRequest',
      },
    );
    dio = Dio(options);
    _refreshDio = Dio(options);
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
      _refreshDio.httpClientAdapter = adapter;
    } else {
      configureHttpAdapter(dio);
      configureHttpAdapter(_refreshDio);
    }
    dio.interceptors.add(_AuthInterceptor(this));
    api = PlengoApi(dio);
  }

  final TokenStore tokens;
  final bool useCookies;
  final VoidCallback? onSessionExpired;
  final VoidCallback? onUpdateRequired;

  late final Dio dio;
  late final Dio _refreshDio;
  late final PlengoApi api;

  Future<bool>? _refreshing;

  /// Rotates the refresh token once even when many requests hit 401 together.
  Future<bool> refreshTokens() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final current = await tokens.read();
    if (current == null) return false;
    try {
      final res = await PlengoApi(_refreshDio).auth.mobileRefresh(
            body: MobileRefreshRequest(refreshToken: current.refreshToken),
          );
      await tokens.write(StoredTokens(accessToken: res.data.accessToken, refreshToken: res.data.refreshToken));
      return true;
    } on DioException catch (e) {
      // Only a definitive rejection ends the session; network errors keep the tokens for later.
      if (e.response?.statusCode == 401) {
        await tokens.clear();
        onSessionExpired?.call();
      }
      return false;
    }
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this.client);

  final ApiClient client;
  static const _retried = 'auth.retried';

  bool _isAuthEndpoint(RequestOptions o) => o.path.startsWith('/api/v1/auth/');

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!client.useCookies && !_isAuthEndpoint(options)) {
      final stored = await client.tokens.read();
      if (stored != null) options.headers['Authorization'] = 'Bearer ${stored.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final apiError = ApiException.fromDio(err);

    if (response?.statusCode == 426 || apiError.code == 'APP_UPDATE_REQUIRED') {
      client.onUpdateRequired?.call();
      return handler.next(err);
    }

    final canRefresh = !client.useCookies &&
        response?.statusCode == 401 &&
        !_isAuthEndpoint(err.requestOptions) &&
        err.requestOptions.extra[_retried] != true;
    if (canRefresh && await client.refreshTokens()) {
      final stored = await client.tokens.read();
      final retry = err.requestOptions
        ..extra[_retried] = true
        ..headers['Authorization'] = 'Bearer ${stored?.accessToken}';
      try {
        return handler.resolve(await client.dio.fetch<dynamic>(retry));
      } on DioException catch (e) {
        return handler.next(e);
      }
    }

    if (response?.statusCode == 401 && client.useCookies && apiError.isUnauthenticated) {
      client.onSessionExpired?.call();
    }
    handler.next(err);
  }
}
