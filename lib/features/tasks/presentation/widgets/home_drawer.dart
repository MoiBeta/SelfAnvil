import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/auth/presentation/widgets/set_password_dialog.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _DrawerAction { home, verifyEmail, addPassword, logout }

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    // Closing the drawer disposes this widget.
    final container = ProviderScope.containerOf(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    Navigator.of(context).pop();
    // While the session is valid: save the pending changes.
    await container.read(homeProvider.notifier).flushPendingChanges();
    // The router and the tasks provider react to the session ending.
    await container.read(authNotifierProvider.notifier).logout();
  }

  void _openVerifyEmail(BuildContext context) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.pushNamed(Routes.verifyEmail);
  }

  void _openSetPassword(BuildContext context) {
    // Closing the drawer disposes this widget: show the dialog from the
    // navigator, which stays.
    final navigator = Navigator.of(context);
    navigator.pop();
    showDialog<void>(
      context: navigator.context,
      builder: (_) => const SetPasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final credentials = ref.watch(authNotifierProvider).value?.credentials;

    final actions = [
      _DrawerAction.home,
      if (credentials?.isEmailConfirmed == false) _DrawerAction.verifyEmail,
      if (credentials?.hasPassword == false) _DrawerAction.addPassword,
      _DrawerAction.logout,
    ];

    return NavigationDrawer(
      selectedIndex: 0,
      onDestinationSelected: (index) => switch (actions[index]) {
        _DrawerAction.home => Navigator.of(context).pop(),
        _DrawerAction.verifyEmail => _openVerifyEmail(context),
        _DrawerAction.addPassword => _openSetPassword(context),
        _DrawerAction.logout => _logout(context),
      },
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
          ),
          child: Text(
            'SelfAnvil',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Inicio'),
        ),
        if (actions.contains(_DrawerAction.verifyEmail))
          const NavigationDrawerDestination(
            icon: Icon(Icons.mark_email_unread_outlined),
            selectedIcon: Icon(Icons.mark_email_unread),
            label: Text('Verificar correo'),
          ),
        if (actions.contains(_DrawerAction.addPassword))
          const NavigationDrawerDestination(
            icon: Icon(Icons.password_outlined),
            selectedIcon: Icon(Icons.password),
            label: Text('Crear contraseña'),
          ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.logout_outlined),
          selectedIcon: Icon(Icons.logout),
          label: Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
