import 'package:auto_admin_app/core/errors/app_error.dart';
import 'package:auto_admin_app/core/errors/app_exception.dart';
import 'package:auto_admin_app/core/errors/global_error_notifier.dart';
import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AuthCredential _account({bool verified = false, bool hasPassword = true}) =>
    AuthCredential(
      id: '1',
      fullName: 'Ana',
      email: 'ana@gmail.com',
      isEmailConfirmed: verified,
      hasPassword: hasPassword,
    );

class _FakeRepository implements AuthRepository {
  AuthCredential? signedIn = _account();
  Object? failure;
  String? sentCode;
  String? sentPassword;
  int resent = 0;

  @override
  Future<AuthCredential?> getAuthState() async => signedIn;

  @override
  Future<AuthCredential> confirmEmail(String code) async {
    if (failure != null) throw failure!;
    sentCode = code;
    return _account(verified: true);
  }

  @override
  Future<void> resendConfirmationCode() async {
    if (failure != null) throw failure!;
    resent++;
  }

  @override
  Future<AuthCredential> setPassword(String password) async {
    if (failure != null) throw failure!;
    sentPassword = password;
    return _account(verified: true, hasPassword: true);
  }

  String? resetEmail;

  @override
  Future<void> requestPasswordReset(String email) async {
    if (failure != null) throw failure!;
    resetEmail = email;
  }

  @override
  Future<AuthCredential> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    if (failure != null) throw failure!;
    sentCode = code;
    sentPassword = password;
    return _account(verified: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeRepository repository;
  late ProviderContainer container;
  final errors = <AppError>[];
  const failure = AppException(
    AppError(
        message: 'El código no es correcto.', type: AppErrorType.validation),
  );

  Future<void> start() async {
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen<AppError?>(globalErrorProvider, (_, next) {
      if (next != null) errors.add(next);
    });
    await container.read(authNotifierProvider.future);
  }

  setUp(() {
    repository = _FakeRepository();
    errors.clear();
  });

  tearDown(() => container.dispose());

  AuthCredential? credentials() =>
      container.read(authNotifierProvider).value!.credentials;

  test('verifying the email updates the account', () async {
    await start();

    final ok = await container
        .read(authNotifierProvider.notifier)
        .confirmEmail('123456');

    expect(ok, isTrue);
    expect(repository.sentCode, '123456');
    expect(credentials()!.isEmailConfirmed, isTrue);
    expect(errors, isEmpty);
  });

  test('a rejected code is reported and changes nothing', () async {
    await start();
    repository.failure = failure;

    final ok = await container
        .read(authNotifierProvider.notifier)
        .confirmEmail('000000');

    expect(ok, isFalse);
    expect(credentials()!.isEmailConfirmed, isFalse);
    expect(errors.single.message, 'El código no es correcto.');
  });

  test('resending a code', () async {
    await start();

    expect(
      await container
          .read(authNotifierProvider.notifier)
          .resendConfirmationCode(),
      isTrue,
    );
    expect(repository.resent, 1);
  });

  test('adding a password updates the account', () async {
    repository.signedIn = _account(verified: true, hasPassword: false);
    await start();

    final ok = await container
        .read(authNotifierProvider.notifier)
        .setPassword('secret1');

    expect(ok, isTrue);
    expect(repository.sentPassword, 'secret1');
    expect(credentials()!.hasPassword, isTrue);
  });

  test('an answer arriving after the session ended does not sign in', () async {
    repository.signedIn = null;
    await start();

    await container.read(authNotifierProvider.notifier).setPassword('secret1');

    expect(credentials(), isNull);
  });

  test('requesting a password reset', () async {
    repository.signedIn = null;
    await start();

    final ok = await container
        .read(authNotifierProvider.notifier)
        .requestPasswordReset('ana@gmail.com');

    expect(ok, isTrue);
    expect(repository.resetEmail, 'ana@gmail.com');
  });

  test('resetting the password signs in', () async {
    repository.signedIn = null;
    await start();

    final ok =
        await container.read(authNotifierProvider.notifier).resetPassword(
              email: 'ana@gmail.com',
              code: '123456',
              password: 'newpass1',
            );

    expect(ok, isTrue);
    expect(repository.sentCode, '123456');
    expect(credentials()!.email, 'ana@gmail.com');
  });

  test('a rejected reset is reported and does not sign in', () async {
    repository.signedIn = null;
    await start();
    repository.failure = failure;

    final ok =
        await container.read(authNotifierProvider.notifier).resetPassword(
              email: 'ana@gmail.com',
              code: '000000',
              password: 'newpass1',
            );

    expect(ok, isFalse);
    expect(credentials(), isNull);
    expect(errors.single.message, 'El código no es correcto.');
  });
}
