begin;

-- =========================================================
-- Format pernyataan gabungan S1-01 secara baris demi baris
-- =========================================================

update public.questions
set question_text =
  E'Antara berikut, yang manakah perlu dipertimbangkan untuk menilai kebolehpercayaan sesuatu sumber?\n\nI Kewibawaan penulis\nII Tarikh penerbitan\nIII Bukti dan rujukan yang digunakan\nIV Bilangan perkongsian dalam media sosial'
where id = 's1-01-q04';


update public.questions
set question_text =
  E'Yang manakah merupakan ciri pembuatan keputusan yang baik?\n\nI Berdasarkan bukti yang relevan\nII Membandingkan beberapa alternatif\nIII Mempertimbangkan kesan terhadap pihak berkepentingan\nIV Bergantung sepenuhnya pada tanggapan pertama'
where id = 's1-01-q15';

commit;