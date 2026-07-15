import '../../domain/entities/quiz_question.dart';
import '../../domain/repositories/quiz_repository.dart';

class MockQuizRepository implements QuizRepository {
  const MockQuizRepository();

  static final List<QuizQuestion>
  _questionBank = List<QuizQuestion>.unmodifiable([
    QuizQuestion(
      id: 'mock-01',
      topicId: 'mock',
      questionText: 'Apakah ciri utama sesebuah negara yang berdaulat?',
      options: [
        'Mempunyai penduduk yang ramai',
        'Bebas mentadbir tanpa dikawal kuasa luar',
        'Mempunyai wilayah yang sangat luas',
        'Menggunakan satu bahasa sahaja',
      ],
      correctOptionIndex: 1,
      explanation:
          'Negara berdaulat mempunyai kuasa tertinggi untuk '
          'mengurus pentadbirannya tanpa dikawal oleh kuasa luar.',
    ),
    QuizQuestion(
      id: 'mock-02',
      topicId: 'mock',
      questionText: 'Apakah undang-undang tertinggi di Malaysia?',
      options: [
        'Perlembagaan Persekutuan',
        'Peraturan kerajaan tempatan',
        'Pekeliling kementerian',
        'Perlembagaan parti politik',
      ],
      correctOptionIndex: 0,
      explanation:
          'Perlembagaan Persekutuan merupakan undang-undang '
          'tertinggi negara.',
    ),
    QuizQuestion(
      id: 'mock-03',
      topicId: 'mock',
      questionText: 'Antara berikut, yang manakah prinsip tadbir urus baik?',
      options: [
        'Kerahsiaan tanpa batas',
        'Pemusatan semua kuasa',
        'Ketelusan dan akauntabiliti',
        'Mengurangkan penglibatan rakyat',
      ],
      correctOptionIndex: 2,
      explanation:
          'Tadbir urus baik menekankan ketelusan, '
          'akauntabiliti dan keberkesanan pentadbiran.',
    ),
    QuizQuestion(
      id: 'mock-04',
      topicId: 'mock',
      questionText: 'Badan manakah yang menggubal undang-undang Persekutuan?',
      options: [
        'Parlimen',
        'Mahkamah',
        'Kabinet sahaja',
        'Pihak berkuasa tempatan',
      ],
      correctOptionIndex: 0,
      explanation:
          'Parlimen ialah badan perundangan yang menggubal '
          'undang-undang pada peringkat Persekutuan.',
    ),
    QuizQuestion(
      id: 'mock-05',
      topicId: 'mock',
      questionText: 'Apakah tujuan utama pengasingan kuasa?',
      options: [
        'Menghapuskan badan kehakiman',
        'Mengelakkan pemusatan dan penyalahgunaan kuasa',
        'Memberi semua kuasa kepada eksekutif',
        'Mengurangkan fungsi Parlimen',
      ],
      correctOptionIndex: 1,
      explanation:
          'Pengasingan kuasa membantu mewujudkan semak dan '
          'imbang antara institusi pemerintahan.',
    ),
    QuizQuestion(
      id: 'mock-06',
      topicId: 'mock',
      questionText:
          'Pilihan raya membolehkan rakyat melakukan perkara berikut:',
      options: [
        'Memilih wakil untuk membentuk kerajaan',
        'Menggubal undang-undang secara langsung',
        'Melantik semua hakim',
        'Menghapuskan Perlembagaan',
      ],
      correctOptionIndex: 0,
      explanation:
          'Melalui pilihan raya, rakyat memilih wakil untuk '
          'mewakili mereka dalam sistem pemerintahan.',
    ),
    QuizQuestion(
      id: 'mock-07',
      topicId: 'mock',
      questionText: 'Apakah fungsi utama kerajaan tempatan?',
      options: [
        'Mengurus hubungan luar negara',
        'Mengawal angkatan tentera',
        'Menyediakan perkhidmatan di kawasan setempat',
        'Menggubal Perlembagaan Persekutuan',
      ],
      correctOptionIndex: 2,
      explanation:
          'Kerajaan tempatan menyediakan dan mengurus '
          'perkhidmatan dalam kawasan pentadbirannya.',
    ),
    QuizQuestion(
      id: 'mock-08',
      topicId: 'mock',
      questionText:
          'Perjanjian Malaysia 1963 berkaitan dengan perkara berikut:',
      options: [
        'Pembentukan Malaysia',
        'Pembubaran Parlimen',
        'Pembentukan pilihan raya pertama',
        'Penubuhan kerajaan tempatan',
      ],
      correctOptionIndex: 0,
      explanation:
          'Perjanjian Malaysia 1963 merupakan dokumen penting '
          'dalam proses pembentukan Malaysia.',
    ),
    QuizQuestion(
      id: 'mock-09',
      topicId: 'mock',
      questionText: 'Apakah maksud kedaulatan undang-undang?',
      options: [
        'Undang-undang hanya terpakai kepada rakyat',
        'Semua pihak tertakluk kepada undang-undang',
        'Pemimpin tidak terikat kepada undang-undang',
        'Undang-undang boleh diketepikan pada bila-bila masa',
      ],
      correctOptionIndex: 1,
      explanation:
          'Kedaulatan undang-undang bermaksud semua pihak '
          'tertakluk kepada undang-undang yang berkuat kuasa.',
    ),
    QuizQuestion(
      id: 'mock-10',
      topicId: 'mock',
      questionText: 'Mengapakah perpaduan penting kepada negara?',
      options: [
        'Mengurangkan kerjasama masyarakat',
        'Meningkatkan konflik antara kaum',
        'Mewujudkan kestabilan dan keharmonian',
        'Menghapuskan kepelbagaian budaya',
      ],
      correctOptionIndex: 2,
      explanation:
          'Perpaduan menyumbang kepada kestabilan, keharmonian '
          'dan kemajuan negara.',
    ),
  ]);

  @override
  Future<List<QuizQuestion>> getQuestions({
    required String topicId,
    required int limit,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final questions = <QuizQuestion>[];

    for (var index = 0; index < limit; index++) {
      final sourceQuestion = _questionBank[index % _questionBank.length];

      final cycle = index ~/ _questionBank.length;

      questions.add(
        sourceQuestion.copyWith(
          id: '${sourceQuestion.id}-${cycle + 1}',
          topicId: topicId,
        ),
      );
    }

    return List<QuizQuestion>.unmodifiable(questions);
  }
}
