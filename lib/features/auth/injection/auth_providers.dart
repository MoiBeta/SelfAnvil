import 'package:auto_admin_app/core/network/dio_client.dart';
import 'package:auto_admin_app/core/network/interceptors/auth_interceptor.dart';
import 'package:auto_admin_app/core/network/interceptors/error_interceptor.dart';
import 'package:auto_admin_app/core/network/interceptors/refresh_interceptor.dart';
import 'package:auto_admin_app/features/auth/data/datasources/auth_data_source.dart';
import 'package:auto_admin_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:auto_admin_app/features/auth/data/datasources/google_id_token_source.dart';
import 'package:auto_admin_app/features/auth/data/repository/auth_repository_impl.dart';
import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_login.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_login_with_google.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_logout.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_register.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/change_password.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/confirm_email.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/get_auth_state.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/resend_confirmation_code.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/set_password.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/request_password_reset.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/reset_password.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto_admin_app/global/di/global_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authBaseUrlProvider =
    Provider<String>((ref) => dotenv.env['AUTH_BASE_URL'] ?? '');

final refreshDioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(authBaseUrlProvider);
  Dio dio = Dio(apiOptions(baseUrl));
  final tokenManager = ref.watch(tokenManagerProvider);
  dio.interceptors.add(RefreshInterceptor(tokenManager));
  return dio;
});

final authDioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(authBaseUrlProvider);
  final dio = Dio(apiOptions(baseUrl));
  final tokenManager = ref.watch(tokenManagerProvider);
  final refreshDio = ref.watch(refreshDioProvider);

  dio.interceptors.addAll([
    AuthInterceptor(
      tokenManager: tokenManager,
      refreshDio: refreshDio,
      requestDio: dio,
      onSessionExpired: () =>
          ref.read(authNotifierProvider.notifier).sessionExpired(),
    ),
    ErrorInterceptor(),
  ]);
  return dio;
});

final authDioClientProvider = Provider<DioClient>((ref) {
  final dio = ref.watch(authDioProvider);
  return DioClient(dio);
});

final Provider<AuthDataSource> authSourceProvider = Provider<AuthDataSource>(
  (ref) => AuthRemoteDataSource(
    tokenManager: ref.watch(
      tokenManagerProvider,
    ),
    client: ref.watch(authDioClientProvider),
  ),
);

/// OAuth web client ID of the backend, the audience of Google ID tokens.
final googleServerClientIdProvider =
    Provider<String>((ref) => dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '');

final googleIdTokenSourceProvider = Provider<GoogleIdTokenSource>(
  (ref) => GoogleSignInIdTokenSource(
    serverClientId: ref.watch(googleServerClientIdProvider),
  ),
);

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepositoryImpl(
          ref.watch(authSourceProvider),
          ref.watch(googleIdTokenSourceProvider),
        ));

final Provider<AuthLogin> authLoginUseCaseProvider =
    Provider<AuthLogin>((ref) => AuthLogin(ref.watch(authRepositoryProvider)));

final Provider<AuthLoginWithGoogle> authLoginWithGoogleUseCaseProvider =
    Provider<AuthLoginWithGoogle>(
        (ref) => AuthLoginWithGoogle(ref.watch(authRepositoryProvider)));

final Provider<AuthLogout> authLogoutUseCaseProvider = Provider<AuthLogout>(
    (ref) => AuthLogout(ref.watch(authRepositoryProvider)));

final Provider<AuthRegister> authRegisterUseCaseProvider =
    Provider<AuthRegister>(
        (ref) => AuthRegister(ref.watch(authRepositoryProvider)));

final Provider<ConfirmEmail> confirmEmailUseCaseProvider =
    Provider<ConfirmEmail>(
        (ref) => ConfirmEmail(ref.watch(authRepositoryProvider)));

final Provider<GetAuthState> getAuthStateUseCaseProvider =
    Provider<GetAuthState>(
        (ref) => GetAuthState(ref.watch(authRepositoryProvider)));

final Provider<ResendConfirmationCode> resendConfirmationCodeUseCaseProvider =
    Provider<ResendConfirmationCode>(
        (ref) => ResendConfirmationCode(ref.watch(authRepositoryProvider)));

final Provider<SetPassword> setPasswordUseCaseProvider = Provider<SetPassword>(
    (ref) => SetPassword(ref.watch(authRepositoryProvider)));

final Provider<RequestPasswordReset> requestPasswordResetUseCaseProvider =
    Provider<RequestPasswordReset>(
        (ref) => RequestPasswordReset(ref.watch(authRepositoryProvider)));

final Provider<ResetPassword> resetPasswordUseCaseProvider =
    Provider<ResetPassword>(
        (ref) => ResetPassword(ref.watch(authRepositoryProvider)));

final Provider<ChangePassword> changePasswordUseCaseProvider =
    Provider<ChangePassword>(
        (ref) => ChangePassword(ref.watch(authRepositoryProvider)));

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, LoginState>(
  () => AuthNotifier(),
  // The splash offers a retry: don't keep the user waiting on automatic ones.
  retry: (_, __) => null,
);
