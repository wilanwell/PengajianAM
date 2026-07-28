import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/entities/quiz_session_source.dart';

/// Tindakan yang boleh dipilih apabila aplikasi menemui
/// draft kuiz atau latihan yang masih belum selesai.
enum ExistingQuizDraftAction { cancel, resume, startNew }

/// Memaparkan dialog apabila aplikasi gagal memeriksa
/// kesahihan draft yang tersimpan.
///
/// Draft tidak dipadamkan apabila pemeriksaan gagal.
Future<void> showQuizDraftVerificationFailure({
  required BuildContext context,
  required String message,
  required String retryActionLabel,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        icon: const Icon(
          Icons.cloud_off_rounded,
          size: 44,
          color: AppColors.warning,
        ),
        title: const Text('Sesi Tersimpan Tidak Dapat Disahkan'),
        content: Text(
          '$message\n\n'
          'Draft tidak dipadamkan. '
          'Sambungkan peranti kepada Internet '
          'dan $retryActionLabel.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Faham'),
          ),
        ],
      );
    },
  );
}

/// Memaparkan maklumat draft sedia ada sebelum pengguna
/// memulakan kuiz atau latihan yang baharu.
///
/// Pengguna boleh:
/// 1. Membatalkan tindakan.
/// 2. Menyambung sesi lama.
/// 3. Memadam draft lama dan memulakan sesi baharu.
Future<ExistingQuizDraftAction?> showExistingQuizDraftDialog({
  required BuildContext context,
  required QuizDraft draft,
  required String draftTopicTitle,
}) {
  final answeredCount = draft.selectedAnswers.length;
  final currentQuestionNumber = draft.currentQuestionIndex + 1;

  final isMistakeReview = draft.source == QuizSessionSource.mistakeReview;

  final sessionLabel = isMistakeReview ? 'latihan semula' : 'kuiz';

  final resumeButtonLabel = isMistakeReview
      ? 'Sambung Latihan'
      : 'Sambung Kuiz';

  return showDialog<ExistingQuizDraftAction>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        icon: const Icon(
          Icons.history_rounded,
          size: 44,
          color: AppColors.primary,
        ),
        title: Text('${draft.source.label} Belum Selesai'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terdapat sesi $sessionLabel yang telah '
                'disimpan pada peranti ini.',
              ),
              const SizedBox(height: AppSpacing.md),
              _DraftInformationRow(label: 'Topik', value: draftTopicTitle),
              const SizedBox(height: AppSpacing.xs),
              _DraftInformationRow(
                label: 'Jenis',
                value: isMistakeReview ? draft.source.label : draft.mode.label,
              ),
              const SizedBox(height: AppSpacing.xs),
              _DraftInformationRow(
                label: 'Kemajuan',
                value:
                    '$answeredCount daripada '
                    '${draft.questionCount} dijawab',
              ),
              const SizedBox(height: AppSpacing.xs),
              _DraftInformationRow(
                label: 'Kedudukan',
                value: 'Soalan $currentQuestionNumber',
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Mula Baharu akan memadamkan semua '
                'jawapan daripada sesi tersimpan.',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(ExistingQuizDraftAction.cancel);
            },
            child: const Text('Batal'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(ExistingQuizDraftAction.startNew);
            },
            child: const Text('Mula Baharu'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop(ExistingQuizDraftAction.resume);
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(resumeButtonLabel),
          ),
        ],
      );
    },
  );
}

class _DraftInformationRow extends StatelessWidget {
  const _DraftInformationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
