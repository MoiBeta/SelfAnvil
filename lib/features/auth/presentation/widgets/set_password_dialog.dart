import 'package:auto_admin_app/core/errors/global_message_notifier.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/global/widgets/loading_button.dart';
import 'package:auto_admin_app/global/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Minimum length the server accepts.
const _minPasswordLength = 6;

/// Adds a password to an account created with Google, so it can also sign in
/// with email and password.
class SetPasswordDialog extends HookConsumerWidget {
  const SetPasswordDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final saving = useState(false);
    final email = ref.watch(authNotifierProvider).value?.credentials?.email;

    Future<void> submit() async {
      if (saving.value || !formKey.currentState!.validate()) return;
      saving.value = true;
      final ok = await ref
          .read(authNotifierProvider.notifier)
          .setPassword(passwordController.text);
      if (!context.mounted) return;
      saving.value = false;
      if (ok) {
        Navigator.of(context).pop();
        ref.read(globalMessageProvider.notifier).show('Contraseña creada.');
      }
    }

    return AlertDialog(
      title: const Text('Crear contraseña'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Así podrás entrar también con ${email ?? 'tu correo'} y esta '
              'contraseña, además de con Google.',
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: passwordController,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) => (value ?? '').length < _minPasswordLength
                  ? 'Usa al menos $_minPasswordLength caracteres'
                  : null,
              onSubmitted: (_) => submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving.value ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        LoadingButton(
          isLoading: saving.value,
          onPressed: submit,
          label: 'Guardar',
        ),
      ],
    );
  }
}
