class AuthCredential {
  final String? id;
  final String? fullName;
  final String? email;
  final bool? isEmailConfirmed;

  /// False for accounts that only sign in with Google.
  final bool? hasPassword;

  AuthCredential({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isEmailConfirmed,
    this.hasPassword,
  });

  AuthCredential copyWith({
    String? id,
    String? fullName,
    String? email,
    bool? isEmailConfirmed,
    bool? hasPassword,
  }) {
    return AuthCredential(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      isEmailConfirmed: isEmailConfirmed ?? this.isEmailConfirmed,
      hasPassword: hasPassword ?? this.hasPassword,
    );
  }
}
