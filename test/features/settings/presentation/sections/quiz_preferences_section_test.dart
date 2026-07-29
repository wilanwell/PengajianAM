import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/domain/entities/app_settings.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/sections/quiz_preferences_section.dart';

void main() {
  testWidgets('memaparkan tetapan kuiz yang sedang dipilih', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizPreferencesSection(
            settings: const AppSettings(
              defaultQuizMode: QuizMode.practice,
              defaultQuestionCount: 10,
            ),
            onModeSelected: (_) async {},
            onQuestionCountSelected: (_) async {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('settings-quiz-preferences-section')),
      findsOneWidget,
    );

    expect(find.text('Mode Kuiz Lalai'), findsOneWidget);

    expect(find.text('Practice Mode'), findsOneWidget);

    expect(find.text('Exam Mode'), findsOneWidget);

    expect(find.text('10 soalan'), findsOneWidget);

    expect(find.text('20 soalan'), findsOneWidget);

    final tenQuestionChip = tester.widget<ChoiceChip>(
      find.byKey(const Key('settings-question-count-10')),
    );

    final twentyQuestionChip = tester.widget<ChoiceChip>(
      find.byKey(const Key('settings-question-count-20')),
    );

    expect(tenQuestionChip.selected, isTrue);

    expect(twentyQuestionChip.selected, isFalse);
  });

  testWidgets('menghantar callback apabila mode dan jumlah soalan dipilih', (
    tester,
  ) async {
    QuizMode? selectedMode;
    int? selectedQuestionCount;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizPreferencesSection(
            settings: const AppSettings(
              defaultQuizMode: QuizMode.practice,
              defaultQuestionCount: 10,
            ),
            onModeSelected: (mode) async {
              selectedMode = mode;
            },
            onQuestionCountSelected: (questionCount) async {
              selectedQuestionCount = questionCount;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-mode-exam')));

    await tester.pump();

    expect(selectedMode, QuizMode.exam);

    await tester.tap(find.byKey(const Key('settings-question-count-20')));

    await tester.pump();

    expect(selectedQuestionCount, 20);
  });
}
