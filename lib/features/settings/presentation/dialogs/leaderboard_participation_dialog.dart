import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

Future<bool> showLeaderboardParticipationDialog(
  BuildContext context, {
  required bool optIn,
}) async {
  final shouldUpdate = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      if (optIn) {
        return AlertDialog(
          key: const Key('settings-leaderboard-opt-in-dialog'),
          icon: const Icon(
            Icons.emoji_events_outlined,
            color: AppColors.actionBlue,
            size: 44,
          ),
          title: const Text('Sertai Leaderboard?'),
          content: const Text(
            'Apabila anda menyertai '
            'leaderboard:\n\n'
            '\u2022 XP mingguan dan bulanan '
            'anda akan digunakan untuk '
            'menentukan ranking.\n'
            '\u2022 Pengguna lain hanya akan '
            'melihat nama samaran seperti '
            'Pelajar-A1B2.\n'
            '\u2022 Nama paparan sebenar anda '
            'hanya ditunjukkan kepada anda '
            'sendiri.\n'
            '\u2022 Anda boleh berhenti '
            'menyertai pada bila-bila masa.\n\n'
            'Dengan memilih “Saya Setuju & '
            'Sertai”, anda memberikan '
            'persetujuan untuk XP tempoh '
            'semasa digunakan dalam '
            'leaderboard.',
          ),
          actions: [
            TextButton(
              key: const Key('settings-leaderboard-opt-in-cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              key: const Key('settings-leaderboard-opt-in-confirm'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Saya Setuju & Sertai'),
            ),
          ],
        );
      }

      return AlertDialog(
        key: const Key('settings-leaderboard-opt-out-dialog'),
        icon: const Icon(
          Icons.privacy_tip_outlined,
          color: AppColors.primary,
          size: 44,
        ),
        title: const Text('Berhenti Menyertai?'),
        content: const Text(
          'Anda akan dikeluarkan daripada '
          'leaderboard.\n\n'
          'XP, progress, sejarah kuiz dan '
          'analitik pembelajaran anda tidak '
          'akan dipadamkan.\n\n'
          'Anda masih boleh melihat '
          'leaderboard tanpa mempunyai '
          'ranking sendiri.',
        ),
        actions: [
          TextButton(
            key: const Key('settings-leaderboard-opt-out-cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('settings-leaderboard-opt-out-confirm'),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Berhenti Menyertai'),
          ),
        ],
      );
    },
  );

  return shouldUpdate ?? false;
}
