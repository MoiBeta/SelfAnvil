import 'package:auto_admin_app/features/auth/data/models/auth_credential_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads fullName from login/register responses', () {
    final model = AuthCredentialModel.fromJson(
        {'id': '1', 'email': 'a@b.com', 'fullName': 'Ana', 'role': 'USER'});
    expect(model.fullName, 'Ana');
  });

  test('reads name from /auth/me responses', () {
    final model = AuthCredentialModel.fromJson(
        {'id': '1', 'email': 'a@b.com', 'name': 'Ana'});
    expect(model.fullName, 'Ana');
  });

  test('reads whether the email is verified and the account has a password',
      () {
    final model = AuthCredentialModel.fromJson({
      'id': '1',
      'email': 'a@b.com',
      'fullName': 'Ana',
      'isEmailConfirmed': true,
      'hasPassword': false,
    });
    final entity = model.toEntity();
    expect(entity.isEmailConfirmed, isTrue);
    expect(entity.hasPassword, isFalse);
  });
}
