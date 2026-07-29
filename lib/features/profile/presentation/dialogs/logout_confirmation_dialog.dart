import 'package:flutter/material.dart';

Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('profile-logout-confirmation-dialog'),
        icon: const Icon(Icons.logout_rounded, size: 44),
        title: const Text('Log Keluar?'),
        content: const Text(
          'Anda perlu log masuk semula '
          'untuk menggunakan aplikasi.',
        ),
        actions: [
          TextButton(
            key: const Key('profile-logout-cancel-button'),
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            key: const Key('profile-logout-confirm-button'),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Keluar'),
          ),
        ],
      );
    },
  );

  return shouldLogout ?? false;
}
