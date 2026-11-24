import 'dart:io';

import 'package:auto_admin_app/core/errors/app_error.dart';
import 'package:auto_admin_app/core/errors/app_exception.dart';
import 'package:dio/dio.dart';

/// Intercepts Dio errors and transforms them into typed [AppException]s.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appError = _mapDioError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: AppException(appError),
      ),
    );
  }

  AppError _mapDioError(DioException err) {
    // Connection / network errors
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown && err.error is SocketException) {
      return AppError(
        message: 'Sin conexión al servidor. Verifica tu red.',
        type: AppErrorType.network,
      );
    }

    // Timeouts
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return const AppError(
        message: 'La solicitud tardó demasiado. Intenta de nuevo.',
        type: AppErrorType.timeout,
      );
    }

    // HTTP status-based errors
    final statusCode = err.response?.statusCode;
    final serverMessage = _extractServerMessage(err.response?.data);

    if (statusCode != null) {
      return switch (statusCode) {
        400 => AppError(
            message: switch (err.requestOptions.path) {
              '/auth/email/verify' => _emailCodeMessage(serverMessage) ??
                  'Escribe el código de 6 dígitos que te enviamos.',
              '/auth/password/reset' => _emailCodeMessage(serverMessage) ??
                  'Revisa el código y la nueva contraseña.',
              _ => serverMessage ?? 'Datos inválidos.',
            },
            type: AppErrorType.validation,
            statusCode: statusCode,
            originalError: err,
          ),
        401 => AppError(
            message: switch (err.requestOptions.path) {
              '/auth/login' => 'Correo o contraseña incorrectos.',
              '/auth/google' => 'No se pudo verificar tu cuenta de Google.',
              _ => 'Tu sesión ha expirado. Inicia sesión nuevamente.',
            },
            type: AppErrorType.unauthorized,
            statusCode: statusCode,
            originalError: err,
          ),
        403 => AppError(
            message: serverMessage ?? 'No tienes permiso para esta acción.',
            type: AppErrorType.forbidden,
            statusCode: statusCode,
            originalError: err,
          ),
        404 => AppError(
            message: serverMessage ?? 'Recurso no encontrado.',
            type: AppErrorType.notFound,
            statusCode: statusCode,
            originalError: err,
          ),
        409 => AppError(
            message: switch (err.requestOptions.path) {
              '/auth/google' =>
                'Este correo ya está vinculado a otra cuenta de Google.',
              '/auth/register' => 'Ya existe una cuenta con este correo.',
              '/auth/email/resend' => 'Tu correo ya está verificado.',
              '/auth/password' => 'Tu cuenta ya tiene contraseña.',
              _ => serverMessage ?? 'Conflicto con el estado actual.',
            },
            type: AppErrorType.conflict,
            statusCode: statusCode,
            originalError: err,
          ),
        429 => AppError(
            message: serverMessage == 'Too many codes today, try again tomorrow'
                ? 'Ya te enviamos demasiados códigos hoy. Inténtalo mañana.'
                : 'Demasiados intentos. Espera un momento e inténtalo '
                    'de nuevo.',
            type: AppErrorType.validation,
            statusCode: statusCode,
            originalError: err,
          ),
        >= 500 => AppError(
            message: 'Error en el servidor. Intenta más tarde.',
            type: AppErrorType.server,
            statusCode: statusCode,
            originalError: err,
          ),
        _ => AppError(
            message: serverMessage ?? 'Error inesperado ($statusCode).',
            type: AppErrorType.unknown,
            statusCode: statusCode,
            originalError: err,
          ),
      };
    }

    // Cancelled requests
    if (err.type == DioExceptionType.cancel) {
      return const AppError(
        message: 'Solicitud cancelada.',
        type: AppErrorType.unknown,
      );
    }

    return AppError(
      message: 'Error inesperado. Intenta de nuevo.',
      type: AppErrorType.unknown,
      originalError: err,
    );
  }

  /// The messages the server gives for a rejected verification code.
  String? _emailCodeMessage(String? serverMessage) => switch (serverMessage) {
        'Invalid code' => 'El código no es correcto.',
        'The code has expired, request a new one' =>
          'El código caducó. Pide uno nuevo.',
        'Too many attempts, request a new code' =>
          'Demasiados intentos. Pide un código nuevo.',
        _ => null,
      };

  /// Tries to extract a human-readable message from the server response body.
  String? _extractServerMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      for (final key in const ['message', 'error', 'detail']) {
        final value = data[key];
        if (value is String) return value;
        // Validation errors come as a list of messages.
        if (value is List && value.isNotEmpty) return value.join('\n');
      }
      return null;
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return null;
  }
}
