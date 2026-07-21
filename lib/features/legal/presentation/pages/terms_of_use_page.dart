import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/constants/app_disclaimer.dart';
import '../../../../core/constants/support_information.dart';
import '../widgets/legal_section_card.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Terma Penggunaan')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            Container(
              padding: AppSpacing.largeCardPadding,
              decoration: const BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: AppRadius.extraLarge,
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadius.large,
                    ),
                    child: const Icon(
                      Icons.gavel_outlined,
                      color: AppColors.textOnPrimary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Terma Penggunaan',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    SupportInformation.appName,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Versi '
                    '${SupportInformation.termsVersion} '
                    '• Berkuat kuasa '
                    '${SupportInformation.effectiveDate}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const LegalSectionCard(
              number: '1',
              title: 'Penerimaan Terma',
              children: [
                LegalParagraph(
                  'Dengan mendaftar, log masuk '
                  'atau menggunakan aplikasi ini, '
                  'anda mengakui bahawa anda telah '
                  'membaca dan bersetuju dengan '
                  'Terma Penggunaan ini.',
                ),
                LegalParagraph(
                  'Sekiranya anda tidak bersetuju '
                  'dengan mana-mana bahagian terma '
                  'ini, anda hendaklah berhenti '
                  'menggunakan aplikasi.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '2',
              title: 'Tujuan Aplikasi',
              children: [
                LegalParagraph(
                  'Aplikasi ini disediakan sebagai '
                  'alat latihan dan ulang kaji '
                  'Pengajian AM STPM.',
                ),
                LegalBullet(
                  text:
                      'Aplikasi bukan pengganti guru, '
                      'buku teks, sukatan rasmi atau '
                      'nasihat akademik profesional.',
                ),
                LegalBullet(
                  text:
                      'Keputusan kuiz hanya digunakan '
                      'sebagai petunjuk pembelajaran '
                      'dan bukan keputusan peperiksaan '
                      'rasmi.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '3',
              title: 'Akaun Pengguna',
              children: [
                LegalParagraph(
                  'Sesetengah fungsi memerlukan '
                  'pengguna mendaftar menggunakan '
                  'alamat e-mel yang sah.',
                ),
                LegalBullet(
                  text:
                      'Pengguna bertanggungjawab '
                      'memastikan maklumat akaun '
                      'adalah tepat.',
                ),
                LegalBullet(
                  text:
                      'Pengguna bertanggungjawab '
                      'menjaga kerahsiaan kata laluan.',
                ),
                LegalBullet(
                  text:
                      'Akaun tidak boleh digunakan '
                      'untuk menyamar sebagai orang '
                      'lain atau mengganggu sistem.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '4',
              title: 'Penggunaan yang Dibenarkan',
              children: [
                LegalParagraph(
                  'Pengguna bersetuju menggunakan '
                  'aplikasi secara sah dan untuk '
                  'tujuan pembelajaran.',
                ),
                LegalBullet(
                  text:
                      'Jangan cuba mendapatkan akses '
                      'tanpa kebenaran kepada akaun, '
                      'database atau sistem backend.',
                ),
                LegalBullet(
                  text:
                      'Jangan mengubah, menyalin atau '
                      'mengedar kandungan aplikasi '
                      'secara komersial tanpa '
                      'kebenaran.',
                ),
                LegalBullet(
                  text:
                      'Jangan menggunakan automation '
                      'atau kaedah lain yang boleh '
                      'mengganggu prestasi sistem.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LegalSectionCard(
              number: '5',
              title: 'Penafian Kandungan',
              children: const [
                LegalParagraph(AppDisclaimer.fullMessage),
                LegalParagraph(
                  'Walaupun usaha munasabah dibuat '
                  'untuk memastikan kandungan tepat, '
                  'tiada jaminan bahawa semua soalan, '
                  'penerangan atau maklumat akan '
                  'sentiasa bebas daripada kesilapan.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '6',
              title: 'Progress, XP dan Ranking',
              children: [
                LegalParagraph(
                  'XP, pencapaian, progress, '
                  'analitik dan leaderboard adalah '
                  'ciri pembelajaran serta motivasi.',
                ),
                LegalParagraph(
                  'Nilai tersebut tidak mempunyai '
                  'nilai kewangan dan tidak boleh '
                  'ditukar kepada wang, hadiah atau '
                  'kelayakan akademik rasmi.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '7',
              title: 'Ketersediaan Perkhidmatan',
              children: [
                LegalParagraph(
                  'Sesetengah fungsi memerlukan '
                  'sambungan Internet dan perkhidmatan '
                  'backend pihak ketiga.',
                ),
                LegalParagraph(
                  'Perkhidmatan mungkin tergendala '
                  'sementara kerana penyelenggaraan, '
                  'masalah rangkaian, perubahan '
                  'teknikal atau keadaan di luar '
                  'kawalan developer.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '8',
              title: 'Harta Intelek',
              children: [
                LegalParagraph(
                  'Reka bentuk aplikasi, logo, code '
                  'dan soalan latihan original '
                  'adalah milik developer atau '
                  'digunakan dengan hak yang sah.',
                ),
                LegalParagraph(
                  'Pengguna diberikan hak terhad '
                  'untuk menggunakan aplikasi bagi '
                  'tujuan peribadi dan bukan '
                  'komersial.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '9',
              title: 'Had Tanggungjawab',
              children: [
                LegalParagraph(
                  'Aplikasi disediakan atas dasar '
                  '“sebagaimana adanya”. Developer '
                  'tidak menjamin bahawa penggunaan '
                  'aplikasi akan menghasilkan markah '
                  'atau keputusan peperiksaan '
                  'tertentu.',
                ),
                LegalParagraph(
                  'Setakat yang dibenarkan oleh '
                  'undang-undang, developer tidak '
                  'bertanggungjawab terhadap kerugian '
                  'yang berpunca daripada penggunaan '
                  'atau ketidakupayaan menggunakan '
                  'aplikasi.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '10',
              title: 'Perubahan Terma',
              children: [
                LegalParagraph(
                  'Terma ini boleh dikemas kini '
                  'apabila fungsi, operasi atau '
                  'keperluan undang-undang berubah.',
                ),
                LegalParagraph(
                  'Tarikh berkuat kuasa dan nombor '
                  'versi akan dikemas kini apabila '
                  'terdapat perubahan penting.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LegalSectionCard(
              number: '11',
              title: 'Hubungi Developer',
              children: const [
                LegalParagraph(
                  'Pertanyaan berkaitan penggunaan '
                  'aplikasi boleh dihantar kepada:',
                ),
                LegalContactBox(
                  label: 'Developer/Penerbit',
                  value: SupportInformation.developerName,
                ),
                LegalContactBox(
                  label: 'E-mel sokongan',
                  value: SupportInformation.supportEmail,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
