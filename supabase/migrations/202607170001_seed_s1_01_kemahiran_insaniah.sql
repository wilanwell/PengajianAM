begin;

-- =========================================================
-- S1-01 KEMAHIRAN INSANIAH
--
-- Skop:
-- 1. Mencari data dan maklumat
-- 2. Menganalisis data dan maklumat
-- 3. Kemahiran berfikir
-- 4. Penyelesaian masalah
-- 5. Pembuatan keputusan
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
    's1-01-q01',
    'topic-s1-01',
    'Apakah tindakan paling wajar apabila menerima maklumat tular yang belum disahkan?',
    jsonb_build_array(
      'Menyebarkannya dengan segera kepada orang lain',
      'Menyemak sumber rasmi dan membandingkannya dengan sumber lain',
      'Menerimanya sebagai benar jika dihantar oleh kenalan',
      'Menilainya berdasarkan jumlah komen dalam media sosial'
    ),
    true,
    1,
    true
  ),
  (
    's1-01-q02',
    'topic-s1-01',
    'Yang manakah merupakan sumber primer dalam sesuatu penyelidikan?',
    jsonb_build_array(
      'Artikel yang meringkaskan beberapa kajian terdahulu',
      'Buku teks yang menerangkan sesuatu konsep',
      'Transkrip temu bual asal dengan responden',
      'Laman sesawang yang mengulas laporan kerajaan'
    ),
    true,
    2,
    true
  ),
  (
    's1-01-q03',
    'topic-s1-01',
    'Apakah perbezaan paling tepat antara data dengan maklumat?',
    jsonb_build_array(
      'Data telah ditafsirkan manakala maklumat masih mentah',
      'Data ialah fakta mentah manakala maklumat ialah data yang telah diproses',
      'Data dan maklumat mempunyai maksud yang sama',
      'Maklumat hanya terdiri daripada angka manakala data terdiri daripada ayat'
    ),
    true,
    3,
    true
  ),
  (
    's1-01-q04',
    'topic-s1-01',
    'Antara berikut, yang manakah perlu dipertimbangkan untuk menilai kebolehpercayaan sesuatu sumber? I Kewibawaan penulis II Tarikh penerbitan III Bukti dan rujukan yang digunakan IV Bilangan perkongsian dalam media sosial',
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
    's1-01-q05',
    'topic-s1-01',
    'Yang manakah merupakan petunjuk paling jelas bahawa sesuatu laporan mungkin berat sebelah?',
    jsonb_build_array(
      'Menggunakan bahasa emotif dan hanya mengemukakan satu sudut pandangan',
      'Menerangkan batasan data yang digunakan',
      'Menyertakan bukti bagi setiap hujah',
      'Membandingkan pandangan daripada beberapa pihak'
    ),
    true,
    5,
    true
  ),
  (
    's1-01-q06',
    'topic-s1-01',
    'Dua laporan menunjukkan angka pengangguran yang berbeza bagi tempoh yang sama. Apakah tindakan analisis yang paling sesuai?',
    jsonb_build_array(
      'Memilih laporan yang menunjukkan angka lebih rendah',
      'Mengambil purata kedua-dua angka tanpa semakan',
      'Menyemak definisi, kaedah pengumpulan data dan tempoh rujukan',
      'Menolak kedua-dua laporan kerana mempunyai angka yang berbeza'
    ),
    true,
    6,
    true
  ),
  (
    's1-01-q07',
    'topic-s1-01',
    'Kaedah manakah paling sesuai untuk meningkatkan kebolehpercayaan hasil kaji selidik?',
    jsonb_build_array(
      'Memilih responden yang mudah dihubungi sahaja',
      'Menggunakan soalan yang mempengaruhi jawapan responden',
      'Mengambil sampel yang sangat kecil daripada satu kumpulan',
      'Menggunakan sampel yang mewakili populasi dan soalan yang neutral'
    ),
    true,
    7,
    true
  ),
  (
    's1-01-q08',
    'topic-s1-01',
    'Satu nilai dalam set data jauh lebih tinggi daripada nilai lain. Apakah tindakan paling wajar terhadap nilai tersebut?',
    jsonb_build_array(
      'Memadamkannya dengan serta-merta',
      'Menyiasat punca dan mengesahkan ketepatan nilai tersebut',
      'Menggantikannya dengan nilai purata',
      'Menganggap keseluruhan set data tidak boleh digunakan'
    ),
    true,
    8,
    true
  ),
  (
    's1-01-q09',
    'topic-s1-01',
    'Satu kajian mendapati pelajar yang tidur lebih lama memperoleh markah lebih tinggi. Apakah kesimpulan yang paling tepat?',
    jsonb_build_array(
      'Tidur lebih lama pasti menyebabkan markah tinggi',
      'Markah tinggi menyebabkan pelajar tidur lebih lama',
      'Hubungan tersebut belum membuktikan sebab dan akibat',
      'Semua faktor lain tidak mempengaruhi pencapaian pelajar'
    ),
    true,
    9,
    true
  ),
  (
    's1-01-q10',
    'topic-s1-01',
    'Yang manakah menunjukkan penggunaan pemikiran kritis?',
    jsonb_build_array(
      'Menilai bukti, andaian dan alasan sebelum menerima sesuatu kesimpulan',
      'Menerima pandangan majoriti tanpa membuat semakan',
      'Menggunakan pengalaman sendiri sebagai satu-satunya bukti',
      'Menolak pandangan yang bercanggah dengan kepercayaan sendiri'
    ),
    true,
    10,
    true
  ),
  (
    's1-01-q11',
    'topic-s1-01',
    'Apakah kaedah paling sesuai untuk menghasilkan pelbagai cadangan penyelesaian pada peringkat awal?',
    jsonb_build_array(
      'Memilih penyelesaian pertama yang dicadangkan',
      'Menolak cadangan yang kelihatan sukar dilaksanakan',
      'Menghadkan perbincangan kepada pendapat ketua kumpulan',
      'Menjalankan sumbang saran tanpa menilai idea terlebih dahulu'
    ),
    true,
    11,
    true
  ),
  (
    's1-01-q12',
    'topic-s1-01',
    'Pilih urutan proses penyelesaian masalah yang paling sesuai.',
    jsonb_build_array(
      'Mengenal pasti masalah, menganalisis punca, menjana alternatif, memilih penyelesaian dan menilai hasil',
      'Memilih penyelesaian, mengenal pasti masalah, melaksanakan tindakan dan mencari punca',
      'Melaksanakan tindakan, menilai hasil, mengenal pasti masalah dan menjana alternatif',
      'Menilai hasil, memilih penyelesaian, menganalisis punca dan mengenal pasti masalah'
    ),
    false,
    12,
    true
  ),
  (
    's1-01-q13',
    'topic-s1-01',
    'Sebuah sekolah mendapati penghantaran tugasan pelajar sering lewat. Apakah langkah terbaik untuk mengenal pasti punca sebenar masalah?',
    jsonb_build_array(
      'Menganggap semua pelajar tidak berdisiplin',
      'Menambah hukuman tanpa mendapatkan maklumat lanjut',
      'Mengumpul bukti dan meneliti faktor yang menyebabkan kelewatan',
      'Mengurangkan jumlah tugasan tanpa menilai masalah'
    ),
    true,
    13,
    true
  ),
  (
    's1-01-q14',
    'topic-s1-01',
    'Apakah asas paling penting dalam membandingkan beberapa alternatif sebelum membuat keputusan?',
    jsonb_build_array(
      'Populariti setiap alternatif dalam kalangan rakan',
      'Kriteria objektif, risiko dan kesan setiap alternatif',
      'Keutamaan individu yang paling berpengaruh',
      'Alternatif yang paling cepat dicadangkan'
    ),
    true,
    14,
    true
  ),
  (
    's1-01-q15',
    'topic-s1-01',
    'Yang manakah merupakan ciri pembuatan keputusan yang baik? I Berdasarkan bukti yang relevan II Membandingkan beberapa alternatif III Mempertimbangkan kesan terhadap pihak berkepentingan IV Bergantung sepenuhnya pada tanggapan pertama',
    jsonb_build_array(
      'I, II dan III',
      'I, II dan IV',
      'I, III dan IV',
      'II, III dan IV'
    ),
    false,
    15,
    true
  ),
  (
    's1-01-q16',
    'topic-s1-01',
    'Apakah tujuan utama analisis kos dan faedah dalam pembuatan keputusan?',
    jsonb_build_array(
      'Menghapuskan semua risiko daripada sesuatu keputusan',
      'Memastikan keputusan yang dibuat diterima oleh semua pihak',
      'Memilih alternatif yang memerlukan kos paling rendah sahaja',
      'Membandingkan sumber yang digunakan dengan manfaat yang dijangka'
    ),
    true,
    16,
    true
  ),
  (
    's1-01-q17',
    'topic-s1-01',
    'Apakah tindakan paling sesuai apabila keputusan perlu dibuat dalam keadaan maklumat yang tidak lengkap?',
    jsonb_build_array(
      'Menangguhkan semua tindakan tanpa had masa',
      'Membuat keputusan secara rawak',
      'Menggunakan maklumat terbaik yang ada serta menyediakan pelan kontingensi',
      'Mengabaikan semua risiko yang belum dikenal pasti'
    ),
    true,
    17,
    true
  ),
  (
    's1-01-q18',
    'topic-s1-01',
    'Bagaimanakah risiko pemikiran kelompok dapat dikurangkan dalam perbincangan?',
    jsonb_build_array(
      'Memastikan semua ahli bersetuju dengan ketua',
      'Menggalakkan pandangan berbeza dan penilaian secara bebas',
      'Mengelakkan perbincangan tentang kelemahan cadangan',
      'Membuat keputusan sebelum semua ahli memberikan pandangan'
    ),
    true,
    18,
    true
  ),
  (
    's1-01-q19',
    'topic-s1-01',
    'Yang manakah menunjukkan penggunaan maklumat secara beretika?',
    jsonb_build_array(
      'Menyatakan sumber dan tidak mengubah data untuk menyokong kesimpulan',
      'Menyalin maklumat tanpa memberikan pengiktirafan',
      'Memilih data yang hanya menyokong pendapat sendiri',
      'Mengubah angka supaya hasil kelihatan lebih meyakinkan'
    ),
    true,
    19,
    true
  ),
  (
    's1-01-q20',
    'topic-s1-01',
    'Sebuah pihak berkuasa tempatan ingin mengurangkan kesesakan lalu lintas. Apakah pendekatan paling sistematik?',
    jsonb_build_array(
      'Melaksanakan cadangan yang paling popular tanpa mengumpul data',
      'Menambah jalan raya tanpa mempertimbangkan pilihan lain',
      'Meniru tindakan bandar lain tanpa menilai keadaan tempatan',
      'Menganalisis data trafik, mengenal pasti punca, membandingkan alternatif dan memantau hasil'
    ),
    true,
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
    's1-01-q01',
    1,
    'Maklumat yang belum disahkan perlu diperiksa melalui sumber rasmi dan dibandingkan dengan sumber lain sebelum dipercayai atau disebarkan.'
  ),
  (
    's1-01-q02',
    2,
    'Transkrip temu bual asal ialah sumber primer kerana maklumat diperoleh secara langsung daripada responden.'
  ),
  (
    's1-01-q03',
    1,
    'Data ialah fakta atau angka mentah. Data yang disusun, dianalisis dan diberikan konteks menjadi maklumat yang bermakna.'
  ),
  (
    's1-01-q04',
    1,
    'Kewibawaan penulis, kemutakhiran sumber serta bukti dan rujukan membantu menentukan kebolehpercayaan. Bilangan perkongsian bukan ukuran ketepatan.'
  ),
  (
    's1-01-q05',
    0,
    'Bahasa emotif dan pemaparan satu sudut pandangan sahaja boleh menunjukkan kecenderungan atau berat sebelah.'
  ),
  (
    's1-01-q06',
    2,
    'Perbezaan angka boleh berpunca daripada definisi, kaedah, sampel atau tempoh rujukan yang berlainan. Faktor tersebut perlu disemak terlebih dahulu.'
  ),
  (
    's1-01-q07',
    3,
    'Sampel yang mewakili populasi dan soalan yang neutral dapat mengurangkan bias serta meningkatkan kebolehpercayaan hasil kaji selidik.'
  ),
  (
    's1-01-q08',
    1,
    'Nilai luar biasa tidak semestinya salah. Puncanya perlu disiasat dan ketepatannya disahkan sebelum dikekalkan atau dikeluarkan.'
  ),
  (
    's1-01-q09',
    2,
    'Hubungan antara dua pemboleh ubah tidak semestinya membuktikan sebab dan akibat kerana mungkin terdapat faktor lain yang mempengaruhi kedua-duanya.'
  ),
  (
    's1-01-q10',
    0,
    'Pemikiran kritis melibatkan penilaian bukti, andaian, alasan dan kesimpulan secara rasional sebelum sesuatu pandangan diterima.'
  ),
  (
    's1-01-q11',
    3,
    'Sumbang saran menggalakkan penghasilan banyak idea terlebih dahulu. Penilaian dibuat selepas proses menjana idea selesai.'
  ),
  (
    's1-01-q12',
    0,
    'Proses yang sistematik bermula dengan mengenal pasti masalah, diikuti analisis punca, penjanaan alternatif, pemilihan penyelesaian dan penilaian hasil.'
  ),
  (
    's1-01-q13',
    2,
    'Punca sebenar perlu dikenal pasti berdasarkan bukti seperti beban tugasan, tempoh yang diberikan, akses kemudahan dan pengurusan masa pelajar.'
  ),
  (
    's1-01-q14',
    1,
    'Alternatif perlu dibandingkan menggunakan kriteria objektif serta penilaian terhadap risiko, kesan dan kebolehlaksanaan.'
  ),
  (
    's1-01-q15',
    0,
    'Keputusan yang baik menggunakan bukti, membandingkan alternatif dan mempertimbangkan kesan kepada pihak berkepentingan. Tanggapan pertama sahaja tidak mencukupi.'
  ),
  (
    's1-01-q16',
    3,
    'Analisis kos dan faedah menilai sama ada manfaat yang dijangka setimpal dengan sumber, masa dan perbelanjaan yang diperlukan.'
  ),
  (
    's1-01-q17',
    2,
    'Dalam keadaan tidak pasti, keputusan boleh dibuat menggunakan bukti terbaik yang ada sambil menyediakan tindakan alternatif sekiranya keadaan berubah.'
  ),
  (
    's1-01-q18',
    1,
    'Pandangan berbeza dan penilaian bebas membantu ahli kumpulan mengesan kelemahan cadangan dan mengelakkan persetujuan tanpa penilaian.'
  ),
  (
    's1-01-q19',
    0,
    'Penggunaan maklumat secara beretika memerlukan sumber dinyatakan dan data dilaporkan dengan tepat tanpa dimanipulasi.'
  ),
  (
    's1-01-q20',
    3,
    'Pendekatan sistematik menggunakan data untuk mengenal pasti punca, menilai beberapa alternatif, melaksanakan tindakan dan memantau keberkesanannya.'
  )
on conflict (question_id)
do update set
  correct_option_index =
    excluded.correct_option_index,

  explanation =
    excluded.explanation;

commit;