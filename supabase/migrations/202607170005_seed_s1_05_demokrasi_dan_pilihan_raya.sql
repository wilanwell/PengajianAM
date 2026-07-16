begin;

-- =========================================================
-- S1-05 DEMOKRASI DAN PILIHAN RAYA
--
-- Skop:
-- 1. Konsep demokrasi
-- 2. Peranan pilihan raya
-- 3. Fungsi Suruhanjaya Pilihan Raya
-- 4. Sistem majoriti mudah
-- 5. Pilihan Raya Umum dan Pilihan Raya Kecil
-- 6. Pemilih dan pendaftaran pemilih
-- 7. Calon pilihan raya
-- 8. Proses pilihan raya
-- 9. Pengundian dan pengiraan undi
-- 10. Petisyen dan persempadanan
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
    's1-05-q01',
    'topic-s1-05',
    'Apakah ciri paling asas sesebuah negara yang mengamalkan demokrasi?',
    jsonb_build_array(
      'Rakyat mempunyai hak memilih wakil melalui pilihan raya',
      'Semua keputusan dibuat oleh sebuah parti sahaja',
      'Kuasa pemerintahan diwarisi tanpa had',
      'Rakyat tidak dibenarkan menyuarakan pandangan'
    ),
    true,
    1,
    true
  ),
  (
    's1-05-q02',
    'topic-s1-05',
    'Mengapakah pilihan raya penting dalam sistem demokrasi?',
    jsonb_build_array(
      'Membolehkan rakyat memilih wakil untuk menjalankan pemerintahan',
      'Menghapuskan keperluan kepada badan perundangan',
      'Memberikan kuasa tanpa had kepada calon yang menang',
      'Membolehkan mahkamah menentukan semua dasar kerajaan'
    ),
    true,
    2,
    true
  ),
  (
    's1-05-q03',
    'topic-s1-05',
    E'Yang manakah merupakan fungsi Suruhanjaya Pilihan Raya?\n\nI Mengurus pendaftaran pemilih\nII Menjalankan pilihan raya umum dan pilihan raya kecil\nIII Menjalankan kajian semula persempadanan bahagian pilihan raya\nIV Menentukan keputusan petisyen pilihan raya',
    jsonb_build_array(
      'I dan II',
      'I, II dan III',
      'II, III dan IV',
      'I, III dan IV'
    ),
    false,
    3,
    true
  ),
  (
    's1-05-q04',
    'topic-s1-05',
    'Apakah maksud sistem majoriti mudah atau First-Past-The-Post yang digunakan dalam pilihan raya Malaysia?',
    jsonb_build_array(
      'Calon yang memperoleh undi terbanyak dalam bahagian pilihan raya diisytiharkan menang',
      'Calon mesti memperoleh lebih daripada dua pertiga jumlah undi',
      'Kerusi dibahagikan mengikut peratus undi setiap parti di seluruh negara',
      'Calon yang mendapat undi kedua tertinggi turut diberikan kerusi'
    ),
    true,
    4,
    true
  ),
  (
    's1-05-q05',
    'topic-s1-05',
    'Bilakah Pilihan Raya Umum diadakan?',
    jsonb_build_array(
      'Apabila berlaku kekosongan satu kerusi sahaja',
      'Apabila Parlimen atau Dewan Undangan Negeri dibubarkan atau tamat tempohnya',
      'Apabila sebuah parti politik menukar pemimpin',
      'Apabila keputusan pilihan raya dicabar oleh seorang pemilih'
    ),
    true,
    5,
    true
  ),
  (
    's1-05-q06',
    'topic-s1-05',
    E'Yang manakah boleh menyebabkan Pilihan Raya Kecil diadakan?\n\nI Kematian wakil rakyat\nII Perletakan jawatan wakil rakyat\nIII Wakil rakyat hilang kelayakan\nIV Pembubaran seluruh Parlimen',
    jsonb_build_array(
      'I dan II',
      'I, II dan III',
      'II, III dan IV',
      'I, III dan IV'
    ),
    false,
    6,
    true
  ),
  (
    's1-05-q07',
    'topic-s1-05',
    'Yang manakah merupakan syarat asas untuk didaftarkan sebagai pemilih?',
    jsonb_build_array(
      'Warganegara Malaysia, berumur sekurang-kurangnya 18 tahun, bermastautin dan tidak hilang kelayakan',
      'Warganegara Malaysia, berumur sekurang-kurangnya 21 tahun dan memiliki pekerjaan tetap',
      'Penduduk tetap, berumur sekurang-kurangnya 18 tahun dan membayar cukai',
      'Mana-mana individu yang telah menetap di Malaysia melebihi lima tahun'
    ),
    true,
    7,
    true
  ),
  (
    's1-05-q08',
    'topic-s1-05',
    'Pernyataan manakah yang tepat tentang pendaftaran pemilih baharu di Malaysia?',
    jsonb_build_array(
      'Setiap pemilih mesti mengemukakan permohonan pada setiap pilihan raya',
      'Pendaftaran hanya dilakukan selepas Parlimen dibubarkan',
      'Warganegara yang mencapai umur 18 tahun dan memenuhi syarat didaftarkan secara automatik',
      'Pendaftaran hanya dibenarkan kepada ahli parti politik'
    ),
    true,
    8,
    true
  ),
  (
    's1-05-q09',
    'topic-s1-05',
    'Apakah maklumat utama yang digunakan untuk menentukan bahagian pilihan raya seseorang pemilih?',
    jsonb_build_array(
      'Alamat tempat kerja pemilih',
      'Alamat mastautin yang direkodkan dengan Jabatan Pendaftaran Negara',
      'Lokasi institusi pendidikan pemilih',
      'Alamat ibu pejabat parti politik pilihannya'
    ),
    true,
    9,
    true
  ),
  (
    's1-05-q10',
    'topic-s1-05',
    E'Yang manakah merupakan jenis pengundian yang digunakan dalam pilihan raya Malaysia?\n\nI Pengundian biasa\nII Pengundian awal\nIII Pengundian pos\nIV Pengundian melalui wakil bebas',
    jsonb_build_array(
      'I dan II',
      'I, II dan III',
      'II, III dan IV',
      'I, III dan IV'
    ),
    false,
    10,
    true
  ),
  (
    's1-05-q11',
    'topic-s1-05',
    'Siapakah yang lazimnya terlibat dalam pengundian awal?',
    jsonb_build_array(
      'Semua pemilih yang berumur antara 18 hingga 21 tahun',
      'Anggota tentera dan pasangan serta anggota polis dan pasangan tertentu yang layak',
      'Semua kakitangan swasta yang bekerja pada hari mengundi',
      'Semua calon dan ejen pilihan raya'
    ),
    true,
    11,
    true
  ),
  (
    's1-05-q12',
    'topic-s1-05',
    'Yang manakah merupakan kelayakan asas untuk menjadi calon pilihan raya Dewan Rakyat?',
    jsonb_build_array(
      'Warganegara Malaysia, bermastautin dalam Persekutuan dan berumur sekurang-kurangnya 18 tahun pada hari penamaan calon',
      'Warganegara Malaysia yang berumur sekurang-kurangnya 25 tahun dan bekerja dalam sektor awam',
      'Pemastautin tetap yang berumur sekurang-kurangnya 18 tahun',
      'Mana-mana pemilih berdaftar yang mendapat sokongan sebuah kementerian'
    ),
    true,
    12,
    true
  ),
  (
    's1-05-q13',
    'topic-s1-05',
    'Pilih urutan proses pilihan raya yang paling sesuai.',
    jsonb_build_array(
      'Pembubaran atau kekosongan, pengeluaran writ, penamaan calon, kempen, pengundian, pengiraan undi dan pengisytiharan keputusan',
      'Kempen, pembubaran, pengiraan undi, penamaan calon, pengundian dan pengeluaran writ',
      'Penamaan calon, pengundian, pembubaran, kempen, pengiraan undi dan pengeluaran writ',
      'Pengundian, penamaan calon, kempen, pembubaran, pengeluaran writ dan pengiraan undi'
    ),
    false,
    13,
    true
  ),
  (
    's1-05-q14',
    'topic-s1-05',
    'Apakah tujuan utama kempen pilihan raya?',
    jsonb_build_array(
      'Membolehkan calon dan parti menerangkan dasar serta mendapatkan sokongan pemilih',
      'Membolehkan calon menentukan tempat mengundi setiap pemilih',
      'Membolehkan parti mengubah daftar pemilih',
      'Membolehkan calon mengisytiharkan keputusan sebelum pengundian'
    ),
    true,
    14,
    true
  ),
  (
    's1-05-q15',
    'topic-s1-05',
    'Mengapakah kerahsiaan undi perlu dipelihara?',
    jsonb_build_array(
      'Supaya pemilih bebas membuat pilihan tanpa tekanan atau ancaman',
      'Supaya keputusan pilihan raya tidak perlu diumumkan',
      'Supaya hanya calon mengetahui jumlah undi',
      'Supaya pemilih boleh mengundi lebih daripada sekali'
    ),
    true,
    15,
    true
  ),
  (
    's1-05-q16',
    'topic-s1-05',
    'Apakah tujuan ejen calon dibenarkan menyaksikan proses pengiraan undi?',
    jsonb_build_array(
      'Untuk mengubah keputusan yang tidak memihak kepada calon mereka',
      'Untuk memastikan proses pengiraan dilaksanakan secara telus dan mengikut peraturan',
      'Untuk menentukan sama ada pilihan raya perlu ditangguhkan',
      'Untuk menambah kertas undi yang dianggap tidak mencukupi'
    ),
    true,
    16,
    true
  ),
  (
    's1-05-q17',
    'topic-s1-05',
    'Bagaimanakah keputusan sesuatu pilihan raya boleh dicabar secara sah?',
    jsonb_build_array(
      'Melalui petisyen pilihan raya di Mahkamah Pilihan Raya',
      'Melalui undian semula yang dianjurkan oleh parti politik',
      'Melalui keputusan Jemaah Menteri',
      'Melalui pungutan suara dalam media sosial'
    ),
    true,
    17,
    true
  ),
  (
    's1-05-q18',
    'topic-s1-05',
    'Apakah tujuan utama kajian semula persempadanan bahagian pilihan raya?',
    jsonb_build_array(
      'Menentukan sempadan dan susunan bahagian pilihan raya yang sesuai',
      'Menentukan parti yang akan memenangi pilihan raya',
      'Menghapuskan semua bahagian pilihan raya negeri',
      'Menentukan calon yang layak menerima undi pos'
    ),
    true,
    18,
    true
  ),
  (
    's1-05-q19',
    'topic-s1-05',
    'Apakah maksud perwakilan wilayah seorang ahli bagi setiap bahagian pilihan raya?',
    jsonb_build_array(
      'Setiap bahagian pilihan raya memilih seorang wakil untuk mewakili kawasan tersebut',
      'Setiap calon boleh mewakili beberapa bahagian pilihan raya serentak',
      'Setiap bahagian pilihan raya memilih semua anggota Jemaah Menteri',
      'Setiap negeri hanya dibenarkan mempunyai seorang wakil rakyat'
    ),
    true,
    19,
    true
  ),
  (
    's1-05-q20',
    'topic-s1-05',
    E'Yang manakah mencerminkan pelaksanaan pilihan raya yang demokratik?\n\nI Pemilih bebas memilih calon\nII Proses pengundian dan pengiraan dilaksanakan secara telus\nIII Pilihan raya diadakan mengikut Perlembagaan dan undang-undang\nIV Pemilih dipaksa menyokong pihak tertentu',
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
    's1-05-q01',
    0,
    'Demokrasi memberikan rakyat hak untuk memilih wakil yang akan mewakili kepentingan mereka dalam pemerintahan.'
  ),
  (
    's1-05-q02',
    0,
    'Pilihan raya membolehkan rakyat menentukan wakil yang akan menjalankan tanggungjawab perundangan dan pemerintahan.'
  ),
  (
    's1-05-q03',
    1,
    'SPR mengurus pendaftaran pemilih, menjalankan pilihan raya dan melaksanakan kajian semula persempadanan. Petisyen pilihan raya diputuskan oleh Mahkamah Pilihan Raya.'
  ),
  (
    's1-05-q04',
    0,
    'Dalam sistem majoriti mudah, calon yang memperoleh undi paling banyak dalam sesuatu bahagian pilihan raya diisytiharkan sebagai pemenang.'
  ),
  (
    's1-05-q05',
    1,
    'Pilihan Raya Umum diadakan apabila Parlimen atau Dewan Undangan Negeri dibubarkan atau terbubar selepas tamat tempohnya.'
  ),
  (
    's1-05-q06',
    1,
    'Pilihan Raya Kecil boleh diadakan apabila berlaku kematian, perletakan jawatan atau kehilangan kelayakan wakil rakyat. Pembubaran seluruh Parlimen membawa kepada Pilihan Raya Umum.'
  ),
  (
    's1-05-q07',
    0,
    'Pemilih mestilah warganegara Malaysia, berumur sekurang-kurangnya 18 tahun, bermastautin dalam sesuatu bahagian pilihan raya dan tidak hilang kelayakan.'
  ),
  (
    's1-05-q08',
    2,
    'Pendaftaran pemilih baharu dilaksanakan secara automatik bagi warganegara yang mencapai umur 18 tahun dan memenuhi syarat undang-undang.'
  ),
  (
    's1-05-q09',
    1,
    'Bahagian pilihan raya pemilih ditentukan berdasarkan alamat mastautin terkini yang direkodkan dengan Jabatan Pendaftaran Negara.'
  ),
  (
    's1-05-q10',
    1,
    'Bentuk pengundian yang digunakan ialah pengundian biasa, pengundian awal dan pengundian pos. Pengundian melalui wakil bebas bukan kategori pengundian.'
  ),
  (
    's1-05-q11',
    1,
    'Pengundian awal disediakan kepada kategori tertentu seperti anggota tentera dan pasangan serta anggota polis dan pasangan tertentu yang layak.'
  ),
  (
    's1-05-q12',
    0,
    'Calon Dewan Rakyat mestilah warganegara Malaysia, bermastautin dalam Persekutuan dan berumur sekurang-kurangnya 18 tahun pada hari penamaan calon.'
  ),
  (
    's1-05-q13',
    0,
    'Proses bermula dengan pembubaran atau kekosongan, diikuti writ, penamaan calon, kempen, pengundian, pengiraan undi dan pengisytiharan keputusan.'
  ),
  (
    's1-05-q14',
    0,
    'Kempen memberikan ruang kepada calon dan parti untuk menerangkan dasar, manifesto serta mendapatkan sokongan pemilih.'
  ),
  (
    's1-05-q15',
    0,
    'Kerahsiaan undi memastikan pemilih boleh membuat pilihan secara bebas tanpa tekanan, ancaman atau campur tangan pihak lain.'
  ),
  (
    's1-05-q16',
    1,
    'Kehadiran ejen membantu memastikan proses pengiraan undi dapat diperhatikan dan dilaksanakan secara telus mengikut peraturan.'
  ),
  (
    's1-05-q17',
    0,
    'Keputusan pilihan raya dicabar melalui petisyen pilihan raya yang dikemukakan kepada Mahkamah Pilihan Raya.'
  ),
  (
    's1-05-q18',
    0,
    'Kajian semula persempadanan bertujuan menyemak sempadan dan susunan bahagian pilihan raya supaya proses perwakilan dapat dilaksanakan dengan sesuai.'
  ),
  (
    's1-05-q19',
    0,
    'Malaysia menggunakan perwakilan wilayah seorang ahli, iaitu setiap bahagian pilihan raya memilih seorang wakil.'
  ),
  (
    's1-05-q20',
    0,
    'Pilihan raya demokratik memberikan kebebasan memilih, dilaksanakan secara telus dan mematuhi Perlembagaan serta undang-undang. Paksaan bercanggah dengan prinsip demokrasi.'
  )
on conflict (question_id)
do update set
  correct_option_index =
    excluded.correct_option_index,

  explanation =
    excluded.explanation;

commit;