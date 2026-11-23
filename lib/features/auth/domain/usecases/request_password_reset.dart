import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';

class RequestPasswordReset {
  final AuthRepository repository;

  RequestPasswordReset(this.repository);

  Future<void> call(String email) => repository.requestPasswordReset(email);
}
