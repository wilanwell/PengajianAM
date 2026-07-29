import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/constants/app_disclaimer.dart';
import '../../../../core/constants/support_information.dart';

Future<void> showAboutApplicationDialog(
  BuildContext context, {
  required VoidCallback onTermsOfUseTap,
  required VoidCallback onPrivacyPolicyTap,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('profile-about-application-dialog'),
        titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          0,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          0,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        title: Column(
          children: [
            Semantics(
              image: true,
              label:
                  'Logo Pengajian AM '
                  'STPM Objektif',
              child: Image.asset(
                'assets/branding/'
                'app_logo_full.png',
                key: const Key('profile-about-application-logo'),
                height: 110,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: AppRadius.extraLarge,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 46,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(SupportInformation.appName, textAlign: TextAlign.center),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  SupportInformation.versionLabel,
                  key: const Key('profile-about-version'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Aplikasi latihan objektif '
                'untuk membantu pelajar '
                'mengulang kaji Pengajian AM '
                'STPM.',
              ),
              const SizedBox(height: AppSpacing.md),
              const _AboutInformationRow(
                icon: Icons.person_outline_rounded,
                label: 'Developer/Penerbit',
                value: SupportInformation.developerName,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _AboutInformationRow(
                icon: Icons.email_outlined,
                label: 'E-mel Sokongan',
                value: SupportInformation.supportEmail,
                selectableValue: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: AppSpacing.cardPadding,
                decoration: const BoxDecoration(
                  color: AppColors.warningBackground,
                  borderRadius: AppRadius.medium,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            AppDisclaimer.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppDisclaimer.shortMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('profile-about-terms-button'),
            onPressed: () {
              Navigator.of(dialogContext).pop();

              onTermsOfUseTap();
            },
            child: const Text('Terma Penggunaan'),
          ),
          TextButton(
            key: const Key('profile-about-privacy-button'),
            onPressed: () {
              Navigator.of(dialogContext).pop();

              onPrivacyPolicyTap();
            },
            child: const Text('Dasar Privasi'),
          ),
          FilledButton(
            key: const Key('profile-about-close-button'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Tutup'),
          ),
        ],
      );
    },
  );
}

class _AboutInformationRow extends StatelessWidget {
  const _AboutInformationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.selectableValue = false,
  });

  final IconData icon;

  final String label;

  final String value;

  final bool selectableValue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: AppRadius.medium,
          ),
          child: Icon(icon, size: 21, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              if (selectableValue)
                SelectableText(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
