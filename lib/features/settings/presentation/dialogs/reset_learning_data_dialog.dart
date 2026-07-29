import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

Future<bool> showResetLearningDataDialog(BuildContext context) async {
  final shouldReset = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('settings-reset-confirmation-dialog'),
        icon: const Icon(
          Icons.warning_amber_rounded,
          size: 44,
          color: AppColors.error,
        ),
        title: const Text('Reset Semua Data?'),
        content: const Text(
          'Tindakan ini akan memadam dan '
          'mengembalikan data berikut kepada '
          'nilai asal:\n\n'
          '\u2022 Nama paparan\n'
          '\u2022 XP dan statistik kuiz\n'
          '\u2022 Aktiviti mingguan\n'
          '\u2022 Sejarah kuiz\n'
          '\u2022 Analitik prestasi\n'
          '\u2022 Sesi kuiz belum selesai\n'
          '\u2022 Jawapan draft pada peranti\n'
          '\u2022 Tetapan kuiz lalai\n\n'
          'Akaun log masuk anda tidak akan '
          'dipadamkan.\n\n'
          'Tindakan ini tidak boleh '
          'dibatalkan.',
        ),
        actions: [
          TextButton(
            key: const Key('settings-reset-cancel-button'),
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            key: const Key('settings-reset-confirm-button'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Reset Data'),
          ),
        ],
      );
    },
  );

  return shouldReset ?? false;
}
