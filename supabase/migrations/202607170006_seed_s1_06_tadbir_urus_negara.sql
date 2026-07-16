begin;

-- =========================================================
-- S1-06 TADBIR URUS NEGARA
--
-- Skop:
-- 1. Takrif dan ciri tadbir urus
-- 2. Prinsip tadbir urus baik
-- 3. Sistem dan struktur pentadbiran
-- 4. Kabinet, kementerian, suruhanjaya
-- 5. Ketua Audit Negara
-- 6. Perbadanan awam
-- 7. Majlis penyelarasan
-- 8. Kerajaan Persekutuan, Negeri dan Tempatan
-- 9. Sumber kewangan kerajaan
-- 10. Kepentingan dan cabaran tadbir urus baik
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
    's1-06-q01',
    'topic-s1-06',
    'Apakah maksud tadbir urus negara yang paling tepat?',
    jsonb_build_array(
      'Proses mengurus dan mentadbir negara secara teratur untuk mencapai matlamat serta kepentingan rakyat',
      'Proses menyerahkan semua urusan kerajaan kepada sektor swasta',
      'Proses menggubal undang-undang oleh mahkamah',
      'Proses membenarkan setiap agensi bertindak tanpa penyelarasan'
    ),
    true,
    1,
    true
  ),
  (
    's1-06-q02',
    'topic-s1-06',
    E'Yang manakah merupakan ciri tadbir urus baik?\n\nI Ketelusan\nII Akauntabiliti\nIII Integriti\nIV Penyalahgunaan kuasa',
    jsonb_build_array(
      'I dan II',
      'I, II dan III',
      'II, III dan IV',
      'I, III dan IV'
    ),
    false,
    2,
    true
  ),
  (
    's1-06-q03',
    'topic-s1-06',
    'Apakah yang dimaksudkan dengan akauntabiliti dalam pentadbiran awam?',
    jsonb_build_array(
      'Pegawai bebas membuat keputusan tanpa memberikan penjelasan',
      'Agensi hanya bertanggungjawab kepada pihak swasta',
      'Pihak yang diberi kuasa bertanggungjawab menjelaskan tindakan dan penggunaan sumber',
      'Semua keputusan pentadbiran mesti dirahsiakan'
    ),
    true,
    3,
    true
  ),
  (
    's1-06-q04',
    'topic-s1-06',
    'Sebuah kementerian menerbitkan maklumat perbelanjaan, pencapaian program dan hasil audit kepada orang awam. Prinsip tadbir urus manakah yang diamalkan?',
    jsonb_build_array(
      'Ketelusan',
      'Pemusatan kuasa',
      'Kerahsiaan pentadbiran',
      'Pengasingan masyarakat'
    ),
    true,
    4,
    true
  ),
  (
    's1-06-q05',
    'topic-s1-06',
    'Yang manakah menunjukkan pentadbiran yang berintegriti?',
    jsonb_build_array(
      'Pegawai memberikan kontrak kepada syarikat milik ahli keluarganya tanpa pengisytiharan',
      'Pegawai mengubah laporan prestasi supaya sasaran kelihatan tercapai',
      'Pegawai merahsiakan kesalahan yang dilakukan oleh rakan sekerja',
      'Pegawai melaksanakan tugas dengan jujur serta mengelakkan konflik kepentingan'
    ),
    true,
    5,
    true
  ),
  (
    's1-06-q06',
    'topic-s1-06',
    'Apakah peranan utama Kabinet dalam pentadbiran Kerajaan Persekutuan?',
    jsonb_build_array(
      'Mengendalikan pilihan raya',
      'Menggubal semua keputusan mahkamah',
      'Membentuk dasar kerajaan dan mengarahkan pelaksanaannya',
      'Mengaudit semua akaun kerajaan'
    ),
    true,
    6,
    true
  ),
  (
    's1-06-q07',
    'topic-s1-06',
    'Apakah fungsi utama sesebuah kementerian?',
    jsonb_build_array(
      'Merancang dan melaksanakan dasar kerajaan dalam bidang tanggungjawabnya',
      'Mendengar rayuan terhadap keputusan Mahkamah Tinggi',
      'Menentukan sempadan kawasan pilihan raya',
      'Memilih Yang di-Pertuan Agong'
    ),
    true,
    7,
    true
  ),
  (
    's1-06-q08',
    'topic-s1-06',
    E'Yang manakah benar tentang pentadbiran Kerajaan Persekutuan?\n\nI Kabinet menentukan dasar kerajaan\nII Kementerian melaksanakan dasar dalam bidang masing-masing\nIII Jabatan menjalankan fungsi operasi dan penyampaian perkhidmatan\nIV Mahkamah mengurus semua program kementerian',
    jsonb_build_array(
      'I dan II',
      'I, II dan III',
      'II, III dan IV',
      'I, III dan IV'
    ),
    false,
    8,
    true
  ),
  (
    's1-06-q09',
    'topic-s1-06',
    'Apakah yang dimaksudkan dengan perbadanan awam?',
    jsonb_build_array(
      'Organisasi yang ditubuhkan kerajaan untuk menjalankan fungsi tertentu atau menyediakan perkhidmatan kepada masyarakat',
      'Pertubuhan politik yang bertanding dalam pilihan raya',
      'Mahkamah khas yang menyelesaikan pertikaian pentadbiran',
      'Syarikat persendirian yang tidak mempunyai hubungan dengan kerajaan'
    ),
    true,
    9,
    true
  ),
  (
    's1-06-q10',
    'topic-s1-06',
    'Apakah perbezaan utama antara badan berkanun dengan badan tidak berkanun?',
    jsonb_build_array(
      'Badan berkanun diwujudkan melalui undang-undang khusus, manakala badan tidak berkanun lazimnya ditubuhkan di bawah undang-undang syarikat',
      'Badan berkanun hanya beroperasi di luar negara',
      'Badan tidak berkanun tidak boleh dimiliki oleh kerajaan',
      'Badan berkanun tidak mempunyai sebarang tanggungjawab awam'
    ),
    true,
    10,
    true
  ),
  (
    's1-06-q11',
    'topic-s1-06',
    'Apakah peranan utama Ketua Audit Negara?',
    jsonb_build_array(
      'Mengurus pendaftaran pemilih',
      'Mengaudit akaun kerajaan dan melaporkan penemuan berkaitan pengurusan kewangan awam',
      'Melantik semua pegawai perkhidmatan awam',
      'Menentukan dasar luar negara'
    ),
    true,
    11,
    true
  ),
  (
    's1-06-q12',
    'topic-s1-06',
    E'Yang manakah merupakan majlis yang membantu penyelarasan antara Kerajaan Persekutuan dengan Kerajaan Negeri?\n\nI Majlis Kewangan Negara\nII Majlis Tanah Negara\nIII Majlis Negara bagi Kerajaan Tempatan\nIV Majlis Peperiksaan Malaysia',
    jsonb_build_array(
      'I dan II',
      'I, II dan III',
      'II, III dan IV',
      'I, III dan IV'
    ),
    false,
    12,
    true
  ),
  (
    's1-06-q13',
    'topic-s1-06',
    'Apakah tujuan utama penyelarasan pentadbiran antara Kerajaan Persekutuan, Kerajaan Negeri dan Pihak Berkuasa Tempatan?',
    jsonb_build_array(
      'Menghapuskan semua kuasa Kerajaan Negeri',
      'Memastikan dasar dan program dilaksanakan secara teratur tanpa pertindihan yang tidak perlu',
      'Membenarkan setiap peringkat kerajaan menggunakan dasar yang bercanggah',
      'Menyerahkan seluruh pentadbiran kepada Pihak Berkuasa Tempatan'
    ),
    true,
    13,
    true
  ),
  (
    's1-06-q14',
    'topic-s1-06',
    'Yang manakah merupakan tanggungjawab lazim Pihak Berkuasa Tempatan?',
    jsonb_build_array(
      'Mengurus pertahanan negara',
      'Menentukan dasar kewangan negara',
      'Mengurus kebersihan, pelesenan dan kemudahan tempatan',
      'Menjalinkan hubungan diplomatik'
    ),
    true,
    14,
    true
  ),
  (
    's1-06-q15',
    'topic-s1-06',
    'Yang manakah merupakan sumber hasil yang lazim bagi Pihak Berkuasa Tempatan?',
    jsonb_build_array(
      'Cukai taksiran dan bayaran lesen',
      'Cukai pendapatan individu',
      'Duti kastam antarabangsa',
      'Hasil petroleum negara'
    ),
    true,
    15,
    true
  ),
  (
    's1-06-q16',
    'topic-s1-06',
    'Mengapakah tadbir urus baik penting dalam menghadapi globalisasi?',
    jsonb_build_array(
      'Membolehkan negara menutup semua hubungan dengan negara luar',
      'Mengurangkan keperluan kepada tenaga kerja berkemahiran',
      'Membolehkan kerajaan mengabaikan perubahan ekonomi dunia',
      'Meningkatkan keyakinan, kecekapan dan daya saing negara'
    ),
    true,
    16,
    true
  ),
  (
    's1-06-q17',
    'topic-s1-06',
    'Sebuah agensi menerima banyak aduan kerana proses permohonan terlalu panjang dan status permohonan sukar diketahui. Apakah penambahbaikan paling sesuai?',
    jsonb_build_array(
      'Menambah lebih banyak borang tanpa menyemak proses kerja',
      'Menyederhanakan prosedur, menetapkan tempoh perkhidmatan dan menyediakan semakan status',
      'Menghentikan penerimaan aduan daripada pelanggan',
      'Mengehadkan maklumat tentang prosedur kepada pegawai tertentu'
    ),
    true,
    17,
    true
  ),
  (
    's1-06-q18',
    'topic-s1-06',
    E'Yang manakah merupakan cabaran terhadap pelaksanaan tadbir urus baik?\n\nI Kelemahan integriti\nII Sistem penyampaian perkhidmatan yang tidak cekap\nIII Kekurangan modal insan yang kompeten\nIV Penggunaan sumber secara berhemah',
    jsonb_build_array(
      'I dan II',
      'I, II dan III',
      'II, III dan IV',
      'I, III dan IV'
    ),
    false,
    18,
    true
  ),
  (
    's1-06-q19',
    'topic-s1-06',
    'Bagaimanakah pembangunan modal insan dapat memperkukuh tadbir urus negara?',
    jsonb_build_array(
      'Dengan mengurangkan latihan dan pembangunan kemahiran pegawai',
      'Dengan memastikan pegawai mempunyai kompetensi, etika dan keupayaan menyesuaikan diri',
      'Dengan menghapuskan penilaian prestasi',
      'Dengan mengehadkan penggunaan pengetahuan baharu'
    ),
    true,
    19,
    true
  ),
  (
    's1-06-q20',
    'topic-s1-06',
    E'Yang manakah merupakan tindakan yang sesuai untuk memperkukuh tadbir urus digital?\n\nI Melindungi data dan sistem kerajaan\nII Memperluas akses perkhidmatan dalam talian\nIII Meningkatkan kemahiran digital penjawat awam\nIV Mengabaikan risiko keselamatan siber',
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
    's1-06-q01',
    0,
    'Tadbir urus merujuk kepada proses dan kaedah sesebuah negara atau organisasi diurus, dikawal dan dipertanggungjawabkan untuk mencapai matlamat awam.'
  ),
  (
    's1-06-q02',
    1,
    'Ketelusan, akauntabiliti dan integriti ialah ciri penting tadbir urus baik. Penyalahgunaan kuasa bertentangan dengan tadbir urus baik.'
  ),
  (
    's1-06-q03',
    2,
    'Akauntabiliti bermaksud individu atau agensi yang diberi kuasa perlu menjelaskan tindakan, keputusan dan penggunaan sumber di bawah tanggungjawabnya.'
  ),
  (
    's1-06-q04',
    0,
    'Penerbitan maklumat perbelanjaan, pencapaian dan hasil audit membolehkan orang awam memahami serta menilai tindakan kerajaan, sekali gus meningkatkan ketelusan.'
  ),
  (
    's1-06-q05',
    3,
    'Integriti melibatkan sikap jujur, amanah, beretika dan mengelakkan konflik kepentingan semasa melaksanakan tanggungjawab.'
  ),
  (
    's1-06-q06',
    2,
    'Kabinet ialah badan eksekutif utama yang membentuk dasar kerajaan dan menyelaraskan pelaksanaannya melalui kementerian serta agensi.'
  ),
  (
    's1-06-q07',
    0,
    'Kementerian merancang, menyelaras dan melaksanakan dasar kerajaan dalam portfolio atau bidang tanggungjawab masing-masing.'
  ),
  (
    's1-06-q08',
    1,
    'Kabinet menentukan dasar, kementerian menyelaras pelaksanaannya dan jabatan menjalankan fungsi operasi. Mahkamah menjalankan fungsi kehakiman.'
  ),
  (
    's1-06-q09',
    0,
    'Perbadanan awam ditubuhkan atau dimiliki kerajaan untuk menjalankan fungsi pembangunan, perdagangan atau penyediaan perkhidmatan tertentu.'
  ),
  (
    's1-06-q10',
    0,
    'Badan berkanun diwujudkan melalui akta atau enakmen khusus, manakala badan tidak berkanun lazimnya diperbadankan di bawah undang-undang syarikat.'
  ),
  (
    's1-06-q11',
    1,
    'Ketua Audit Negara mengaudit akaun Kerajaan Persekutuan, negeri dan badan awam serta melaporkan penemuan berkaitan pengurusan kewangan.'
  ),
  (
    's1-06-q12',
    1,
    'Majlis Kewangan Negara, Majlis Tanah Negara dan Majlis Negara bagi Kerajaan Tempatan membantu penyelarasan dasar antara Kerajaan Persekutuan dengan negeri.'
  ),
  (
    's1-06-q13',
    1,
    'Penyelarasan memastikan tanggungjawab setiap peringkat kerajaan jelas, program saling menyokong dan pertindihan pentadbiran dapat dikurangkan.'
  ),
  (
    's1-06-q14',
    2,
    'Pihak Berkuasa Tempatan lazimnya mengurus kebersihan, pelesenan, kemudahan awam, perancangan tempatan dan perkhidmatan dalam kawasannya.'
  ),
  (
    's1-06-q15',
    0,
    'Cukai taksiran, bayaran lesen, sewaan dan fi perkhidmatan merupakan antara sumber hasil yang lazim bagi Pihak Berkuasa Tempatan.'
  ),
  (
    's1-06-q16',
    3,
    'Tadbir urus yang cekap, telus dan stabil meningkatkan keyakinan pelabur, kualiti perkhidmatan serta daya saing negara dalam persekitaran global.'
  ),
  (
    's1-06-q17',
    1,
    'Prosedur yang ringkas, standard masa perkhidmatan dan semakan status dapat meningkatkan kecekapan, ketelusan dan pengalaman pelanggan.'
  ),
  (
    's1-06-q18',
    1,
    'Kelemahan integriti, ketidakcekapan penyampaian dan kekurangan modal insan kompeten ialah cabaran tadbir urus. Penggunaan sumber secara berhemah ialah amalan positif.'
  ),
  (
    's1-06-q19',
    1,
    'Modal insan yang kompeten dan beretika membantu agensi melaksanakan dasar dengan cekap, membuat keputusan berkualiti dan menyesuaikan diri dengan perubahan.'
  ),
  (
    's1-06-q20',
    0,
    'Tadbir urus digital memerlukan perlindungan data, peluasan akses perkhidmatan dan kemahiran digital. Risiko keselamatan siber tidak boleh diabaikan.'
  )
on conflict (question_id)
do update set
  correct_option_index =
    excluded.correct_option_index,

  explanation =
    excluded.explanation;

commit;