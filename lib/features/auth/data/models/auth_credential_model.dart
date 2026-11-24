import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';

class AuthCredentialModel {
  final String id;
  final String? fullName;
  final String? email;
  final bool? isEmailConfirmed;
  final bool? hasPassword;

  AuthCredentialModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.isEmailConfirmed,
    this.hasPassword,
  });

  AuthCredential toEntity() => AuthCredential(
        id: id,
        fullName: fullName,
        email: email,
        isEmailConfirmed: isEmailConfirmed,
        hasPassword: hasPassword,
      );

  factory AuthCredentialModel.fromJson(Map<String, dynamic> json) =>
      AuthCredentialModel(
        id: json['id'],
        // login/register return `fullName`, /auth/me returns `name`
        fullName: json['fullName'] ?? json['name'],
        email: json['email'],
        isEmailConfirmed: json['isEmailConfirmed'],
        hasPassword: json['hasPassword'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': fullName,
        'email': email,
        'isEmailConfirmed': isEmailConfirmed,
        'hasPassword': hasPassword,
      };
}
