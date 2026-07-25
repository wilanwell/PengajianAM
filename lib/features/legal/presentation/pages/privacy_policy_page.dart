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
                    '| Berkuat kuasa '
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
                  'akaun, leaderboard dan '
                  'keselamatan aplikasi.',
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
                      'XP mingguan dan bulanan yang '
                      'dikira daripada percubaan kuiz '
                      'dalam tempoh semasa.',
                ),
                LegalBullet(
                  text:
                      'Pilihan penyertaan leaderboard, '
                      'tarikh persetujuan dan versi '
                      'persetujuan yang diterima.',
                ),
                LegalBullet(
                  text:
                      'Nama samaran, ranking dan XP '
                      'tempoh semasa bagi pengguna '
                      'yang memilih untuk menyertai '
                      'leaderboard.',
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
                  'Status sambungan Internet boleh '
                  'diperiksa untuk memaparkan amaran '
                  'offline, tetapi tidak digunakan '
                  'untuk menentukan lokasi pengguna.',
                ),
                LegalParagraph(
                  'Pengguna tidak sepatutnya '
                  'memasukkan maklumat sensitif yang '
                  'tidak diperlukan ke dalam nama '
                  'paparan.',
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
                      'pencapaian dan statistik '
                      'pembelajaran.',
                ),
                LegalBullet(
                  text:
                      'Mengira XP mingguan dan '
                      'bulanan berdasarkan tempoh '
                      'semasa.',
                ),
                LegalBullet(
                  text:
                      'Menentukan ranking apabila '
                      'pengguna memberikan '
                      'persetujuan untuk menyertai '
                      'leaderboard.',
                ),
                LegalBullet(
                  text:
                      'Memaparkan sejarah dan '
                      'analitik pembelajaran.',
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
                  'Data akaun dan pembelajaran '
                  'disimpan serta diproses melalui '
                  'Supabase sebagai penyedia '
                  'perkhidmatan backend.',
                ),
                LegalParagraph(
                  'Draft kuiz dan tetapan tertentu '
                  'boleh disimpan secara tempatan '
                  'pada peranti pengguna.',
                ),
                LegalParagraph(
                  'Penyedia perkhidmatan hanya '
                  'digunakan untuk menjalankan '
                  'fungsi teknikal yang diperlukan '
                  'oleh aplikasi.',
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
              title: 'Leaderboard dan Persetujuan',
              children: [
                LegalParagraph(
                  'Penyertaan leaderboard adalah '
                  'pilihan. Pengguna tidak dimasukkan '
                  'ke dalam ranking secara '
                  'automatik.',
                ),
                LegalParagraph(
                  'Pengguna masih boleh melihat '
                  'leaderboard tanpa menyertainya.',
                ),
                LegalParagraph(
                  'Apabila pengguna memilih untuk '
                  'menyertai, XP mingguan dan '
                  'bulanan bagi tempoh semasa akan '
                  'digunakan untuk menentukan '
                  'ranking.',
                ),
                LegalParagraph(
                  'Pengguna lain hanya melihat nama '
                  'samaran seperti Pelajar-A1B2. '
                  'Nama paparan sebenar hanya '
                  'ditunjukkan kepada pemilik akaun '
                  'sendiri.',
                ),
                LegalParagraph(
                  'Alamat e-mel, kata laluan, token '
                  'authentication dan maklumat log '
                  'masuk tidak dipaparkan pada '
                  'leaderboard.',
                ),
                LegalParagraph(
                  'Pengguna boleh berhenti menyertai '
                  'pada bila-bila masa melalui '
                  'halaman Tetapan.',
                ),
                LegalParagraph(
                  'Berhenti menyertai akan '
                  'mengeluarkan pengguna daripada '
                  'ranking. Tindakan tersebut tidak '
                  'memadam XP, progress, sejarah '
                  'kuiz atau analitik pembelajaran.',
                ),
                LegalParagraph(
                  'Perubahan penyertaan boleh '
                  'direkodkan sebagai event '
                  'persetujuan bagi memastikan '
                  'pilihan pengguna dapat diaudit.',
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
                  'Operasi sensitif seperti '
                  'pengesahan penghapusan akaun, '
                  'pengiraan keputusan kuiz dan '
                  'pengiraan ranking dijalankan pada '
                  'bahagian server.',
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
                  'untuk menyediakan akaun dan '
                  'fungsi aplikasi, atau selama '
                  'diperlukan untuk memenuhi '
                  'kewajipan yang sah.',
                ),
                LegalParagraph(
                  'Fungsi Reset Data Pembelajaran '
                  'memadam progress, sejarah, '
                  'analitik dan draft, tetapi tidak '
                  'memadam akaun authentication.',
                ),
                LegalParagraph(
                  'Reset Data Pembelajaran tidak '
                  'mengubah pilihan privasi '
                  'leaderboard kerana pilihan '
                  'tersebut diurus secara '
                  'berasingan.',
                ),
                LegalParagraph(
                  'Penghapusan akaun akan memadam '
                  'profil, progress, sejarah kuiz, '
                  'sesi kuiz, preference '
                  'leaderboard dan rekod '
                  'persetujuan yang dikaitkan dengan '
                  'akaun.',
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
                      'Memilih untuk menyertai atau '
                      'berhenti menyertai '
                      'leaderboard.',
                ),
                LegalBullet(
                  text:
                      'Melihat leaderboard tanpa '
                      'mempunyai ranking sendiri.',
                ),
                LegalBullet(
                  text:
                      'Meminta akses, pembetulan atau '
                      'penghapusan data peribadi.',
                ),
                LegalBullet(
                  text:
                      'Memadam akaun dan data '
                      'berkaitan melalui aplikasi.',
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
                  'STPM. Pengguna yang masih di '
                  'bawah umur dewasa digalakkan '
                  'menggunakan aplikasi dengan '
                  'pengetahuan ibu bapa atau '
                  'penjaga.',
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
                  'apabila ciri, penyedia '
                  'perkhidmatan atau amalan '
                  'pemprosesan data berubah.',
                ),
                LegalParagraph(
                  'Tarikh berkuat kuasa dan nombor '
                  'versi akan dikemas kini apabila '
                  'terdapat perubahan penting.',
                ),
                LegalParagraph(
                  'Persetujuan baharu boleh diminta '
                  'sekiranya perubahan penting '
                  'menjejaskan cara data leaderboard '
                  'digunakan.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            LegalSectionCard(
              number: '13',
              title: 'Hubungi Kami',
              children: const [
                LegalParagraph(
                  'Pertanyaan privasi, permintaan '
                  'akses atau permintaan '
                  'penghapusan data boleh dihantar '
                  'kepada:',
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
