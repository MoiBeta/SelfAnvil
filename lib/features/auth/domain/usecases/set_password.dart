import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';

class SetPassword {
  final AuthRepository repository;

  SetPassword(this.repository);

  Future<AuthCredential> call(String password) {
    return repository.setPassword(password);
  }
}
