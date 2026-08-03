import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/quiz_session_source.dart';
import '../controllers/quiz_session_state.dart';

enum QuizExitAction { continueQuiz, saveAndExit, discardAndExit }

abstract final class QuizQuestionDialogs {
  static Future<QuizExitAction?> showExitDialog({
    required BuildContext context,
    required QuizSessionState state,
  }) {
    final sessionLabel = state.source == QuizSessionSource.mistakeReview
        ? 'latihan semula'
        : 'kuiz';

    return showDialog<QuizExitAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('quiz-exit-dialog'),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 42,
          ),
          title: Text('Keluar ${state.source.label}?'),
          content: Text(
            'Kemajuan $sessionLabel disimpan secara '
            'automatik.\n\n'
            '${state.answeredQuestionCount} daripada '
            '${state.questions.length} soalan '
            'telah dijawab.\n'
            '${state.unansweredQuestionCount} '
            'soalan belum dijawab.\n'
            '${state.flaggedQuestionCount} '
            'soalan ditanda.\n\n'
            'Pilih Simpan & Keluar untuk '
            'menyambung kuiz ini kemudian.',
          ),
          actions: [
            TextButton(
              key: const Key('quiz-exit-continue-button'),
              onPressed: () {
                Navigator.of(dialogContext).pop(QuizExitAction.continueQuiz);
              },
              child: Text('Teruskan ${state.source.label}'),
            ),
            OutlinedButton.icon(
              key: const Key('quiz-exit-discard-button'),
              onPressed: () {
                Navigator.of(dialogContext).pop(QuizExitAction.discardAndExit);
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Buang Sesi'),
            ),
            FilledButton.icon(
              key: const Key('quiz-exit-save-button'),
              onPressed: () {
                Navigator.of(dialogContext).pop(QuizExitAction.saveAndExit);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan & Keluar'),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> showSubmitDialog({
    required BuildContext context,
    required QuizSessionState state,
  }) async {
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('quiz-submit-dialog'),
          title: const Text('Hantar Jawapan?'),
          content: Text(
            '${state.answeredQuestionCount} daripada '
            '${state.questions.length} soalan '
            'telah dijawab.\n\n'
            '${state.unansweredQuestionCount} soalan '
            'masih belum dijawab.\n\n'
            '${state.flaggedQuestionCount} soalan '
            'telah ditanda.',
          ),
          actions: [
            TextButton(
              key: const Key('quiz-submit-review-button'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Semak Semula'),
            ),
            FilledButton(
              key: const Key('quiz-submit-confirm-button'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Hantar'),
            ),
          ],
        );
      },
    );

    return shouldSubmit == true;
  }

  static void showSubmittingMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          key: Key('quiz-submitting-snackbar'),
          content: Text(
            'Jawapan sedang dihantar. '
            'Sila tunggu sebentar.',
          ),
        ),
      );
  }
}
