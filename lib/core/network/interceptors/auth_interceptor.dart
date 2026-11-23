import 'dart:developer';

import 'package:auto_admin_app/core/storage/token_manager.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final TokenManager tokenManager;
  final Dio requestDio;
  final Dio refreshDio;

  /// Called when the refresh token is rejected and the user must log in again.
  final void Function()? onSessionExpired;

  /// In-flight refresh shared by every interceptor instance (auth and habits
  /// clients), so concurrent 401s trigger a single refresh. With refresh token
  /// rotation, parallel refreshes would invalidate each other.
  static Future<String?>? _refreshing;

  static const _retriedKey = 'auth_retried';

  /// A 401 here means wrong credentials, not an expired session.
  static const _credentialPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/google',
    '/auth/password/reset',
  };

  AuthInterceptor({
    required this.tokenManager,
    required this.requestDio,
    required this.refreshDio,
    this.onSessionExpired,
  });

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenManager.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final alreadyRetried = requestOptions.extra[_retriedKey] == true;

    if (err.response?.statusCode != 401 ||
        alreadyRetried ||
        _credentialPaths.contains(requestOptions.path)) {
      return handler.next(err);
    }

    // An exception escaping here would leave the handler uncalled and the
    // original request hanging forever, so any failure counts as "no token".
    String? newAccessToken;
    try {
      newAccessToken = await (_refreshing ??=
          _refreshTokens().whenComplete(() => _refreshing = null));
    } catch (e, st) {
      log('Token refresh failed', error: e, stackTrace: st);
    }

    if (newAccessToken == null) {
      return handler.next(err);
    }

    try {
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final responseRetry = await requestDio.request(
        requestOptions.path,
        options: Options(
          method: requestOptions.method,
          headers: requestOptions.headers,
          extra: {...requestOptions.extra, _retriedKey: true},
        ),
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
      );
      return handler.resolve(responseRetry);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Returns the new access token, or null if the session could not be renewed.
  Future<String?> _refreshTokens() async {
    final refreshToken = await tokenManager.getRefreshToken();
    if (refreshToken == null) {
      await _expireSession();
      return null;
    }

    try {
      final response = await refreshDio.post('/auth/refresh');
      final newAccessToken = response.data['tokens']['accessToken'];
      final newRefreshToken = response.data['tokens']['refreshToken'];

      await tokenManager.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return newAccessToken;
    } on DioException catch (e) {
      // Only a rejected refresh token ends the session; network errors keep
      // the tokens so the user can retry.
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        await _expireSession();
      }
      return null;
    }
  }

  Future<void> _expireSession() async {
    await tokenManager.deleteTokens();
    try {
      onSessionExpired?.call();
    } catch (e, st) {
      log('onSessionExpired failed', error: e, stackTrace: st);
    }
  }
}
