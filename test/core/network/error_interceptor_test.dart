import 'package:auto_admin_app/core/errors/error_handler.dart';
import 'package:auto_admin_app/core/network/interceptors/error_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with [status] and [body].
class _FixedResponse extends Interceptor {
  final int status;
  final Object? body;

  _FixedResponse(this.status, this.body);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: status,
          data: body,
        ),
        type: DioExceptionType.badResponse,
      ),
      true,
    );
  }
}

void main() {
  Future<String> messageOf(String path, int status, [Object? body]) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.addAll([ErrorInterceptor(), _FixedResponse(status, body)]);
    try {
      await dio.post(path);
      fail('The request should fail');
    } catch (e) {
      return ErrorHandler.extractAppError(e).message;
    }
  }

  test('validation errors given as a list are shown', () async {
    expect(
      await messageOf('/auth/register', 400, {
        'message': ['password must be longer than or equal to 6 characters'],
      }),
      'password must be longer than or equal to 6 characters',
    );
  });

  test('rejected verification codes are explained in Spanish', () async {
    expect(
      await messageOf('/auth/email/verify', 400, {'message': 'Invalid code'}),
      'El código no es correcto.',
    );
    expect(
      await messageOf('/auth/email/verify', 400, {
        'message': 'The code has expired, request a new one',
      }),
      'El código caducó. Pide uno nuevo.',
    );
    expect(
      await messageOf('/auth/email/verify', 400, {
        'message': 'Too many attempts, request a new code',
      }),
      'Demasiados intentos. Pide un código nuevo.',
    );
  });

  test('conflicts of the account endpoints', () async {
    expect(
      await messageOf(
          '/auth/register', 409, {'message': 'User already exists'}),
      'Ya existe una cuenta con este correo.',
    );
    expect(
      await messageOf('/auth/password', 409),
      'Tu cuenta ya tiene contraseña.',
    );
    expect(
      await messageOf('/auth/email/resend', 409),
      'Tu correo ya está verificado.',
    );
  });

  test('too many requests', () async {
    expect(
      await messageOf('/auth/email/resend', 429),
      'Demasiados intentos. Espera un momento e inténtalo de nuevo.',
    );
  });

  test('rejected password resets', () async {
    expect(
      await messageOf('/auth/password/reset', 400, {'message': 'Invalid code'}),
      'El código no es correcto.',
    );
    expect(
      await messageOf('/auth/password/reset', 400, {
        'message': ['password must be longer than or equal to 6 characters'],
      }),
      'Revisa el código y la nueva contraseña.',
    );
  });

  test('the daily limit of codes', () async {
    expect(
      await messageOf('/auth/email/resend', 429, {
        'message': 'Too many codes today, try again tomorrow',
      }),
      'Ya te enviamos demasiados códigos hoy. Inténtalo mañana.',
    );
  });
}
