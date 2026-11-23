import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/core/constants/validators.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:auto_admin_app/global/theme/spacing.dart';
import 'package:auto_admin_app/global/widgets/loading_button.dart';
import 'package:auto_admin_app/global/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Local to the screen, so the password does not outlive it.
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);

    final loginState = ref.watch(authNotifierProvider).value;
    final isLoading = loginState?.isLoading ?? false;

    ref.listen(authNotifierProvider, (previous, next) {
      final credentials = next.value?.credentials;
      if (credentials != null && context.mounted) {
        context.go(Routes.home);
      }
    });

    Future<void> submit() async {
      if (isLoading || !formKey.currentState!.validate()) return;
      await ref.read(authNotifierProvider.notifier).login(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
    }

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.formHorizontal),
        child: Form(
          key: formKey,
          child: AutofillGroup(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: Spacing.xl, bottom: Spacing.lg),
                  child: Lottie.asset(
                    'assets/animations/task-login.json',
                    // Leaves the fields visible, also with the keyboard open.
                    height: 200,
                  ),
                ),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Correo'),
                  validator: validateEmail,
                ),
                const SizedBox(height: Spacing.formFieldSpacing),
                PasswordField(
                  controller: passwordController,
                  autofillHints: const [AutofillHints.password],
                  validator: (value) =>
                      validateRequired(value, 'Escribe tu contraseña'),
                  onSubmitted: (_) => submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.pushNamed(
                              Routes.forgotPassword,
                              extra: emailController.text.trim(),
                            ),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                LoadingButton(
                  isLoading: isLoading,
                  onPressed: submit,
                  label: 'Iniciar sesión',
                ),
                const SizedBox(height: Spacing.sm),
                const GoogleSignInButton(),
                const SizedBox(height: Spacing.sm),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context.pushReplacementNamed(Routes.register),
                  child: const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
