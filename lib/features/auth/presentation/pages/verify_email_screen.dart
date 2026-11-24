import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/core/errors/global_message_notifier.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/global/theme/spacing.dart';
import 'package:auto_admin_app/global/widgets/loading_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Asks for the code sent to the user's email. Shown after registering and
/// from the drawer while the email is unverified.
class VerifyEmailScreen extends HookConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final verifying = useState(false);
    final resending = useState(false);

    final email = ref.watch(authNotifierProvider).value?.credentials?.email;
    final notifier = ref.read(authNotifierProvider.notifier);
    void showMessage(String message) =>
        ref.read(globalMessageProvider.notifier).show(message);

    Future<void> submit() async {
      if (verifying.value || !formKey.currentState!.validate()) return;
      verifying.value = true;
      final ok = await notifier.confirmEmail(codeController.text.trim());
      if (!context.mounted) return;
      verifying.value = false;
      if (ok) {
        showMessage('Correo verificado.');
        context.go(Routes.home);
      }
    }

    Future<void> resend() async {
      resending.value = true;
      final ok = await notifier.resendConfirmationCode();
      if (!context.mounted) return;
      resending.value = false;
      if (ok) showMessage('Te enviamos un código nuevo.');
    }

    final busy = verifying.value || resending.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Verifica tu correo')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.formHorizontal),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enviamos un código de 6 dígitos a ${email ?? 'tu correo'}. '
                    'Al verificarlo podrás entrar tanto con tu contraseña '
                    'como con Google.',
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
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    validator: (value) =>
                        RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                            ? null
                            : 'Escribe el código de 6 dígitos',
                    onFieldSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: Spacing.formFieldSpacing),
                  LoadingButton(
                    isLoading: verifying.value,
                    onPressed: busy ? null : submit,
                    label: 'Verificar',
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextButton(
                    onPressed: busy ? null : resend,
                    child: const Text('Reenviar código'),
                  ),
                  TextButton(
                    onPressed: busy ? null : () => context.go(Routes.home),
                    child: const Text('Más tarde'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
