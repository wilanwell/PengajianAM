import '../../domain/entities/mistake_book_snapshot.dart';

enum MistakeBookStatus { initial, loading, success, failure }

class MistakeBookState {
  const MistakeBookState({
    this.status = MistakeBookStatus.initial,
    this.snapshot,
    this.errorMessage,
  });

  final MistakeBookStatus status;

  final MistakeBookSnapshot? snapshot;

  final String? errorMessage;

  bool get isLoading {
    return status == MistakeBookStatus.loading;
  }
}
