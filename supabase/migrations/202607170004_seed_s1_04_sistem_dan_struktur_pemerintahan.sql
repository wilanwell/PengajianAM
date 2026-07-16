begin;

-- =========================================================
-- S1-04 SISTEM DAN STRUKTUR PEMERINTAHAN
--
-- Skop:
-- 1. Demokrasi Berparlimen dan Raja Berperlembagaan
-- 2. Yang di-Pertuan Agong
-- 3. Majlis Raja-Raja
-- 4. Badan Perundangan
-- 5. Badan Eksekutif
-- 6. Badan Kehakiman
-- 7. Institusi utama negara
--
-- Semua soalan ditulis secara original.
-- =========================================================

insert into public.questions (
  id,
  topic_id,
  question_text,
  options,
  shuffle_options,
  sort_order,
  is_active
)
values
  (
    's1-04-q01',
    'topic-s1-04',
    'Apakah sistem pemerintahan yang diamalkan oleh Malaysia?',
    jsonb_build_array(
      'Sistem republik berpresiden',
      'Sistem monarki mutlak',
      'Sistem demokrasi berparlimen di bawah Raja Berperlembagaan',
      'Sistem pemerintahan tentera'
    ),
    true,
    1,
    true
  ),
  (
    's1-04-q02',
    'topic-s1-04',
    'Pernyataan manakah yang paling tepat tentang kedudukan Yang di-Pertuan Agong dan Perdana Menteri?',
    jsonb_build_array(
      'Yang di-Pertuan Agong ialah Ketua Kerajaan manakala Perdana Menteri ialah Ketua Negara',
      'Yang di-Pertuan Agong ialah Ketua Negara manakala Perdana Menteri ialah Ketua Kerajaan',
      'Kedua-duanya merupakan Ketua Negara',
      'Perdana Menteri ialah Ketua Perundangan manakala Yang di-Pertuan Agong ialah Ketua Kehakiman'
    ),
    true,
    2,
    true
  ),
  (
    's1-04-q03',
    'topic-s1-04',
    'Apakah tujuan utama pembahagian kuasa antara badan perundangan, eksekutif dan kehakiman?',
    jsonb_build_array(
      'Memusatkan semua kuasa pada satu institusi',
      'Mewujudkan semak dan imbang serta mengurangkan penyalahgunaan kuasa',
      'Menghapuskan kerjasama antara institusi kerajaan',
      'Memberikan kuasa menggubal undang-undang kepada mahkamah'
    ),
    true,
    3,
    true
  ),
  (
    's1-04-q04',
    'topic-s1-04',
    E'Yang manakah merupakan komponen Parlimen Malaysia?\n\nI Yang di-Pertuan Agong\nII Dewan Negara\nIII Dewan Rakyat\nIV Jemaah Menteri',
    jsonb_build_array(
      'I dan II',
      'I, II dan III',
      'II, III dan IV',
      'I, III dan IV'
    ),
    false,
    4,
    true
  ),
  (
    's1-04-q05',
    'topic-s1-04',
    'Ahli badan manakah dipilih secara langsung oleh rakyat melalui pilihan raya?',
    jsonb_build_array(
      'Dewan Rakyat',
      'Dewan Negara',
      'Jemaah Menteri',
      'Majlis Raja-Raja'
    ),
    true,
    5,
    true
  ),
  (
    's1-04-q06',
    'topic-s1-04',
    'Apakah fungsi utama Dewan Negara dalam proses perundangan?',
    jsonb_build_array(
      'Melantik semua Ahli Dewan Rakyat',
      'Menentukan keputusan mahkamah',
      'Meneliti dan membahaskan rang undang-undang yang dikemukakan',
      'Menjalankan pentadbiran kementerian'
    ),
    true,
    6,
    true
  ),
  (
    's1-04-q07',
    'topic-s1-04',
    'Di manakah rang undang-undang berkaitan kewangan atau perbekalan mesti dimulakan?',
    jsonb_build_array(
      'Dewan Negara',
      'Dewan Rakyat',
      'Majlis Raja-Raja',
      'Mahkamah Persekutuan'
    ),
    true,
    7,
    true
  ),
  (
    's1-04-q08',
    'topic-s1-04',
    'Pilih urutan peringkat utama pembacaan sesuatu rang undang-undang dalam sesebuah Dewan.',
    jsonb_build_array(
      'Bacaan Pertama, Bacaan Kedua, Peringkat Jawatankuasa, Bacaan Ketiga',
      'Bacaan Kedua, Bacaan Pertama, Bacaan Ketiga, Peringkat Jawatankuasa',
      'Peringkat Jawatankuasa, Bacaan Pertama, Bacaan Kedua, Bacaan Ketiga',
      'Bacaan Pertama, Peringkat Jawatankuasa, Bacaan Ketiga, Bacaan Kedua'
    ),
    false,
    8,
    true
  ),
  (
    's1-04-q09',
    'topic-s1-04',
    'Siapakah yang dilantik sebagai Perdana Menteri oleh Yang di-Pertuan Agong?',
    jsonb_build_array(
      'Mana-mana anggota Dewan Negara yang paling lama berkhidmat',
      'Ketua hakim yang paling kanan',
      'Ketua parti yang memperoleh undi popular tertinggi tanpa mengambil kira sokongan Dewan Rakyat',
      'Seorang anggota Dewan Rakyat yang pada hemat baginda mungkin mendapat kepercayaan majoriti ahli Dewan Rakyat'
    ),
    true,
    9,
    true
  ),
  (
    's1-04-q10',
    'topic-s1-04',
    'Kepada siapakah Jemaah Menteri bertanggungjawab secara bersama?',
    jsonb_build_array(
      'Majlis Raja-Raja',
      'Mahkamah Persekutuan',
      'Parlimen',
      'Suruhanjaya Pilihan Raya'
    ),
    true,
    10,
    true
  ),
  (
    's1-04-q11',
    'topic-s1-04',
    E'Yang manakah merupakan kuasa budi bicara Yang di-Pertuan Agong?\n\nI Melantik Perdana Menteri\nII Tidak memperkenankan permintaan pembubaran Parlimen\nIII Meminta diadakan mesyuarat Majlis Raja-Raja yang berkaitan dengan keistimewaan, kedudukan, kemuliaan dan kebesaran Raja-Raja\nIV Melantik semua menteri tanpa nasihat Perdana Menteri',
    jsonb_build_array(
      'I, II dan III',
      'I, II dan IV',
      'I, III dan IV',
      'II, III dan IV'
    ),
    false,
    11,
    true
  ),
  (
    's1-04-q12',
    'topic-s1-04',
    'Daripada kalangan siapakah anggota Jemaah Menteri Persekutuan dilantik?',
    jsonb_build_array(
      'Pegawai kanan perkhidmatan awam sahaja',
      'Ahli Dewan Rakyat sahaja',
      'Ahli mana-mana satu Majlis Parlimen',
      'Anggota Majlis Raja-Raja sahaja'
    ),
    true,
    12,
    true
  ),
  (
    's1-04-q13',
    'topic-s1-04',
    'Apakah fungsi Majlis Raja-Raja yang berkaitan dengan jawatan Ketua Utama Negara?',
    jsonb_build_array(
      'Melantik semua Ahli Dewan Negara',
      'Memilih Yang di-Pertuan Agong dan Timbalan Yang di-Pertuan Agong',
      'Memilih Perdana Menteri selepas pilihan raya',
      'Melantik Ketua Hakim Negara tanpa proses lain'
    ),
    true,
    13,
    true
  ),
  (
    's1-04-q14',
    'topic-s1-04',
    'Siapakah Ketua Kerajaan pada peringkat negeri?',
    jsonb_build_array(
      'Setiausaha Kerajaan Negeri',
      'Sultan atau Yang di-Pertua Negeri',
      'Yang Dipertua Dewan Undangan Negeri',
      'Menteri Besar atau Ketua Menteri'
    ),
    true,
    14,
    true
  ),
  (
    's1-04-q15',
    'topic-s1-04',
    'Mahkamah manakah merupakan mahkamah tertinggi dalam hierarki kehakiman Malaysia?',
    jsonb_build_array(
      'Mahkamah Persekutuan',
      'Mahkamah Rayuan',
      'Mahkamah Tinggi',
      'Mahkamah Sesyen'
    ),
    true,
    15,
    true
  ),
  (
    's1-04-q16',
    'topic-s1-04',
    'Apakah fungsi utama Mahkamah Rayuan?',
    jsonb_build_array(
      'Mendengar semua kes buat kali pertama',
      'Mendengar rayuan terhadap keputusan Mahkamah Tinggi',
      'Menggubal undang-undang berkaitan mahkamah',
      'Menyelesaikan pertikaian antara Dewan Negara dengan Dewan Rakyat'
    ),
    true,
    16,
    true
  ),
  (
    's1-04-q17',
    'topic-s1-04',
    'Pernyataan manakah yang tepat tentang Mahkamah Tinggi di Malaysia?',
    jsonb_build_array(
      'Malaysia hanya mempunyai satu Mahkamah Tinggi',
      'Mahkamah Tinggi merupakan sebahagian daripada Mahkamah Bawahan',
      'Mahkamah Tinggi di Malaya dan Mahkamah Tinggi di Sabah dan Sarawak mempunyai kedudukan yang setara',
      'Mahkamah Tinggi hanya mendengar kes yang berlaku di ibu negara'
    ),
    true,
    17,
    true
  ),
  (
    's1-04-q18',
    'topic-s1-04',
    'Yang manakah tergolong sebagai Mahkamah Bawahan?',
    jsonb_build_array(
      'Mahkamah Sesyen dan Mahkamah Majistret',
      'Mahkamah Persekutuan dan Mahkamah Rayuan',
      'Mahkamah Tinggi dan Mahkamah Sesyen',
      'Mahkamah Rayuan dan Mahkamah Majistret'
    ),
    true,
    18,
    true
  ),
  (
    's1-04-q19',
    'topic-s1-04',
    'Apakah peranan utama badan kehakiman dalam sistem pemerintahan?',
    jsonb_build_array(
      'Membentuk Jemaah Menteri selepas pilihan raya',
      'Mengurus kutipan hasil kerajaan',
      'Menentukan dasar pentadbiran kementerian',
      'Mentafsir dan mengaplikasikan undang-undang serta menyelesaikan pertikaian'
    ),
    true,
    19,
    true
  ),
  (
    's1-04-q20',
    'topic-s1-04',
    E'Yang manakah merupakan fungsi institusi negara yang tepat?\n\nI Ketua Audit Negara mengaudit akaun kerajaan\nII Peguam Negara memberikan nasihat undang-undang kepada kerajaan dan menjalankan fungsi pendakwaan\nIII Suruhanjaya Pilihan Raya mengendalikan pilihan raya\nIV Jemaah Menteri mendengar rayuan terhadap keputusan Mahkamah Rayuan',
    jsonb_build_array(
      'I, II dan III',
      'I, II dan IV',
      'I, III dan IV',
      'II, III dan IV'
    ),
    false,
    20,
    true
  )
on conflict (id)
do update set
  topic_id =
    excluded.topic_id,

  question_text =
    excluded.question_text,

  options =
    excluded.options,

  shuffle_options =
    excluded.shuffle_options,

  sort_order =
    excluded.sort_order,

  is_active =
    excluded.is_active;


-- =========================================================
-- JAWAPAN DAN PENERANGAN
-- =========================================================

insert into private.question_answers (
  question_id,
  correct_option_index,
  explanation
)
values
  (
    's1-04-q01',
    2,
    'Malaysia mengamalkan demokrasi berparlimen di bawah Raja Berperlembagaan dengan Yang di-Pertuan Agong sebagai Ketua Negara.'
  ),
  (
    's1-04-q02',
    1,
    'Yang di-Pertuan Agong ialah Ketua Negara, manakala Perdana Menteri mengetuai kerajaan Persekutuan.'
  ),
  (
    's1-04-q03',
    1,
    'Pembahagian kuasa membantu mewujudkan semak dan imbang supaya kuasa kerajaan tidak tertumpu sepenuhnya pada satu badan.'
  ),
  (
    's1-04-q04',
    1,
    'Parlimen Malaysia terdiri daripada Yang di-Pertuan Agong, Dewan Negara dan Dewan Rakyat. Jemaah Menteri ialah badan eksekutif.'
  ),
  (
    's1-04-q05',
    0,
    'Ahli Dewan Rakyat dipilih oleh rakyat melalui pilihan raya untuk mewakili kawasan Parlimen masing-masing.'
  ),
  (
    's1-04-q06',
    2,
    'Dewan Negara berperanan meneliti, membahaskan dan menyemak rang undang-undang dalam proses perundangan.'
  ),
  (
    's1-04-q07',
    1,
    'Rang undang-undang yang berkaitan dengan kewangan atau perbekalan mesti dimulakan di Dewan Rakyat.'
  ),
  (
    's1-04-q08',
    0,
    'Urutan utamanya ialah Bacaan Pertama, Bacaan Kedua, Peringkat Jawatankuasa dan Bacaan Ketiga.'
  ),
  (
    's1-04-q09',
    3,
    'Yang di-Pertuan Agong melantik seorang anggota Dewan Rakyat yang pada hemat baginda mungkin mendapat kepercayaan majoriti ahli Dewan Rakyat.'
  ),
  (
    's1-04-q10',
    2,
    'Jemaah Menteri bertanggungjawab secara bersama kepada Parlimen terhadap dasar dan keputusan kerajaan.'
  ),
  (
    's1-04-q11',
    0,
    'Kuasa budi bicara termasuk melantik Perdana Menteri, tidak memperkenankan permintaan pembubaran Parlimen dan meminta mesyuarat tertentu Majlis Raja-Raja. Menteri lain dilantik atas nasihat Perdana Menteri.'
  ),
  (
    's1-04-q12',
    2,
    'Menteri dilantik daripada kalangan ahli Dewan Rakyat atau Dewan Negara, manakala Perdana Menteri mestilah anggota Dewan Rakyat.'
  ),
  (
    's1-04-q13',
    1,
    'Majlis Raja-Raja memilih Yang di-Pertuan Agong dan Timbalan Yang di-Pertuan Agong mengikut peraturan yang ditetapkan.'
  ),
  (
    's1-04-q14',
    3,
    'Menteri Besar atau Ketua Menteri ialah Ketua Kerajaan Negeri, manakala Sultan atau Yang di-Pertua Negeri ialah Ketua Negeri.'
  ),
  (
    's1-04-q15',
    0,
    'Mahkamah Persekutuan ialah mahkamah tertinggi dalam hierarki kehakiman Malaysia.'
  ),
  (
    's1-04-q16',
    1,
    'Mahkamah Rayuan mendengar rayuan terhadap keputusan Mahkamah Tinggi sebelum sesuatu perkara dibawa ke Mahkamah Persekutuan, jika dibenarkan.'
  ),
  (
    's1-04-q17',
    2,
    'Mahkamah Tinggi di Malaya dan Mahkamah Tinggi di Sabah dan Sarawak mempunyai kedudukan serta bidang kuasa yang setara dalam kawasan masing-masing.'
  ),
  (
    's1-04-q18',
    0,
    'Mahkamah Sesyen dan Mahkamah Majistret merupakan Mahkamah Bawahan.'
  ),
  (
    's1-04-q19',
    3,
    'Badan kehakiman mentafsir dan mengaplikasikan undang-undang, menyelesaikan pertikaian serta menentukan kes menurut undang-undang.'
  ),
  (
    's1-04-q20',
    0,
    'Ketua Audit Negara mengaudit akaun kerajaan, Peguam Negara menjalankan fungsi perundangan dan pendakwaan, manakala Suruhanjaya Pilihan Raya mengendalikan pilihan raya. Jemaah Menteri bukan mahkamah rayuan.'
  )
on conflict (question_id)
do update set
  correct_option_index =
    excluded.correct_option_index,

  explanation =
    excluded.explanation;

commit;