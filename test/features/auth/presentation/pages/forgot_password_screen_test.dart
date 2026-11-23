import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthNotifier extends AuthNotifier {
  final requested = <String>[];
  final resets = <(String, String, String)>[];
  bool acceptReset = true;

  @override
  Future<LoginState> build() async => const LoginState(isLoading: false);

  @override
  Future<bool> requestPasswordReset(String email) async {
    requested.add(email);
    return true;
  }

  @override
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    resets.add((email, code, password));
    if (acceptReset) {
      state = AsyncData(state.value!.copyWith(
        credentials: AuthCredential(
          id: '1',
          fullName: 'Ana',
          email: email,
          isEmailConfirmed: true,
          hasPassword: true,
        ),
      ));
    }
    return acceptReset;
  }
}

void main() {
  late _FakeAuthNotifier auth;

  Future<void> pumpScreen(WidgetTester tester, {String? email}) async {
    auth = _FakeAuthNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authNotifierProvider.overrideWith(() => auth)],
        child: MaterialApp(home: ForgotPasswordScreen(initialEmail: email)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('prefills the email typed on the login screen', (tester) async {
    await pumpScreen(tester, email: 'ana@gmail.com');

    expect(find.text('ana@gmail.com'), findsOneWidget);
  });

  testWidgets('asks for a valid email before sending', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField), 'ana');
    await tapText(tester, 'Enviar código');

    expect(find.text('Escribe un correo válido'), findsOneWidget);
    expect(auth.requested, isEmpty);
  });

  testWidgets('sends the code, then resets with it', (tester) async {
    await pumpScreen(tester, email: 'ana@gmail.com');

    await tapText(tester, 'Enviar código');
    expect(auth.requested, ['ana@gmail.com']);
    expect(find.textContaining('enviamos a ana@gmail.com'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '123456');
    await tester.enterText(find.byType(TextFormField).at(1), 'newpass1');
    await tapText(tester, 'Cambiar contraseña');

    expect(auth.resets, [('ana@gmail.com', '123456', 'newpass1')]);
    expect(auth.state.value!.credentials, isNotNull);
  });

  testWidgets('checks the code and password before resetting', (tester) async {
    await pumpScreen(tester, email: 'ana@gmail.com');
    await tapText(tester, 'Enviar código');

    await tester.enterText(find.byType(TextFormField).at(0), '12');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tapText(tester, 'Cambiar contraseña');

    expect(find.text('Escribe el código de 6 dígitos'), findsOneWidget);
    expect(find.text('Usa al menos 6 caracteres'), findsOneWidget);
    expect(auth.resets, isEmpty);
  });

  testWidgets('resends the code without asking for it first', (tester) async {
    await pumpScreen(tester, email: 'ana@gmail.com');
    await tapText(tester, 'Enviar código');

    await tapText(tester, 'Reenviar código');

    expect(auth.requested, ['ana@gmail.com', 'ana@gmail.com']);
  });

  testWidgets('can go back to change the email', (tester) async {
    await pumpScreen(tester, email: 'ana@gmail.com');
    await tapText(tester, 'Enviar código');

    await tapText(tester, 'Usar otro correo');

    expect(find.text('Enviar código'), findsOneWidget);
  });
}
