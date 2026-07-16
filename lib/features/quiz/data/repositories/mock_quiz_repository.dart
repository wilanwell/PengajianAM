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
      options: const [
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
      options: const [
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
      options: const [
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
      options: const [
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
      options: const [
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
      options: const [
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
      options: const [
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
      options: const [
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
      options: const [
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
      options: const [
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
    QuizQuestion(
      id: 'mock-11',
      topicId: 'mock',
      questionText: 'Apakah fungsi utama badan eksekutif?',
      options: const [
        'Melaksanakan dasar dan undang-undang',
        'Mentafsir Perlembagaan sahaja',
        'Mengendalikan semua pilihan raya',
        'Menggubal keputusan mahkamah',
      ],
      correctOptionIndex: 0,
      explanation:
          'Badan eksekutif bertanggungjawab melaksanakan '
          'dasar dan undang-undang dalam pentadbiran negara.',
    ),
    QuizQuestion(
      id: 'mock-12',
      topicId: 'mock',
      questionText: 'Apakah peranan utama badan kehakiman?',
      options: const [
        'Menyediakan perkhidmatan perbandaran',
        'Melaksanakan dasar kerajaan',
        'Mentafsir dan menguatkuasakan undang-undang',
        'Mengurus kempen pilihan raya',
      ],
      correctOptionIndex: 2,
      explanation:
          'Badan kehakiman mentafsir undang-undang dan '
          'menyelesaikan pertikaian berdasarkan undang-undang.',
    ),
    QuizQuestion(
      id: 'mock-13',
      topicId: 'mock',
      questionText: 'Apakah maksud akauntabiliti dalam pentadbiran awam?',
      options: const [
        'Pegawai bebas daripada sebarang tanggungjawab',
        'Keputusan pentadbiran tidak perlu dijelaskan',
        'Pegawai bertanggungjawab terhadap tindakan dan keputusan',
        'Maklumat kerajaan mesti dirahsiakan sepenuhnya',
      ],
      correctOptionIndex: 2,
      explanation:
          'Akauntabiliti bermaksud seseorang pegawai atau '
          'organisasi bertanggungjawab terhadap tindakan dan '
          'keputusan yang dibuat.',
    ),
    QuizQuestion(
      id: 'mock-14',
      topicId: 'mock',
      questionText: 'Apakah tujuan prinsip semak dan imbang?',
      options: const [
        'Memberikan kuasa mutlak kepada satu badan',
        'Mengawal dan menyeimbangkan penggunaan kuasa',
        'Menghapuskan fungsi badan perundangan',
        'Mengurangkan peranan undang-undang',
      ],
      correctOptionIndex: 1,
      explanation:
          'Prinsip semak dan imbang mengelakkan sesuatu badan '
          'daripada menggunakan kuasa secara berlebihan.',
    ),
    QuizQuestion(
      id: 'mock-15',
      topicId: 'mock',
      questionText: 'Apakah kepentingan penyertaan rakyat dalam pemerintahan?',
      options: const [
        'Membolehkan rakyat menyumbang kepada proses demokrasi',
        'Menghapuskan tanggungjawab kerajaan',
        'Mengurangkan ketelusan pentadbiran',
        'Menggantikan semua institusi kerajaan',
      ],
      correctOptionIndex: 0,
      explanation:
          'Penyertaan rakyat membolehkan pandangan masyarakat '
          'diambil kira dalam proses demokrasi dan pentadbiran.',
    ),
    QuizQuestion(
      id: 'mock-16',
      topicId: 'mock',
      questionText: 'Apakah tujuan utama perkhidmatan awam?',
      options: const [
        'Memberikan keuntungan kepada pegawai',
        'Melaksanakan dasar dan memberikan perkhidmatan kepada rakyat',
        'Menggantikan fungsi semua syarikat swasta',
        'Mengurus parti politik',
      ],
      correctOptionIndex: 1,
      explanation:
          'Perkhidmatan awam melaksanakan dasar kerajaan dan '
          'menyampaikan perkhidmatan kepada masyarakat.',
    ),
    QuizQuestion(
      id: 'mock-17',
      topicId: 'mock',
      questionText: 'Yang manakah menunjukkan pentadbiran yang telus?',
      options: const [
        'Maklumat keputusan disembunyikan',
        'Proses membuat keputusan boleh diketahui dan disemak',
        'Semua urusan dikendalikan tanpa rekod',
        'Aduan masyarakat tidak diterima',
      ],
      correctOptionIndex: 1,
      explanation:
          'Ketelusan melibatkan proses dan maklumat yang boleh '
          'diketahui, difahami dan disemak oleh pihak berkaitan.',
    ),
    QuizQuestion(
      id: 'mock-18',
      topicId: 'mock',
      questionText: 'Apakah kesan pentadbiran yang cekap?',
      options: const [
        'Sumber digunakan dengan lebih berkesan',
        'Masa penyampaian perkhidmatan bertambah panjang',
        'Aduan masyarakat semakin diabaikan',
        'Kos pentadbiran meningkat tanpa kawalan',
      ],
      correctOptionIndex: 0,
      explanation:
          'Pentadbiran yang cekap menggunakan masa, tenaga dan '
          'sumber dengan berkesan untuk mencapai objektif.',
    ),
    QuizQuestion(
      id: 'mock-19',
      topicId: 'mock',
      questionText: 'Apakah peranan utama Perlembagaan dalam sesebuah negara?',
      options: const [
        'Menetapkan asas pemerintahan dan hak yang berkaitan',
        'Menghapuskan pembahagian kuasa',
        'Menggantikan semua keputusan mahkamah',
        'Memberikan kuasa tanpa had kepada pemerintah',
      ],
      correctOptionIndex: 0,
      explanation:
          'Perlembagaan menjadi asas kepada struktur pemerintahan, '
          'pembahagian kuasa dan perlindungan hak.',
    ),
    QuizQuestion(
      id: 'mock-20',
      topicId: 'mock',
      questionText: 'Pilih susunan umum proses membuat keputusan yang logik.',
      options: const [
        'Kenal pasti masalah, kumpul maklumat, nilai pilihan, buat keputusan',
        'Buat keputusan, kenal pasti masalah, nilai pilihan, kumpul maklumat',
        'Nilai pilihan, buat keputusan, kumpul maklumat, kenal pasti masalah',
        'Kumpul maklumat, buat keputusan, kenal pasti masalah, nilai pilihan',
      ],
      correctOptionIndex: 0,
      explanation:
          'Proses yang logik bermula dengan mengenal pasti masalah, '
          'diikuti pengumpulan maklumat, penilaian pilihan dan '
          'pembuatan keputusan.',
      shuffleOptions: false,
    ),
  ]);

  @override
  Future<List<QuizQuestion>> getQuestions({
    required String topicId,
    required int limit,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (limit <= 0) {
      return const [];
    }

    final resolvedLimit = limit > _questionBank.length
        ? _questionBank.length
        : limit;

    final selectedQuestions = _questionBank
        .take(resolvedLimit)
        .map((question) => question.copyWith(topicId: topicId))
        .toList(growable: false);

    return List<QuizQuestion>.unmodifiable(selectedQuestions);
  }
}
