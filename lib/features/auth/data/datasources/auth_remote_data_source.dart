import 'package:auto_admin_app/core/network/dio_client.dart';
import 'package:auto_admin_app/core/storage/token_manager.dart';
import 'package:auto_admin_app/features/auth/data/models/auth_credential_model.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/change_password_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/login_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/sign_up_data.dart';
import 'package:dio/dio.dart';

import 'auth_data_source.dart';

class AuthRemoteDataSource extends AuthDataSource {
  final TokenManager tokenManager;
  final DioClient client;

  AuthRemoteDataSource({required this.tokenManager, required this.client});

  @override
  Future<bool> changePassword(ChangePasswordData changePasswordData) {
    // TODO: implement changePassword
    throw UnimplementedError();
  }

  @override
  Future<AuthCredentialModel> confirmEmail(String code) async {
    final response = await client.post(
      '/auth/email/verify',
      data: {'code': code},
    );
    return AuthCredentialModel.fromJson(response.data);
  }

  @override
  Future<AuthCredentialModel?> getAuthState() async {
    if (!await tokenManager.hasAccessToken()) return null;
    try {
      final response = await client.get(
        '/auth/me',
      );
      return AuthCredentialModel.fromJson(response.data);
    } on DioException catch (e) {
      // Only a rejected session means "logged out": a network failure says
      // nothing about it, and the tokens are still valid.
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) return null;
      rethrow;
    }
  }

  @override
  Future<AuthCredentialModel?> login(LoginData loginData) async {
    try {
      final response = await client.post(
        '/auth/login',
        data: loginData.toJson(),
      );

      if (response.statusCode == 200) {
        final userData = response.data['user'];
        final tokenData = response.data['tokens'];

        await tokenManager.saveTokens(
          accessToken: tokenData['accessToken'],
          refreshToken: tokenData['refreshToken'],
        );

        return AuthCredentialModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthCredentialModel?> loginWithGoogle(String idToken) async {
    final response = await client.post(
      '/auth/google',
      data: {'idToken': idToken},
    );
    if (response.statusCode != 200) return null;

    final tokenData = response.data['tokens'];
    await tokenManager.saveTokens(
      accessToken: tokenData['accessToken'],
      refreshToken: tokenData['refreshToken'],
    );
    return AuthCredentialModel.fromJson(response.data['user']);
  }

  @override
  Future<void> logout() async {
    try {
      // Invalidates the refresh token on the server.
      await client.post('/auth/logout');
    } catch (_) {
      // Log out locally even if the server can't be reached.
    }
    await tokenManager.deleteTokens();
  }

  @override
  Future<AuthCredentialModel?> registerUser(SignUpData signUpData) async {
    Response<dynamic> response =
        await client.post('/auth/register', data: signUpData.toJson());
    if (response.statusCode == 201) {
      final userData = response.data['user'];
      final tokenData = response.data['tokens'];

      await tokenManager.saveTokens(
        accessToken: tokenData['accessToken'],
        refreshToken: tokenData['refreshToken'],
      );

      return AuthCredentialModel.fromJson(userData);
    }
    return null;
  }

  @override
  Future<void> resendConfirmationCode() async {
    await client.post('/auth/email/resend');
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await client.post('/auth/password/forgot', data: {'email': email});
  }

  @override
  Future<AuthCredentialModel> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final response = await client.post(
      '/auth/password/reset',
      data: {'email': email, 'code': code, 'password': password},
    );
    final tokenData = response.data['tokens'];
    await tokenManager.saveTokens(
      accessToken: tokenData['accessToken'],
      refreshToken: tokenData['refreshToken'],
    );
    return AuthCredentialModel.fromJson(response.data['user']);
  }

  @override
  Future<AuthCredentialModel> setPassword(String password) async {
    final response = await client.post(
      '/auth/password',
      data: {'password': password},
    );
    return AuthCredentialModel.fromJson(response.data);
  }
}
