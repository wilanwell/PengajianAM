begin;

-- =========================================================
-- S1-03 PERLEMBAGAAN PERSEKUTUAN
--
-- Skop utama:
-- 1. Konsep dan ketertinggian Perlembagaan
-- 2. Agama Persekutuan
-- 3. Kebebasan asasi
-- 4. Bahasa kebangsaan
-- 5. Kedudukan istimewa dan kepentingan sah
-- 6. Pembahagian kuasa perundangan
-- 7. Kewarganegaraan
-- 8. Pindaan Perlembagaan
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
    's1-03-q01',
    'topic-s1-03',
    'Apakah undang-undang tertinggi di Malaysia?',
    jsonb_build_array(
      'Akta Parlimen',
      'Perlembagaan Negeri',
      'Perlembagaan Persekutuan',
      'Keputusan Jemaah Menteri'
    ),
    true,
    1,
    true
  ),
  (
    's1-03-q02',
    'topic-s1-03',
    'Apakah kesan terhadap undang-undang yang bercanggah dengan Perlembagaan Persekutuan?',
    jsonb_build_array(
      'Undang-undang tersebut terus berkuat kuasa tanpa perubahan',
      'Undang-undang tersebut terbatal setakat bahagian yang bercanggah',
      'Seluruh Perlembagaan Persekutuan perlu dipinda',
      'Undang-undang tersebut menjadi undang-undang negeri'
    ),
    true,
    2,
    true
  ),
  (
    's1-03-q03',
    'topic-s1-03',
    'Pernyataan manakah yang paling tepat tentang kedudukan agama dalam Perlembagaan Persekutuan?',
    jsonb_build_array(
      'Semua agama mempunyai kedudukan sebagai agama Persekutuan',
      'Agama selain Islam tidak boleh diamalkan',
      'Hal ehwal agama tidak disebut dalam Perlembagaan',
      'Islam ialah agama Persekutuan tetapi agama lain boleh diamalkan dengan aman dan damai'
    ),
    true,
    3,
    true
  ),
  (
    's1-03-q04',
    'topic-s1-03',
    E'Yang manakah terkandung dalam kebebasan asasi?\n\nI Kebebasan diri\nII Kesamarataan di sisi undang-undang\nIII Kebebasan bercakap, berhimpun dan berpersatuan\nIV Kebebasan mengingkari keputusan mahkamah',
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
    's1-03-q05',
    'topic-s1-03',
    'Seorang individu ditangkap oleh pihak berkuasa. Apakah hak yang perlu diberikan kepadanya menurut kebebasan diri?',
    jsonb_build_array(
      'Dimaklumkan sebab penangkapan dan dibenarkan mendapatkan khidmat peguam',
      'Dibebaskan serta-merta tanpa sebarang siasatan',
      'Dibenarkan menentukan sendiri pertuduhan terhadapnya',
      'Dikecualikan daripada semua proses perundangan'
    ),
    true,
    5,
    true
  ),
  (
    's1-03-q06',
    'topic-s1-03',
    'Apakah maksud prinsip kesamarataan yang diperuntukkan dalam Perlembagaan Persekutuan?',
    jsonb_build_array(
      'Semua orang mesti menerima pendapatan yang sama',
      'Semua orang bebas daripada sebarang tindakan undang-undang',
      'Semua orang sama di sisi undang-undang dan berhak mendapat perlindungan yang sama',
      'Semua orang mesti memegang jawatan yang sama dalam kerajaan'
    ),
    true,
    6,
    true
  ),
  (
    's1-03-q07',
    'topic-s1-03',
    'Mengapakah kebebasan bercakap, berhimpun dan berpersatuan tidak dianggap sebagai kebebasan mutlak?',
    jsonb_build_array(
      'Kebebasan tersebut hanya diberikan kepada penjawat awam',
      'Parlimen boleh mengenakan sekatan tertentu demi kepentingan yang dibenarkan oleh Perlembagaan',
      'Kebebasan tersebut hanya boleh digunakan semasa pilihan raya',
      'Kerajaan boleh menghapuskannya tanpa undang-undang'
    ),
    true,
    7,
    true
  ),
  (
    's1-03-q08',
    'topic-s1-03',
    'Yang manakah merupakan perlindungan terhadap hak harta?',
    jsonb_build_array(
      'Harta boleh diambil tanpa sebarang undang-undang',
      'Semua harta persendirian menjadi milik kerajaan',
      'Pemilik tidak boleh mempertikaikan pengambilan hartanya',
      'Harta tidak boleh diambil secara paksa tanpa pampasan yang mencukupi'
    ),
    true,
    8,
    true
  ),
  (
    's1-03-q09',
    'topic-s1-03',
    'Pernyataan manakah yang paling tepat tentang bahasa kebangsaan?',
    jsonb_build_array(
      'Bahasa Melayu ialah bahasa kebangsaan, manakala penggunaan dan pembelajaran bahasa lain tidak dilarang',
      'Hanya bahasa Melayu boleh digunakan dalam semua urusan persendirian',
      'Bahasa Inggeris ialah bahasa kebangsaan kedua',
      'Setiap negeri boleh menentukan bahasa kebangsaannya sendiri'
    ),
    true,
    9,
    true
  ),
  (
    's1-03-q10',
    'topic-s1-03',
    'Apakah tanggungjawab Yang di-Pertuan Agong berdasarkan Perkara 153?',
    jsonb_build_array(
      'Menghapuskan semua bentuk kepentingan antara komuniti',
      'Memberikan semua jawatan awam kepada satu komuniti sahaja',
      'Memelihara kedudukan istimewa orang Melayu dan anak negeri Sabah dan Sarawak serta kepentingan sah kaum-kaum lain',
      'Menentukan kewarganegaraan setiap individu tanpa mengikut undang-undang'
    ),
    true,
    10,
    true
  ),
  (
    's1-03-q11',
    'topic-s1-03',
    'Di manakah pembahagian kuasa perundangan antara Kerajaan Persekutuan dengan Kerajaan Negeri dinyatakan?',
    jsonb_build_array(
      'Jadual Ketiga',
      'Jadual Kesembilan',
      'Jadual Kesepuluh',
      'Jadual Ketiga Belas'
    ),
    true,
    11,
    true
  ),
  (
    's1-03-q12',
    'topic-s1-03',
    'Yang manakah terletak di bawah Senarai Persekutuan?',
    jsonb_build_array(
      'Pertahanan negara',
      'Tanah',
      'Kerajaan tempatan',
      'Adat Melayu'
    ),
    true,
    12,
    true
  ),
  (
    's1-03-q13',
    'topic-s1-03',
    'Yang manakah terletak di bawah Senarai Negeri?',
    jsonb_build_array(
      'Hal ehwal luar negeri',
      'Pertahanan',
      'Kewarganegaraan',
      'Tanah'
    ),
    true,
    13,
    true
  ),
  (
    's1-03-q14',
    'topic-s1-03',
    'Yang manakah merupakan perkara dalam Senarai Bersama?',
    jsonb_build_array(
      'Mata wang',
      'Pertahanan',
      'Perumahan',
      'Kewarganegaraan'
    ),
    true,
    14,
    true
  ),
  (
    's1-03-q15',
    'topic-s1-03',
    'Satu undang-undang negeri didapati bercanggah dengan undang-undang Persekutuan. Apakah kesannya?',
    jsonb_build_array(
      'Undang-undang negeri mengatasi undang-undang Persekutuan',
      'Undang-undang Persekutuan mengatasi undang-undang negeri setakat percanggahan tersebut',
      'Kedua-dua undang-undang terbatal sepenuhnya',
      'Undang-undang yang diluluskan lebih awal mesti diutamakan'
    ),
    true,
    15,
    true
  ),
  (
    's1-03-q16',
    'topic-s1-03',
    'Pihak manakah mempunyai kuasa menggubal undang-undang mengenai perkara yang tidak dinyatakan dalam mana-mana senarai perundangan?',
    jsonb_build_array(
      'Badan Perundangan Negeri',
      'Jemaah Menteri',
      'Suruhanjaya Pilihan Raya',
      'Majlis Raja-Raja'
    ),
    true,
    16,
    true
  ),
  (
    's1-03-q17',
    'topic-s1-03',
    E'Yang manakah merupakan cara memperoleh kewarganegaraan Malaysia?\n\nI Kuat kuasa undang-undang\nII Pendaftaran\nIII Naturalisasi\nIV Percantuman wilayah',
    jsonb_build_array(
      'I dan II',
      'I, II dan III',
      'II, III dan IV',
      'I, II, III dan IV'
    ),
    false,
    17,
    true
  ),
  (
    's1-03-q18',
    'topic-s1-03',
    'Sebuah undang-undang dipersoalkan kerana dikatakan bercanggah dengan Perlembagaan Persekutuan. Apakah peranan mahkamah dalam keadaan tersebut?',
    jsonb_build_array(
      'Menggubal undang-undang baharu untuk menggantikannya',
      'Mengubah dasar kerajaan tanpa prosiding',
      'Menentukan kesahihan undang-undang dan mengisytiharkan bahagian yang bercanggah sebagai tidak sah',
      'Memindahkan kuasa menggubal undang-undang kepada pihak swasta'
    ),
    true,
    18,
    true
  ),
  (
    's1-03-q19',
    'topic-s1-03',
    'Apakah syarat umum untuk meluluskan kebanyakan pindaan terhadap Perlembagaan Persekutuan?',
    jsonb_build_array(
      'Sokongan majoriti mudah dalam Dewan Rakyat sahaja',
      'Sokongan tidak kurang daripada dua pertiga jumlah ahli setiap Majlis Parlimen',
      'Kelulusan semua Dewan Undangan Negeri',
      'Persetujuan sebulat suara semua warganegara'
    ),
    true,
    19,
    true
  ),
  (
    's1-03-q20',
    'topic-s1-03',
    E'Yang manakah benar tentang pindaan Perlembagaan Persekutuan?\n\nI Pindaan tertentu berkaitan bahasa kebangsaan dan kedudukan istimewa memerlukan persetujuan Majlis Raja-Raja\nII Kebanyakan pindaan memerlukan sokongan sekurang-kurangnya dua pertiga jumlah ahli setiap Majlis Parlimen\nIII Pindaan tertentu yang menyentuh perlindungan Sabah atau Sarawak memerlukan persetujuan Yang di-Pertua Negeri yang berkenaan\nIV Semua pindaan mesti diluluskan melalui referendum kebangsaan',
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
    's1-03-q01',
    2,
    'Perlembagaan Persekutuan ialah undang-undang tertinggi yang menjadi asas kepada sistem pemerintahan dan perundangan Malaysia.'
  ),
  (
    's1-03-q02',
    1,
    'Undang-undang yang bercanggah dengan Perlembagaan terbatal hanya setakat bahagian yang tidak selaras dengan Perlembagaan.'
  ),
  (
    's1-03-q03',
    3,
    'Islam ialah agama Persekutuan, manakala agama-agama lain boleh diamalkan dengan aman dan damai di Malaysia.'
  ),
  (
    's1-03-q04',
    1,
    'Kebebasan diri, kesamarataan serta kebebasan bercakap, berhimpun dan berpersatuan ialah antara kebebasan asasi. Tiada kebebasan untuk mengingkari keputusan mahkamah.'
  ),
  (
    's1-03-q05',
    0,
    'Individu yang ditangkap perlu dimaklumkan sebab penangkapannya dan dibenarkan berunding serta dibela oleh peguam pilihannya.'
  ),
  (
    's1-03-q06',
    2,
    'Prinsip kesamarataan bermaksud setiap orang adalah sama di sisi undang-undang dan berhak mendapat perlindungan undang-undang yang sama.'
  ),
  (
    's1-03-q07',
    1,
    'Kebebasan tersebut tertakluk pada sekatan yang boleh dibuat melalui undang-undang bagi tujuan seperti keselamatan, ketenteraman awam atau moral.'
  ),
  (
    's1-03-q08',
    3,
    'Perlembagaan melindungi hak harta dan menetapkan bahawa pengambilan secara paksa perlu disertai pampasan yang mencukupi.'
  ),
  (
    's1-03-q09',
    0,
    'Bahasa Melayu ialah bahasa kebangsaan, tetapi Perlembagaan tidak melarang penggunaan, pengajaran atau pembelajaran bahasa lain.'
  ),
  (
    's1-03-q10',
    2,
    'Yang di-Pertuan Agong bertanggungjawab memelihara kedudukan istimewa orang Melayu dan anak negeri Sabah dan Sarawak serta kepentingan sah kaum-kaum lain.'
  ),
  (
    's1-03-q11',
    1,
    'Jadual Kesembilan mengandungi Senarai Persekutuan, Senarai Negeri dan Senarai Bersama.'
  ),
  (
    's1-03-q12',
    0,
    'Pertahanan negara ialah perkara Persekutuan kerana melibatkan keselamatan dan kepentingan negara secara keseluruhan.'
  ),
  (
    's1-03-q13',
    3,
    'Tanah ialah perkara di bawah bidang kuasa perundangan negeri.'
  ),
  (
    's1-03-q14',
    2,
    'Perumahan merupakan antara perkara dalam Senarai Bersama yang boleh diperundangkan oleh Persekutuan dan negeri.'
  ),
  (
    's1-03-q15',
    1,
    'Apabila undang-undang negeri bercanggah dengan undang-undang Persekutuan, undang-undang Persekutuan mengatasi dan undang-undang negeri terbatal setakat percanggahan.'
  ),
  (
    's1-03-q16',
    0,
    'Kuasa baki perundangan bagi perkara yang tidak dinyatakan dalam mana-mana senarai terletak pada Badan Perundangan Negeri.'
  ),
  (
    's1-03-q17',
    3,
    'Kewarganegaraan boleh diperoleh melalui kuat kuasa undang-undang, pendaftaran, naturalisasi dan percantuman wilayah.'
  ),
  (
    's1-03-q18',
    2,
    'Mahkamah boleh menilai kesahihan undang-undang dan mengisytiharkan bahagian yang bercanggah dengan Perlembagaan sebagai tidak sah.'
  ),
  (
    's1-03-q19',
    1,
    'Secara umum, kebanyakan pindaan memerlukan sokongan tidak kurang daripada dua pertiga jumlah ahli dalam setiap Majlis Parlimen.'
  ),
  (
    's1-03-q20',
    0,
    'Pindaan tertentu memerlukan persetujuan tambahan daripada Majlis Raja-Raja atau Yang di-Pertua Negeri Sabah atau Sarawak. Referendum kebangsaan bukan syarat bagi semua pindaan.'
  )
on conflict (question_id)
do update set
  correct_option_index =
    excluded.correct_option_index,

  explanation =
    excluded.explanation;

commit;