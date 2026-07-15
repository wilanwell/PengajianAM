import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/study_topic.dart';
import 'topics_state.dart';

final topicsControllerProvider =
    NotifierProvider<TopicsController, TopicsState>(TopicsController.new);

class TopicsController extends Notifier<TopicsState> {
  @override
  TopicsState build() {
    return const TopicsState();
  }

  Future<void> loadTopics({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        (state.status == TopicsStatus.loading ||
            state.status == TopicsStatus.success)) {
      return;
    }

    state = state.copyWith(
      status: TopicsStatus.loading,
      clearErrorMessage: true,
    );

    try {
      // Temporary simulation of a remote database request.
      // This will later be replaced by TopicsRepository and Supabase.
      await Future<void>.delayed(const Duration(milliseconds: 450));

      const topics = <StudyTopic>[
        StudyTopic(
          id: 'topic-s1-01',
          code: 'S1-01',
          semester: 1,
          title: 'Kemahiran Insaniah',
          description:
              'Kemahiran mencari maklumat, menganalisis data, '
              'menyelesaikan masalah dan membuat keputusan.',
          questionCount: 20,
          completedQuestionCount: 6,
        ),
        StudyTopic(
          id: 'topic-s1-02',
          code: 'S1-02',
          semester: 1,
          title: 'Negara Berdaulat',
          description:
              'Konsep, ciri dan kepentingan sesebuah negara '
              'yang berdaulat.',
          questionCount: 15,
          completedQuestionCount: 15,
        ),
        StudyTopic(
          id: 'topic-s1-03',
          code: 'S1-03',
          semester: 1,
          title: 'Perlembagaan Persekutuan',
          description:
              'Pembentukan, keluhuran, pindaan dan peruntukan '
              'utama Perlembagaan Persekutuan.',
          questionCount: 35,
          completedQuestionCount: 14,
        ),
        StudyTopic(
          id: 'topic-s1-04',
          code: 'S1-04',
          semester: 1,
          title: 'Perjanjian Malaysia 1963',
          description:
              'Latar belakang, kandungan dan kepentingan '
              'Perjanjian Malaysia 1963.',
          questionCount: 15,
          completedQuestionCount: 0,
        ),
        StudyTopic(
          id: 'topic-s1-05',
          code: 'S1-05',
          semester: 1,
          title: 'Tadbir Urus Baik',
          description:
              'Konsep, prinsip, kepentingan dan cabaran '
              'pelaksanaan tadbir urus yang baik.',
          questionCount: 25,
          completedQuestionCount: 5,
        ),
        StudyTopic(
          id: 'topic-s1-06',
          code: 'S1-06',
          semester: 1,
          title: 'Sistem dan Struktur Pemerintahan',
          description:
              'Badan perundangan, eksekutif, kehakiman dan '
              'struktur pentadbiran Malaysia.',
          questionCount: 25,
          completedQuestionCount: 0,
        ),
        StudyTopic(
          id: 'topic-s1-07',
          code: 'S1-07',
          semester: 1,
          title: 'Kedaulatan Malaysia',
          description:
              'Isu, cabaran dan strategi mempertahankan '
              'kedaulatan serta perpaduan negara.',
          questionCount: 15,
          completedQuestionCount: 0,
        ),
      ];

      state = const TopicsState(status: TopicsStatus.success, topics: topics);
    } catch (_) {
      state = const TopicsState(
        status: TopicsStatus.failure,
        errorMessage: 'Senarai topik tidak dapat dimuatkan. Sila cuba semula.',
      );
    }
  }

  void searchChanged(String value) {
    state = state.copyWith(searchQuery: value, clearErrorMessage: true);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '', clearErrorMessage: true);
  }

  void filterChanged(TopicProgressFilter filter) {
    state = state.copyWith(filter: filter, clearErrorMessage: true);
  }

  Future<void> refreshTopics() {
    return loadTopics(forceRefresh: true);
  }

  void reset() {
    state = const TopicsState();
  }
}
