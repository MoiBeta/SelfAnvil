import 'package:auto_admin_app/features/auth/data/models/auth_credential_model.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/change_password_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/login_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/sign_up_data.dart';

abstract class AuthDataSource {
  Future<bool> changePassword(ChangePasswordData changePasswordData);
  Future<AuthCredentialModel> confirmEmail(String code);
  Future<AuthCredentialModel?> getAuthState();
  Future<AuthCredentialModel?> login(LoginData loginData);
  Future<AuthCredentialModel?> loginWithGoogle(String idToken);
  Future<void> logout();
  Future<AuthCredentialModel?> registerUser(SignUpData signUpData);
  Future<void> resendConfirmationCode();

  /// Adds a password to an account that has none (created with Google).
  Future<AuthCredentialModel> setPassword(String password);

  /// Asks for a code to reset the password of [email]'s account.
  Future<void> requestPasswordReset(String email);

  /// Sets a new password with the code sent by email, and signs in.
  Future<AuthCredentialModel> resetPassword({
    required String email,
    required String code,
    required String password,
  });
}
