import '../entities/mistake_book_snapshot.dart';

abstract interface class MistakeBookRepository {
  Future<MistakeBookSnapshot> fetchMistakeBook();
}
