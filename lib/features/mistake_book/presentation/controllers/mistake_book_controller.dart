import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/presentation/providers/network_request_executor_provider.dart';
import '../../../../core/services/supabase_client_provider.dart';
import '../../data/repositories/supabase_mistake_book_repository.dart';
import '../../domain/exceptions/mistake_book_failure.dart';
import '../../domain/repositories/mistake_book_repository.dart';
import 'mistake_book_state.dart';

final mistakeBookRepositoryProvider = Provider<MistakeBookRepository>((ref) {
  return SupabaseMistakeBookRepository(
    ref.read(supabaseClientProvider),
    ref.read(networkRequestExecutorProvider),
  );
});

final mistakeBookControllerProvider =
    NotifierProvider<MistakeBookController, MistakeBookState>(
      MistakeBookController.new,
    );

class MistakeBookController extends Notifier<MistakeBookState> {
  Future<void>? _activeRequest;

  int _requestGeneration = 0;

  MistakeBookRepository get _repository {
    return ref.read(mistakeBookRepositoryProvider);
  }

  @override
  MistakeBookState build() {
    ref.onDispose(() {
      _requestGeneration++;
      _activeRequest = null;
    });

    return const MistakeBookState();
  }

  Future<void> loadMistakeBook({bool forceRefresh = false}) {
    final currentRequest = _activeRequest;

    if (!forceRefresh && currentRequest != null) {
      return currentRequest;
    }

    if (!forceRefresh && state.status == MistakeBookStatus.success) {
      return Future<void>.value();
    }

    late final Future<void> request;

    request = _loadInternal().whenComplete(() {
      if (identical(_activeRequest, request)) {
        _activeRequest = null;
      }
    });

    _activeRequest = request;

    return request;
  }

  Future<void> _loadInternal() async {
    final requestGeneration = ++_requestGeneration;

    final existingSnapshot = state.snapshot;

    state = MistakeBookState(
      status: MistakeBookStatus.loading,
      snapshot: existingSnapshot,
    );

    late final MistakeBookState resultState;

    try {
      final snapshot = await _repository.fetchMistakeBook();

      resultState = MistakeBookState(
        status: MistakeBookStatus.success,
        snapshot: snapshot,
      );
    } on MistakeBookFailure catch (error) {
      resultState = MistakeBookState(
        status: MistakeBookStatus.failure,
        snapshot: existingSnapshot,
        errorMessage: error.message,
      );
    } catch (_) {
      resultState = MistakeBookState(
        status: MistakeBookStatus.failure,
        snapshot: existingSnapshot,
        errorMessage:
            'Buku Kesilapan tidak dapat '
            'dimuatkan. Sila cuba semula.',
      );
    }

    if (requestGeneration == _requestGeneration) {
      state = resultState;
    }
  }

  Future<void> refreshMistakeBook() {
    return loadMistakeBook(forceRefresh: true);
  }

  void reset() {
    _requestGeneration++;
    _activeRequest = null;

    state = const MistakeBookState();
  }
}
