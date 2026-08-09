import 'dart:async';

final class QuizSessionTimerCoordinator {
  Timer? _timer;

  bool get isRunning {
    return _timer?.isActive ?? false;
  }

  void start({
    required bool Function() canContinue,
    required int? Function() readRemainingSeconds,
    required void Function(int remainingSeconds) onTick,
    required void Function() onExpired,
  }) {
    cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      /*
         * Controller kekal menjadi autoriti
         * terhadap status sesi.
         *
         * Coordinator hanya mengurus lifecycle
         * timer dan tidak mengetahui Riverpod
         * atau QuizSessionState.
         */
      if (!canContinue()) {
        cancel();
        return;
      }

      final remainingSeconds = readRemainingSeconds();

      if (remainingSeconds == null) {
        cancel();
        return;
      }

      final nextValue = remainingSeconds - 1;

      if (nextValue <= 0) {
        onTick(0);

        /*
           * Timer dihentikan sebelum callback
           * expiry supaya hanya satu expiry
           * boleh dicetuskan.
           */
        cancel();

        onExpired();
        return;
      }

      onTick(nextValue);
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
