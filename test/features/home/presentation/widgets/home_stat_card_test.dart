import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/app/theme/app_colors.dart';
import 'package:pengajian_am_stpm_objektif/features/home/presentation/widgets/home_stat_card.dart';

void main() {
  testWidgets('HomeStatCard menjalankan tindakan '
      'apabila ditekan', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              child: HomeStatCard(
                icon: Icons.emoji_events_outlined,
                label: 'Ranking Mingguan',
                value: 'Sertai',
                iconColor: AppColors.bronze,
                iconBackgroundColor: AppColors.warningBackground,
                semanticLabel: 'Sertai leaderboard',
                onTap: () {
                  tapCount++;
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sertai'), findsOneWidget);

    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    await tester.tap(find.text('Sertai'));

    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('HomeStatCard tanpa tindakan tidak '
      'memaparkan chevron', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              child: HomeStatCard(
                icon: Icons.quiz_outlined,
                label: 'Kuiz Disiapkan',
                value: '4',
                iconColor: AppColors.actionBlue,
                iconBackgroundColor: AppColors.softBlue,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('4'), findsOneWidget);

    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });
}
