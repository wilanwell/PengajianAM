import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/constants/support_information.dart';
import '../widgets/legal_section_card.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dasar Privasi')),
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
                      Icons.privacy_tip_outlined,
                      color: AppColors.textOnPrimary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Dasar Privasi',
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
                    '${SupportInformation.privacyPolicyVersion} '
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
              title: 'Pengenalan',
              children: [
                LegalParagraph(
                  'Dasar Privasi ini menerangkan '
                  'cara data dikumpul, digunakan, '
                  'disimpan dan dilindungi apabila '
                  'anda menggunakan aplikasi.',
                ),
                LegalParagraph(
                  'Pengumpulan data dihadkan kepada '
                  'maklumat yang diperlukan untuk '
                  'menyediakan fungsi pembelajaran, '
                  'akaun dan keselamatan aplikasi.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '2',
              title: 'Data yang Dikumpul',
              children: [
                LegalBullet(
                  text:
                      'Alamat e-mel untuk pendaftaran, '
                      'log masuk, pengesahan akaun dan '
                      'pemulihan kata laluan.',
                ),
                LegalBullet(
                  text:
                      'Nama paparan dan ID akaun '
                      'dalaman.',
                ),
                LegalBullet(
                  text:
                      'Keputusan kuiz, jawapan, '
                      'markah, XP, progress, sejarah '
                      'percubaan dan analitik topik.',
                ),
                LegalBullet(
                  text:
                      'Maklumat leaderboard seperti '
                      'nama paparan, ranking dan XP.',
                ),
                LegalBullet(
                  text:
                      'Tetapan kuiz yang dipilih oleh '
                      'pengguna.',
                ),
                LegalBullet(
                  text:
                      'Draft kuiz dan jawapan belum '
                      'dihantar yang disimpan dalam '
                      'peranti.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '3',
              title: 'Data yang Tidak Diminta',
              children: [
                LegalParagraph(
                  'Versi semasa aplikasi tidak '
                  'meminta akses kepada lokasi tepat, '
                  'senarai kenalan, kamera, mikrofon, '
                  'SMS atau fail peribadi pengguna.',
                ),
                LegalParagraph(
                  'Status sambungan Internet diperiksa '
                  'untuk memaparkan amaran di luar talian (offline), '
                  'tetapi aplikasi tidak menggunakan '
                  'status tersebut untuk menentukan '
                  'lokasi pengguna.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '4',
              title: 'Tujuan Pemprosesan',
              children: [
                LegalBullet(
                  text:
                      'Mendaftarkan dan mengesahkan '
                      'akaun pengguna.',
                ),
                LegalBullet(
                  text:
                      'Menyediakan kuiz dan menyemak '
                      'jawapan pengguna.',
                ),
                LegalBullet(
                  text:
                      'Mengira XP, progress, '
                      'pencapaian dan ranking.',
                ),
                LegalBullet(
                  text:
                      'Memaparkan sejarah dan analitik '
                      'pembelajaran.',
                ),
                LegalBullet(
                  text:
                      'Menyimpan draft supaya kuiz '
                      'boleh disambung semula.',
                ),
                LegalBullet(
                  text:
                      'Mengesan dan menangani masalah '
                      'keselamatan atau penyalahgunaan '
                      'sistem.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '5',
              title: 'Penyimpanan dan Pemprosesan',
              children: [
                LegalParagraph(
                  'Data akaun serta pembelajaran '
                  'disimpan dan diproses melalui '
                  'Supabase sebagai penyedia '
                  'perkhidmatan backend.',
                ),
                LegalParagraph(
                  'Draft kuiz serta tetapan tertentu '
                  'boleh disimpan secara tempatan pada '
                  'peranti pengguna.',
                ),
                LegalParagraph(
                  'Penggunaan penyedia perkhidmatan '
                  'tidak memberikan mereka kebenaran '
                  'untuk menggunakan data bagi tujuan '
                  'mereka sendiri di luar penyediaan '
                  'perkhidmatan tersebut.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '6',
              title: 'Perkongsian Data',
              children: [
                LegalParagraph(
                  'Developer tidak menjual data '
                  'peribadi pengguna.',
                ),
                LegalParagraph(
                  'Data hanya boleh diproses oleh '
                  'penyedia perkhidmatan teknikal '
                  'yang diperlukan untuk operasi '
                  'aplikasi, atau didedahkan apabila '
                  'dikehendaki oleh undang-undang.',
                ),
                LegalParagraph(
                  'Versi semasa aplikasi tidak '
                  'berkongsi data pengguna dengan '
                  'pengiklan untuk personalized '
                  'advertising.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '7',
              title: 'Leaderboard',
              children: [
                LegalParagraph(
                  'Leaderboard boleh memaparkan nama '
                  'paparan, XP dan kedudukan pengguna '
                  'kepada pengguna aplikasi yang '
                  'telah log masuk.',
                ),
                LegalParagraph(
                  'Alamat e-mel, kata laluan dan '
                  'maklumat authentication tidak '
                  'dipaparkan pada leaderboard.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '8',
              title: 'Keselamatan Data',
              children: [
                LegalParagraph(
                  'Langkah teknikal dan organisasi '
                  'yang munasabah digunakan untuk '
                  'mengurangkan risiko akses tanpa '
                  'kebenaran, kehilangan, perubahan '
                  'atau penyalahgunaan data.',
                ),
                LegalParagraph(
                  'Walau bagaimanapun, tiada sistem '
                  'elektronik atau penghantaran data '
                  'boleh dijamin selamat sepenuhnya.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '9',
              title: 'Penyimpanan dan Penghapusan',
              children: [
                LegalParagraph(
                  'Data disimpan selama diperlukan '
                  'untuk menyediakan akaun dan fungsi '
                  'aplikasi, atau selama diperlukan '
                  'untuk memenuhi kewajipan yang sah.',
                ),
                LegalParagraph(
                  'Fungsi Reset Data Pembelajaran '
                  'memadam progress, sejarah, '
                  'analitik dan draft, tetapi tidak '
                  'memadam akaun authentication.',
                ),
                LegalParagraph(
                  'Permintaan penghapusan akaun dan '
                  'data berkaitan boleh dihantar '
                  'kepada e-mel privasi yang '
                  'dinyatakan di bawah.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '10',
              title: 'Pilihan dan Hak Pengguna',
              children: [
                LegalBullet(text: 'Mengemas kini nama paparan.'),
                LegalBullet(text: 'Mereset data pembelajaran.'),
                LegalBullet(
                  text:
                      'Meminta akses, pembetulan atau '
                      'penghapusan data peribadi.',
                ),
                LegalBullet(
                  text:
                      'Berhenti menggunakan aplikasi '
                      'pada bila-bila masa.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '11',
              title: 'Pengguna Muda',
              children: [
                LegalParagraph(
                  'Aplikasi direka untuk pelajar '
                  'STPM. Pengguna yang masih di bawah '
                  'umur dewasa digalakkan menggunakan '
                  'aplikasi dengan pengetahuan ibu '
                  'bapa atau penjaga.',
                ),
                LegalParagraph(
                  'Pengguna tidak perlu memberikan '
                  'maklumat peribadi tambahan selain '
                  'maklumat yang diperlukan untuk '
                  'akaun dan pembelajaran.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const LegalSectionCard(
              number: '12',
              title: 'Perubahan Dasar Privasi',
              children: [
                LegalParagraph(
                  'Dasar ini boleh dikemas kini '
                  'apabila ciri, penyedia perkhidmatan '
                  'atau amalan pemprosesan data '
                  'berubah.',
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
              number: '13',
              title: 'Hubungi Kami',
              children: const [
                LegalParagraph(
                  'Pertanyaan, permintaan akses atau '
                  'permintaan penghapusan data boleh '
                  'dihantar kepada:',
                ),
                LegalContactBox(
                  label: 'Developer/Penerbit',
                  value: SupportInformation.developerName,
                ),
                LegalContactBox(
                  label: 'E-mel privasi',
                  value: SupportInformation.privacyEmail,
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
