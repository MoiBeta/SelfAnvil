import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/change_password_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/login_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/sign_up_data.dart';

abstract class AuthRepository {
  Future<AuthCredential?> getAuthState();

  Future<AuthCredential?> login(LoginData loginData);

  /// Null when the user cancels.
  Future<AuthCredential?> loginWithGoogle();

  Future<AuthCredential?> registerUser(SignUpData signUpData);

  /// Verifies the email with the code sent to it.
  Future<AuthCredential> confirmEmail(String code);

  Future<void> resendConfirmationCode();

  /// Adds a password to an account that has none (created with Google).
  Future<AuthCredential> setPassword(String password);

  /// Asks for a code to reset the password of [email]'s account. Succeeds
  /// whether the account exists or not.
  Future<void> requestPasswordReset(String email);

  /// Sets a new password with the code sent by email, and signs in.
  Future<AuthCredential> resetPassword({
    required String email,
    required String code,
    required String password,
  });

  Future<void> logout();

  Future<bool> changePassword(ChangePasswordData changePasswordData);
}
