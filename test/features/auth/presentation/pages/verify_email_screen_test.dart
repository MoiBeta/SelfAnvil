import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/verify_email_screen.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthNotifier extends AuthNotifier {
  bool accept = true;
  final codes = <String>[];
  int resent = 0;

  @override
  Future<LoginState> build() async => LoginState(
        isLoading: false,
        credentials: AuthCredential(
          id: '1',
          fullName: 'Ana',
          email: 'ana@gmail.com',
          isEmailConfirmed: false,
        ),
      );

  @override
  Future<bool> confirmEmail(String code) async {
    codes.add(code);
    return accept;
  }

  @override
  Future<bool> resendConfirmationCode() async {
    resent++;
    return true;
  }
}

void main() {
  late _FakeAuthNotifier auth;

  Future<void> pumpScreen(WidgetTester tester) async {
    auth = _FakeAuthNotifier();
    final router = GoRouter(
      initialLocation: Routes.verifyEmail,
      routes: [
        GoRoute(
          path: Routes.verifyEmail,
          builder: (_, __) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: Routes.home,
          builder: (_, __) => const Text('home'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authNotifierProvider.overrideWith(() => auth)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows where the code was sent', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('ana@gmail.com'), findsOneWidget);
  });

  testWidgets('asks for 6 digits before sending', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField), '12a4');
    await tester.tap(find.text('Verificar'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe el código de 6 dígitos'), findsOneWidget);
    expect(auth.codes, isEmpty);
  });

  testWidgets('a valid code verifies and goes home', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verificar'));
    await tester.pumpAndSettle();

    expect(auth.codes, ['123456']);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a rejected code stays on the screen', (tester) async {
    await pumpScreen(tester);
    auth.accept = false;

    await tester.enterText(find.byType(TextFormField), '000000');
    await tester.tap(find.text('Verificar'));
    await tester.pumpAndSettle();

    expect(find.byType(VerifyEmailScreen), findsOneWidget);
  });

  testWidgets('can resend the code or leave it for later', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Reenviar código'));
    await tester.pumpAndSettle();
    expect(auth.resent, 1);

    await tester.tap(find.text('Más tarde'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
