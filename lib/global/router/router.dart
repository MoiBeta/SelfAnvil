import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/auth_page.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/login_screen.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/register_screen.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/verify_email_screen.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/pages/adding_task_screen.dart';
import 'package:auto_admin_app/features/tasks/presentation/pages/home_page.dart';
import 'package:auto_admin_app/global/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Re-runs `redirect` when the user logs in/out or the session expires.
  final authChanges = ValueNotifier<bool>(false);
  ref.listen(authNotifierProvider, (_, next) {
    authChanges.value = next.value?.credentials != null;
  });
  ref.onDispose(authChanges.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authChanges,
    routes: [
      GoRoute(
        path: Routes.splash,
        name: Routes.splash,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: Routes.auth,
        name: Routes.auth,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AuthPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: Routes.login,
        name: Routes.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: Routes.register,
        name: Routes.register,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: Routes.forgotPassword,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ForgotPasswordScreen(initialEmail: state.extra as String?),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: Routes.verifyEmail,
        name: Routes.verifyEmail,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const VerifyEmailScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: Routes.home,
        name: Routes.home,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: Routes.addingTask,
        name: Routes.addingTask,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: AddingTaskScreen(
            task: state.extra != null ? state.extra as Task? : null,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
    ],
    redirect: (context, state) {
      final credentials = ref.read(authNotifierProvider).value?.credentials;
      final isAuthenticated = credentials != null;

      if (state.uri.toString() == Routes.splash) return null;

      final goingToAuth = state.uri.toString() == Routes.login ||
          state.uri.toString() == Routes.register ||
          state.uri.toString() == Routes.forgotPassword ||
          state.uri.toString() == Routes.auth;

      if (!isAuthenticated && !goingToAuth) {
        return Routes.auth;
      }

      if (isAuthenticated && goingToAuth) {
        // Just registered: ask for the code that was sent.
        if (state.uri.toString() == Routes.register &&
            credentials.isEmailConfirmed == false) {
          return Routes.verifyEmail;
        }
        return Routes.home;
      }

      return null;
    },
  );
}
