import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/exceptions/mistake_book_failure.dart';
import 'mistake_book_controller.dart';
import 'mistake_book_topic_state.dart';

final mistakeBookTopicControllerProvider =
    NotifierProvider<MistakeBookTopicController, MistakeBookTopicState>(
      MistakeBookTopicController.new,
    );

class MistakeBookTopicController extends Notifier<MistakeBookTopicState> {
  Future<void>? _activeRequest;

  String? _activeTopicId;

  int _requestGeneration = 0;

  @override
  MistakeBookTopicState build() {
    ref.onDispose(() {
      _requestGeneration++;
      _activeRequest = null;
      _activeTopicId = null;
    });

    return const MistakeBookTopicState();
  }

  Future<void> loadTopic(String topicId, {bool forceRefresh = false}) {
    final normalizedTopicId = topicId.trim();

    if (normalizedTopicId.isEmpty) {
      _requestGeneration++;
      _activeRequest = null;
      _activeTopicId = null;

      state = const MistakeBookTopicState(
        status: MistakeBookTopicStatus.failure,
        topicId: '',
        errorMessage: 'Topik Buku Kesilapan tidak sah.',
      );

      return Future<void>.value();
    }

    final currentRequest = _activeRequest;

    if (!forceRefresh &&
        currentRequest != null &&
        _activeTopicId == normalizedTopicId) {
      return currentRequest;
    }

    if (!forceRefresh &&
        state.status == MistakeBookTopicStatus.success &&
        state.topicId == normalizedTopicId) {
      return Future<void>.value();
    }

    late final Future<void> request;

    request = _loadInternal(normalizedTopicId).whenComplete(() {
      if (identical(_activeRequest, request)) {
        _activeRequest = null;
        _activeTopicId = null;
      }
    });

    _activeRequest = request;
    _activeTopicId = normalizedTopicId;

    return request;
  }

  Future<void> _loadInternal(String topicId) async {
    final requestGeneration = ++_requestGeneration;

    final existingDetail = state.detail?.topicId == topicId
        ? state.detail
        : null;

    state = MistakeBookTopicState(
      status: MistakeBookTopicStatus.loading,
      topicId: topicId,
      detail: existingDetail,
    );

    late final MistakeBookTopicState resultState;

    try {
      final detail = await ref
          .read(mistakeBookRepositoryProvider)
          .fetchMistakeBookTopic(topicId);

      resultState = MistakeBookTopicState(
        status: MistakeBookTopicStatus.success,
        topicId: topicId,
        detail: detail,
      );
    } on MistakeBookFailure catch (error) {
      resultState = MistakeBookTopicState(
        status: MistakeBookTopicStatus.failure,
        topicId: topicId,
        detail: existingDetail,
        errorMessage: error.message,
      );
    } catch (_) {
      resultState = MistakeBookTopicState(
        status: MistakeBookTopicStatus.failure,
        topicId: topicId,
        detail: existingDetail,
        errorMessage:
            'Butiran topik Buku Kesilapan tidak dapat '
            'dimuatkan. Sila cuba semula.',
      );
    }

    if (requestGeneration == _requestGeneration) {
      state = resultState;
    }
  }

  Future<void> refreshTopic(String topicId) {
    return loadTopic(topicId, forceRefresh: true);
  }

  void reset() {
    _requestGeneration++;
    _activeRequest = null;
    _activeTopicId = null;

    state = const MistakeBookTopicState();
  }
}
