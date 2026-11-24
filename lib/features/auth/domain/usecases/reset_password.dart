import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';

class ResetPassword {
  final AuthRepository repository;

  ResetPassword(this.repository);

  Future<AuthCredential> call({
    required String email,
    required String code,
    required String password,
  }) =>
      repository.resetPassword(email: email, code: code, password: password);
}
