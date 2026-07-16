begin;

-- =========================================================
-- S1-07 KEDAULATAN MALAYSIA
--
-- Skop:
-- 1. Konsep kedaulatan dan keutuhan wilayah
-- 2. Ancaman dalaman dan luaran
-- 3. Pertahanan dan keselamatan sempadan
-- 4. Kestabilan politik
-- 5. Ketahanan ekonomi
-- 6. Integrasi dan perpaduan
-- 7. Sosial dan budaya
-- 8. Keselamatan siber dan maklumat
-- 9. Sains, teknologi dan inovasi
-- 10. Peranan kerajaan, masyarakat dan rakyat
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
    's1-07-q01',
    'topic-s1-07',
    'Apakah maksud paling tepat bagi kedaulatan Malaysia?',
    jsonb_build_array(
      'Keupayaan negara membuat keputusan dan mentadbir tanpa dikawal oleh kuasa luar',
      'Kebebasan kerajaan bertindak tanpa mematuhi undang-undang',
      'Keupayaan negara menguasai wilayah negara lain',
      'Kebebasan rakyat daripada semua bentuk tanggungjawab'
    ),
    true,
    1,
    true
  ),
  (
    's1-07-q02',
    'topic-s1-07',
    E'Yang manakah penting untuk mengekalkan kedaulatan negara?\n\nI Keutuhan wilayah\nII Pemerintahan yang berkesan\nIII Perpaduan rakyat\nIV Kebergantungan mutlak kepada kuasa asing',
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
    's1-07-q03',
    'topic-s1-07',
    'Apakah tujuan utama kawalan keselamatan di sempadan darat, laut dan udara?',
    jsonb_build_array(
      'Menghentikan semua pergerakan antara negara',
      'Melindungi wilayah serta mengawal kemasukan manusia dan barangan',
      'Menghapuskan kegiatan perdagangan antarabangsa',
      'Menyerahkan urusan keselamatan kepada negara jiran'
    ),
    true,
    3,
    true
  ),
  (
    's1-07-q04',
    'topic-s1-07',
    'Sebuah kapal asing memasuki perairan negara tanpa kebenaran. Apakah tindakan paling sesuai?',
    jsonb_build_array(
      'Mengabaikan kejadian tersebut untuk mengelakkan ketegangan',
      'Menyebarkan maklumat yang belum disahkan kepada orang ramai',
      'Mengambil tindakan penguatkuasaan, mengumpul bukti dan menggunakan saluran diplomatik serta undang-undang',
      'Menghentikan semua hubungan dengan negara asal kapal tersebut'
    ),
    true,
    4,
    true
  ),
  (
    's1-07-q05',
    'topic-s1-07',
    E'Yang manakah boleh mengancam keselamatan dan kedaulatan negara dari dalam?\n\nI Kegiatan ekstremisme\nII Sabotaj terhadap kemudahan penting\nIII Penyebaran maklumat palsu yang mencetuskan konflik\nIV Perbincangan awam yang berasaskan fakta',
    jsonb_build_array(
      'I dan II',
      'I, II dan III',
      'II, III dan IV',
      'I, III dan IV'
    ),
    false,
    5,
    true
  ),
  (
    's1-07-q06',
    'topic-s1-07',
    'Bagaimanakah kestabilan politik membantu memelihara kedaulatan negara?',
    jsonb_build_array(
      'Membolehkan pentadbiran dan dasar keselamatan dilaksanakan secara berterusan',
      'Menghapuskan peranan undang-undang dan institusi negara',
      'Membolehkan semua keputusan dibuat oleh pihak luar',
      'Mengurangkan keperluan kepada perpaduan rakyat'
    ),
    true,
    6,
    true
  ),
  (
    's1-07-q07',
    'topic-s1-07',
    'Mengapakah kebergantungan ekonomi yang berlebihan kepada satu kuasa asing boleh menjadi risiko?',
    jsonb_build_array(
      'Negara tidak lagi memerlukan perdagangan antarabangsa',
      'Pihak luar mungkin mempunyai pengaruh besar terhadap keputusan dan dasar negara',
      'Semua pelaburan asing akan dihentikan secara automatik',
      'Kerajaan tidak perlu membangunkan industri tempatan'
    ),
    true,
    7,
    true
  ),
  (
    's1-07-q08',
    'topic-s1-07',
    'Yang manakah paling berkesan untuk meningkatkan ketahanan ekonomi negara?',
    jsonb_build_array(
      'Bergantung pada satu sumber pendapatan sahaja',
      'Mengimport semua barangan keperluan tanpa membangunkan kapasiti tempatan',
      'Mempelbagaikan ekonomi, meningkatkan produktiviti dan memperkukuh industri strategik',
      'Menghentikan semua hubungan perdagangan dengan negara lain'
    ),
    true,
    8,
    true
  ),
  (
    's1-07-q09',
    'topic-s1-07',
    'Apakah kesan penyeludupan barangan kawalan dan sumber negara?',
    jsonb_build_array(
      'Meningkatkan hasil kerajaan',
      'Mengurangkan ketirisan dan menstabilkan bekalan',
      'Mengukuhkan pengurusan sempadan',
      'Menyebabkan kerugian negara, ketirisan subsidi dan gangguan bekalan'
    ),
    true,
    9,
    true
  ),
  (
    's1-07-q10',
    'topic-s1-07',
    'Bagaimanakah perpaduan masyarakat berbilang kaum menyumbang kepada kedaulatan Malaysia?',
    jsonb_build_array(
      'Mengurangkan rasa saling mempercayai',
      'Mengukuhkan kestabilan, kerjasama dan ketahanan negara',
      'Menghapuskan kepelbagaian budaya',
      'Mengehadkan penyertaan rakyat dalam masyarakat'
    ),
    true,
    10,
    true
  ),
  (
    's1-07-q11',
    'topic-s1-07',
    'Apakah pendekatan terbaik untuk mempertahankan identiti dan budaya negara dalam era globalisasi?',
    jsonb_build_array(
      'Menolak semua unsur budaya luar tanpa penilaian',
      'Menggantikan semua budaya tempatan dengan budaya antarabangsa',
      'Memelihara warisan tempatan sambil menerima unsur luar yang sesuai secara terpilih',
      'Mengehadkan penglibatan generasi muda dalam kegiatan kebudayaan'
    ),
    true,
    11,
    true
  ),
  (
    's1-07-q12',
    'topic-s1-07',
    'Sistem bekalan air, tenaga dan komunikasi negara diserang melalui rangkaian komputer. Apakah jenis ancaman tersebut?',
    jsonb_build_array(
      'Ancaman keselamatan siber terhadap infrastruktur kritikal',
      'Ancaman kebudayaan tradisional',
      'Pertikaian pilihan raya',
      'Masalah perdagangan biasa'
    ),
    true,
    12,
    true
  ),
  (
    's1-07-q13',
    'topic-s1-07',
    E'Yang manakah dapat memperkukuh keselamatan siber negara?\n\nI Melindungi data dan sistem kritikal\nII Mengemas kini sistem dan perisian keselamatan\nIII Meningkatkan kesedaran serta kemahiran digital\nIV Berkongsi kata laluan dengan pihak lain',
    jsonb_build_array(
      'I dan II',
      'I, II dan III',
      'II, III dan IV',
      'I, III dan IV'
    ),
    false,
    13,
    true
  ),
  (
    's1-07-q14',
    'topic-s1-07',
    'Maklumat palsu mengenai isu keselamatan tersebar dengan pantas dalam media sosial. Apakah tindakan paling bertanggungjawab?',
    jsonb_build_array(
      'Menyebarkannya supaya orang ramai dapat membuat keputusan sendiri',
      'Menambah maklumat yang belum disahkan supaya lebih menarik',
      'Menyemak sumber rasmi, tidak menyebarkannya dan melaporkan kandungan yang berbahaya',
      'Menganggap semua maklumat dalam media sosial adalah benar'
    ),
    true,
    14,
    true
  ),
  (
    's1-07-q15',
    'topic-s1-07',
    'Bagaimanakah sains, teknologi dan inovasi membantu mempertahankan kedaulatan negara?',
    jsonb_build_array(
      'Dengan mengurangkan keupayaan pemantauan keselamatan',
      'Dengan meningkatkan kebergantungan mutlak kepada teknologi asing',
      'Dengan menggantikan semua pertimbangan manusia',
      'Dengan meningkatkan pemantauan, komunikasi, analisis data dan keupayaan tindak balas'
    ),
    true,
    15,
    true
  ),
  (
    's1-07-q16',
    'topic-s1-07',
    'Mengapakah jaminan bekalan makanan penting kepada keselamatan dan kedaulatan negara?',
    jsonb_build_array(
      'Memastikan rakyat memperoleh bekalan mencukupi ketika berlaku gangguan atau krisis',
      'Membolehkan negara menghentikan semua aktiviti pertanian',
      'Menghapuskan keperluan menyimpan stok makanan',
      'Memastikan negara hanya bergantung pada makanan import'
    ),
    true,
    16,
    true
  ),
  (
    's1-07-q17',
    'topic-s1-07',
    E'Yang manakah merupakan ancaman keselamatan bukan tradisional?\n\nI Wabak penyakit\nII Bencana alam\nIII Jenayah siber\nIV Pencerobohan tentera asing',
    jsonb_build_array(
      'I dan II',
      'I, II dan III',
      'II, III dan IV',
      'I, III dan IV'
    ),
    false,
    17,
    true
  ),
  (
    's1-07-q18',
    'topic-s1-07',
    'Mengapakah kerjasama antarabangsa diperlukan dalam menangani jenayah rentas sempadan?',
    jsonb_build_array(
      'Jenayah tersebut melibatkan lebih daripada satu bidang kuasa dan memerlukan perkongsian maklumat serta tindakan bersama',
      'Kerjasama antarabangsa membolehkan negara menyerahkan seluruh kuasanya',
      'Jenayah rentas sempadan hanya boleh ditangani oleh organisasi swasta',
      'Kerjasama tersebut menghapuskan keperluan kepada undang-undang negara'
    ),
    true,
    18,
    true
  ),
  (
    's1-07-q19',
    'topic-s1-07',
    E'Yang manakah merupakan tanggungjawab rakyat dalam memelihara kedaulatan Malaysia?\n\nI Mematuhi undang-undang\nII Menjaga perpaduan\nIII Melaporkan kegiatan yang mengancam keselamatan\nIV Menyebarkan maklumat sulit negara',
    jsonb_build_array(
      'I dan II',
      'I, II dan III',
      'II, III dan IV',
      'I, III dan IV'
    ),
    false,
    19,
    true
  ),
  (
    's1-07-q20',
    'topic-s1-07',
    'Pilih urutan tindakan yang paling sistematik apabila negara menghadapi ancaman baharu.',
    jsonb_build_array(
      'Kenal pasti ancaman, nilai risiko, selaras tindakan, laksanakan respons dan pantau hasil',
      'Laksanakan respons, abaikan risiko, kenal pasti ancaman dan hentikan pemantauan',
      'Pantau hasil, tamatkan tindakan, nilai risiko dan kenal pasti ancaman',
      'Sebarkan maklumat, abaikan bukti, laksanakan tindakan dan nilai ancaman'
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
    's1-07-q01',
    0,
    'Kedaulatan bermaksud negara mempunyai kuasa tertinggi untuk mentadbir dan menentukan dasarnya tanpa dikawal oleh kuasa luar.'
  ),
  (
    's1-07-q02',
    1,
    'Keutuhan wilayah, pemerintahan berkesan dan perpaduan rakyat membantu mengekalkan kedaulatan. Kebergantungan mutlak kepada kuasa asing boleh melemahkannya.'
  ),
  (
    's1-07-q03',
    1,
    'Kawalan sempadan melindungi wilayah negara dan memastikan pergerakan manusia serta barangan berlaku mengikut undang-undang.'
  ),
  (
    's1-07-q04',
    2,
    'Pencerobohan perlu ditangani melalui penguatkuasaan, pengumpulan bukti, undang-undang dan saluran diplomatik secara tersusun.'
  ),
  (
    's1-07-q05',
    1,
    'Ekstremisme, sabotaj dan maklumat palsu yang mencetuskan konflik boleh mengancam keselamatan negara. Perbincangan berasaskan fakta menyokong proses demokratik.'
  ),
  (
    's1-07-q06',
    0,
    'Kestabilan politik membolehkan institusi berfungsi dan dasar keselamatan serta pembangunan dilaksanakan secara konsisten.'
  ),
  (
    's1-07-q07',
    1,
    'Kebergantungan berlebihan boleh memberikan pihak luar pengaruh ekonomi yang digunakan untuk mempengaruhi keputusan atau dasar negara.'
  ),
  (
    's1-07-q08',
    2,
    'Ekonomi yang pelbagai, produktif dan mempunyai industri strategik lebih mampu menghadapi kejutan serta tekanan dari luar.'
  ),
  (
    's1-07-q09',
    3,
    'Penyeludupan menyebabkan kehilangan hasil, ketirisan subsidi, gangguan bekalan dan kerugian kepada ekonomi negara.'
  ),
  (
    's1-07-q10',
    1,
    'Perpaduan meningkatkan kepercayaan, kerjasama dan kestabilan masyarakat, sekali gus memperkukuh ketahanan negara.'
  ),
  (
    's1-07-q11',
    2,
    'Identiti negara dapat dipelihara dengan memartabatkan warisan tempatan sambil menilai unsur luar secara rasional dan terpilih.'
  ),
  (
    's1-07-q12',
    0,
    'Serangan terhadap sistem bekalan air, tenaga atau komunikasi melalui rangkaian komputer merupakan ancaman siber terhadap infrastruktur kritikal.'
  ),
  (
    's1-07-q13',
    1,
    'Perlindungan sistem, pengemaskinian keselamatan dan peningkatan literasi digital mengurangkan risiko siber. Kata laluan tidak patut dikongsi.'
  ),
  (
    's1-07-q14',
    2,
    'Maklumat keselamatan perlu disemak melalui sumber rasmi. Kandungan palsu tidak patut disebarkan dan kandungan berbahaya wajar dilaporkan.'
  ),
  (
    's1-07-q15',
    3,
    'Teknologi membantu pemantauan sempadan, komunikasi, risikan, analisis data dan tindak balas terhadap ancaman dengan lebih pantas.'
  ),
  (
    's1-07-q16',
    0,
    'Jaminan makanan memastikan bekalan asas terus tersedia ketika berlaku gangguan perdagangan, bencana atau krisis.'
  ),
  (
    's1-07-q17',
    1,
    'Wabak penyakit, bencana alam dan jenayah siber ialah ancaman bukan tradisional. Pencerobohan tentera ialah ancaman keselamatan tradisional.'
  ),
  (
    's1-07-q18',
    0,
    'Jenayah rentas sempadan melibatkan beberapa negara dan memerlukan perkongsian risikan, penyelarasan penguatkuasaan serta bantuan perundangan.'
  ),
  (
    's1-07-q19',
    1,
    'Rakyat membantu memelihara kedaulatan dengan mematuhi undang-undang, menjaga perpaduan dan melaporkan ancaman. Maklumat sulit tidak boleh disebarkan.'
  ),
  (
    's1-07-q20',
    0,
    'Pengurusan ancaman yang sistematik bermula dengan mengenal pasti ancaman, menilai risiko, menyelaras pihak berkaitan, bertindak dan memantau hasil.'
  )
on conflict (question_id)
do update set
  correct_option_index =
    excluded.correct_option_index,

  explanation =
    excluded.explanation;

commit;