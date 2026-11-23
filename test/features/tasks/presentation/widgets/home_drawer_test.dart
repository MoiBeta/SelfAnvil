import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:auto_admin_app/features/tasks/presentation/widgets/home_drawer.dart';
import 'package:auto_admin_app/global/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: HomeDrawer(),
        ),
      ),
    );
  }

  group('HomeDrawer - Actions', () {
    late _FakeAuthNotifier auth;

    Future<void> openDrawer(WidgetTester tester) async {
      auth = _FakeAuthNotifier();
      final scaffoldKey = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => auth),
            homeProvider.overrideWith(_FakeHomeNotifier.new),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(key: scaffoldKey, drawer: const HomeDrawer()),
          ),
        ),
      );
      scaffoldKey.currentState!.openDrawer();
      await tester.pumpAndSettle();
    }

    testWidgets('Inicio closes the drawer', (tester) async {
      await openDrawer(tester);
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationDrawer), findsNothing);
    });

    testWidgets('logging out needs confirmation', (tester) async {
      await openDrawer(tester);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(auth.loggedOut, isFalse);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión').last);
      await tester.pumpAndSettle();
      expect(auth.loggedOut, isTrue);
      expect(find.byType(NavigationDrawer), findsNothing);
    });
  });

  group('HomeDrawer - Sign-in methods', () {
    late _FakeAuthNotifier auth;

    Future<void> openDrawer(
      WidgetTester tester, {
      required bool verified,
      required bool hasPassword,
    }) async {
      auth = _FakeAuthNotifier(
        credentials: AuthCredential(
          id: '1',
          fullName: 'Ana',
          email: 'ana@gmail.com',
          isEmailConfirmed: verified,
          hasPassword: hasPassword,
        ),
      );
      final scaffoldKey = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => auth),
            homeProvider.overrideWith(_FakeHomeNotifier.new),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(key: scaffoldKey, drawer: const HomeDrawer()),
          ),
        ),
      );
      scaffoldKey.currentState!.openDrawer();
      await tester.pumpAndSettle();
    }

    testWidgets('offers to verify the email and add a password when missing',
        (tester) async {
      await openDrawer(tester, verified: false, hasPassword: false);

      expect(find.text('Verificar correo'), findsOneWidget);
      expect(find.text('Crear contraseña'), findsOneWidget);
      expect(find.byType(NavigationDrawerDestination), findsNWidgets(4));
    });

    testWidgets('offers nothing extra when both are done', (tester) async {
      await openDrawer(tester, verified: true, hasPassword: true);

      expect(find.text('Verificar correo'), findsNothing);
      expect(find.text('Crear contraseña'), findsNothing);
      expect(find.byType(NavigationDrawerDestination), findsNWidgets(2));
    });

    testWidgets('logging out still works with the extra entries',
        (tester) async {
      await openDrawer(tester, verified: false, hasPassword: false);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión').last);
      await tester.pumpAndSettle();

      expect(auth.loggedOut, isTrue);
    });

    testWidgets('adds a password from a dialog', (tester) async {
      await openDrawer(tester, verified: true, hasPassword: false);

      await tester.tap(find.text('Crear contraseña'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationDrawer), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Usa al menos 6 caracteres'), findsOneWidget);
      expect(auth.newPassword, isNull);

      await tester.enterText(find.byType(TextFormField), 'secret1');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(auth.newPassword, 'secret1');
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('HomeDrawer - Navigation Drawer widget tests', () {
    testWidgets('uses NavigationDrawer widget (not legacy Drawer)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify NavigationDrawer is present
      expect(find.byType(NavigationDrawer), findsOneWidget);

      // Verify legacy Drawer is NOT used directly as the top-level drawer
      // NavigationDrawer internally may use Drawer, but our code should use
      // the M3 NavigationDrawer widget explicitly
      final navigationDrawerFinder = find.byType(NavigationDrawer);
      expect(navigationDrawerFinder, findsOneWidget);
    });

    testWidgets('contains NavigationDrawerDestination items',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify 2 NavigationDrawerDestination widgets are present
      expect(find.byType(NavigationDrawerDestination), findsNWidgets(2));
    });

    testWidgets('DrawerHeader is present with correct background color',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify DrawerHeader is present
      expect(find.byType(DrawerHeader), findsOneWidget);

      // Verify DrawerHeader background color matches colorScheme.primaryContainer
      final drawerHeader = tester.widget<DrawerHeader>(
        find.byType(DrawerHeader),
      );
      final decoration = drawerHeader.decoration as BoxDecoration;
      expect(
        decoration.color,
        AppTheme.lightTheme.colorScheme.primaryContainer,
      );
    });

    testWidgets('displays "SelfAnvil" text in the header',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('SelfAnvil'), findsOneWidget);
    });

    testWidgets('displays "Inicio" and "Cerrar sesión" labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  final AuthCredential? credentials;
  bool loggedOut = false;
  String? newPassword;

  _FakeAuthNotifier({this.credentials});

  @override
  Future<LoginState> build() async =>
      LoginState(isLoading: false, credentials: credentials);

  @override
  Future<void> logout() async => loggedOut = true;

  @override
  Future<bool> setPassword(String password) async {
    newPassword = password;
    return true;
  }
}

class _FakeHomeNotifier extends HomeNotifier {
  @override
  Future<List<Task>> build() async => [];
}
