import 'package:auto_admin_app/core/constants/validators.dart';
import 'package:auto_admin_app/core/errors/global_message_notifier.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/global/theme/spacing.dart';
import 'package:auto_admin_app/global/widgets/loading_button.dart';
import 'package:auto_admin_app/global/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Minimum length the server accepts.
const _minPasswordLength = 6;

/// Resets the password with a code sent by email, in two steps: the email,
/// then the code and the new password. On success the user is signed in and
/// the router takes them home.
class ForgotPasswordScreen extends HookConsumerWidget {
  /// Prefills the email, typically with what was typed on the login screen.
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController(text: initialEmail);
    final codeController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final codeSent = useState(false);
    final busy = useState(false);

    final notifier = ref.read(authNotifierProvider.notifier);
    void showMessage(String message) =>
        ref.read(globalMessageProvider.notifier).show(message);

    Future<void> requestCode() async {
      busy.value = true;
      final ok =
          await notifier.requestPasswordReset(emailController.text.trim());
      if (!context.mounted) return;
      busy.value = false;
      if (ok) {
        codeSent.value = true;
        showMessage('Si el correo tiene una cuenta, te enviamos un código.');
      }
    }

    Future<void> sendCode() async {
      if (busy.value || !formKey.currentState!.validate()) return;
      await requestCode();
    }

    Future<void> reset() async {
      if (busy.value || !formKey.currentState!.validate()) return;
      busy.value = true;
      final ok = await notifier.resetPassword(
        email: emailController.text.trim(),
        code: codeController.text.trim(),
        password: passwordController.text,
      );
      if (!context.mounted) return;
      busy.value = false;
      if (ok) showMessage('Contraseña cambiada.');
    }

    final email = emailController.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.formHorizontal),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: codeSent.value
                      ? [
                          Text(
                            'Escribe el código que enviamos a $email y tu '
                            'nueva contraseña.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: Spacing.formFieldSpacing),
                          TextFormField(
                            controller: codeController,
                            decoration: const InputDecoration(
                              labelText: 'Código',
                              counterText: '',
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 6,
                            validator: (value) =>
                                RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                                    ? null
                                    : 'Escribe el código de 6 dígitos',
                          ),
                          const SizedBox(height: Spacing.formFieldSpacing),
                          PasswordField(
                            controller: passwordController,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: (value) =>
                                (value ?? '').length < _minPasswordLength
                                    ? 'Usa al menos $_minPasswordLength '
                                        'caracteres'
                                    : null,
                            onSubmitted: (_) => reset(),
                          ),
                          const SizedBox(height: Spacing.formFieldSpacing),
                          LoadingButton(
                            isLoading: busy.value,
                            onPressed: reset,
                            label: 'Cambiar contraseña',
                          ),
                          const SizedBox(height: Spacing.sm),
                          TextButton(
                            // The email was already checked on the first step.
                            onPressed: busy.value ? null : requestCode,
                            child: const Text('Reenviar código'),
                          ),
                          TextButton(
                            onPressed: busy.value
                                ? null
                                : () {
                                    codeController.clear();
                                    codeSent.value = false;
                                  },
                            child: const Text('Usar otro correo'),
                          ),
                        ]
                      : [
                          const Text(
                            'Te enviaremos un código a tu correo para que '
                            'elijas una nueva contraseña.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: Spacing.formFieldSpacing),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.email],
                            decoration:
                                const InputDecoration(labelText: 'Correo'),
                            validator: validateEmail,
                            onFieldSubmitted: (_) => sendCode(),
                          ),
                          const SizedBox(height: Spacing.formFieldSpacing),
                          LoadingButton(
                            isLoading: busy.value,
                            onPressed: sendCode,
                            label: 'Enviar código',
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
