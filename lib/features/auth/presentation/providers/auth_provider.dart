import 'dart:async';
import 'dart:developer';

import 'package:auto_admin_app/core/errors/error_handler.dart';
import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_login.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_login_with_google.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_logout.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_register.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/change_password.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/confirm_email.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/get_auth_state.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/change_password_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/login_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/sign_up_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/resend_confirmation_code.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/set_password.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/request_password_reset.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/reset_password.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/notifications/notification_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends AsyncNotifier<LoginState> {
  late GetAuthState _getAuthState;
  late AuthLogin _authLogin;
  late AuthLoginWithGoogle _authLoginWithGoogle;
  late AuthRegister _authRegister;
  late ConfirmEmail _confirmEmail;
  late ResendConfirmationCode _resendConfirmationCode;
  late AuthLogout _authLogout;
  late ChangePassword _changePassword;
  late SetPassword _setPassword;
  late RequestPasswordReset _requestPasswordReset;
  late ResetPassword _resetPassword;

  StreamSubscription<String>? _fcmTokenRefreshSub;

  @override
  Future<LoginState> build() async {
    _getAuthState = ref.watch(getAuthStateUseCaseProvider);
    _authLogin = ref.watch(authLoginUseCaseProvider);
    _authLoginWithGoogle = ref.watch(authLoginWithGoogleUseCaseProvider);
    _authRegister = ref.watch(authRegisterUseCaseProvider);
    _confirmEmail = ref.watch(confirmEmailUseCaseProvider);
    _resendConfirmationCode = ref.watch(resendConfirmationCodeUseCaseProvider);
    _authLogout = ref.watch(authLogoutUseCaseProvider);
    _changePassword = ref.watch(changePasswordUseCaseProvider);
    _setPassword = ref.watch(setPasswordUseCaseProvider);
    _requestPasswordReset = ref.watch(requestPasswordResetUseCaseProvider);
    _resetPassword = ref.watch(resetPasswordUseCaseProvider);
    ref.onDispose(() => _fcmTokenRefreshSub?.cancel());

    AuthCredential? authCredential = await _getAuthState();
    if (authCredential != null) {
      // Session restored on app start: make sure the backend has this
      // device's current FCM token.
      _registerFcmToken();
    }
    return LoginState(
      isLoading: false,
      credentials: authCredential,
    );
  }

  Future<void> login({required String email, required String password}) async {
    state = AsyncData(
      state.value!.copyWith(
        isLoading: true,
      ),
    );
    try {
      AuthCredential? authCredential = await _authLogin(LoginData(
        email: email,
        password: password,
      ));
      state = AsyncData(
        state.value!.copyWith(
          isLoading: false,
          credentials: authCredential,
        ),
      );

      // Register FCM token after successful login (non-blocking)
      _registerFcmToken();
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      state = AsyncData(
        state.value!.copyWith(isLoading: false),
      );
    }
  }

  /// Signs in with the Google account the user picks. Closing the picker
  /// leaves everything as it was, without an error.
  Future<void> loginWithGoogle() async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      final authCredential = await _authLoginWithGoogle();
      state = AsyncData(
        state.value!.copyWith(isLoading: false, credentials: authCredential),
      );
      if (authCredential != null) _registerFcmToken();
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      state = AsyncData(state.value!.copyWith(isLoading: false));
    }
  }

  String get _platform =>
      kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();

  /// Registers the FCM device token with the backend (after login, register
  /// or session restore) and keeps it updated when FCM rotates it.
  /// Wrapped in try/catch to avoid blocking the login flow on failure.
  Future<void> _registerFcmToken() async {
    try {
      final pushService = ref.read(pushNotificationServiceProvider);
      final tokenRepo = ref.read(deviceTokenRepositoryProvider);
      final fcmToken = await pushService.getToken();
      if (fcmToken != null) {
        await tokenRepo.registerToken(token: fcmToken, platform: _platform);
      }

      _fcmTokenRefreshSub ??= pushService.onTokenRefresh.listen((token) {
        tokenRepo
            .registerToken(token: token, platform: _platform)
            .catchError((e) => log('Failed to update FCM token: $e'));
      });
    } catch (e) {
      log('Failed to register FCM token: $e');
    }
  }

  /// Removes this device's FCM token from the backend so the device stops
  /// receiving reminders for the logged-out user.
  Future<void> _unregisterFcmToken() async {
    await _fcmTokenRefreshSub?.cancel();
    _fcmTokenRefreshSub = null;
    try {
      final fcmToken =
          await ref.read(pushNotificationServiceProvider).getToken();
      if (fcmToken != null) {
        await ref
            .read(deviceTokenRepositoryProvider)
            .unregisterToken(token: fcmToken);
      }
    } catch (e) {
      log('Failed to unregister FCM token: $e');
    }
  }

  /// Called by the HTTP layer when the refresh token is rejected.
  void sessionExpired() {
    final current = state.value;
    // While build() is still running it already resolves to "no credentials".
    if (current == null || current.credentials == null) return;
    _fcmTokenRefreshSub?.cancel();
    _fcmTokenRefreshSub = null;
    state = AsyncData(current.copyWith(clearCredentials: true));
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = AsyncData(
      state.value!.copyWith(
        isLoading: true,
      ),
    );
    try {
      AuthCredential? authCredential = await _authRegister.call(
        SignUpData(email: email, password: password, fullName: fullName),
      );
      state = AsyncData(
        state.value!.copyWith(
          isLoading: false,
          credentials: authCredential,
        ),
      );

      _registerFcmToken();
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      state = AsyncData(
        state.value!.copyWith(isLoading: false),
      );
    }
  }

  /// Verifies the email with the code sent to it. Returns whether it worked;
  /// failures are reported to the user.
  Future<bool> confirmEmail(String code) async {
    try {
      _updateCredentials(await _confirmEmail(code));
      return true;
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      return false;
    }
  }

  /// Sends a new verification code. Returns whether it was sent.
  Future<bool> resendConfirmationCode() async {
    try {
      await _resendConfirmationCode();
      return true;
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      return false;
    }
  }

  /// Adds a password to an account created with Google, so it can also sign
  /// in with email and password. Returns whether it worked.
  Future<bool> setPassword(String password) async {
    try {
      _updateCredentials(await _setPassword(password));
      return true;
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      return false;
    }
  }

  /// Asks for a code to reset the password. Returns whether the request
  /// went through (the server does not say if the account exists).
  Future<bool> requestPasswordReset(String email) async {
    try {
      await _requestPasswordReset(email);
      return true;
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      return false;
    }
  }

  /// Sets a new password with the code sent by email and signs in. Returns
  /// whether it worked.
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      final credentials = await _resetPassword(
        email: email,
        code: code,
        password: password,
      );
      state = AsyncData(state.value!.copyWith(credentials: credentials));
      _registerFcmToken();
      return true;
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      return false;
    }
  }

  /// Applies the account returned by the server, unless the session ended
  /// in the meantime.
  void _updateCredentials(AuthCredential updated) {
    final current = state.value;
    if (current?.credentials == null) return;
    state = AsyncData(current!.copyWith(credentials: updated));
  }

  Future<void> logout() async {
    await _unregisterFcmToken();
    await _authLogout();
    state = AsyncData(
      state.value!.copyWith(
        clearCredentials: true,
      ),
    );
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = AsyncData(
      state.value!.copyWith(
        isLoading: true,
      ),
    );
    try {
      bool success = await _changePassword(
        ChangePasswordData(oldPassword: oldPassword, newPassword: newPassword),
      );
      state = AsyncData(
        state.value!.copyWith(
          isLoading: false,
        ),
      );
      return success;
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      state = AsyncData(
        state.value!.copyWith(isLoading: false),
      );
      return false;
    }
  }
}

class LoginState {
  final AuthCredential? credentials;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const LoginState({
    this.isLoading = true,
    this.hasError = false,
    this.credentials,
    this.errorMessage,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    AuthCredential? credentials,
    bool clearCredentials = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      credentials: clearCredentials ? null : (credentials ?? this.credentials),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
