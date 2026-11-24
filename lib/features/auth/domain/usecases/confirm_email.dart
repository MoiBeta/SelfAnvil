import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';

class ConfirmEmail {
  final AuthRepository repository;

  ConfirmEmail(this.repository);

  Future<AuthCredential> call(String code) {
    return repository.confirmEmail(code);
  }
}
