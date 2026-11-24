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

class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullNameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);

    final loginState = ref.watch(authNotifierProvider).value;
    final isLoading = loginState?.isLoading ?? false;

    ref.listen(authNotifierProvider, (previous, next) {
      final credentials = next.value?.credentials;
      if (credentials != null && context.mounted) {
        context.go(credentials.isEmailConfirmed == false
            ? Routes.verifyEmail
            : Routes.home);
      }
    });

    Future<void> submit() async {
      if (isLoading || !formKey.currentState!.validate()) return;
      await ref.read(authNotifierProvider.notifier).register(
            email: emailController.text.trim(),
            password: passwordController.text,
            fullName: fullNameController.text.trim(),
          );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.formHorizontal),
        child: Center(
          // Scrollable: the keyboard leaves little room on small screens.
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: fullNameController,
                      decoration:
                          const InputDecoration(labelText: 'Nombre completo'),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      validator: (value) =>
                          validateRequired(value, 'Escribe tu nombre'),
                    ),
                    const SizedBox(height: Spacing.formFieldSpacing),
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
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (value) =>
                          validateRequired(value, 'Escribe una contraseña'),
                      onSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: Spacing.formFieldSpacing),
                    LoadingButton(
                      isLoading: isLoading,
                      onPressed: submit,
                      label: 'Registrarse',
                    ),
                    const SizedBox(height: Spacing.sm),
                    const GoogleSignInButton(),
                    const SizedBox(height: Spacing.sm),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.pushReplacementNamed(Routes.login),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
