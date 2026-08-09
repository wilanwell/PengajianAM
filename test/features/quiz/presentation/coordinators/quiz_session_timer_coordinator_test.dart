import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/coordinators/quiz_session_timer_coordinator.dart';

void main() {
  test('start menghasilkan tick selepas satu saat', () async {
    final coordinator = QuizSessionTimerCoordinator();

    addTearDown(coordinator.cancel);

    var remainingSeconds = 3;
    final tickValues = <int>[];
    var expiredCount = 0;

    coordinator.start(
      canContinue: () => true,
      readRemainingSeconds: () {
        return remainingSeconds;
      },
      onTick: (value) {
        remainingSeconds = value;
        tickValues.add(value);
      },
      onExpired: () {
        expiredCount++;
      },
    );

    expect(coordinator.isRunning, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 1150));

    expect(tickValues, [2]);

    expect(remainingSeconds, 2);

    expect(expiredCount, 0);

    expect(coordinator.isRunning, isTrue);
  });

  test('cancel menghentikan timer sebelum tick', () async {
    final coordinator = QuizSessionTimerCoordinator();

    addTearDown(coordinator.cancel);

    var remainingSeconds = 3;
    var tickCount = 0;
    var expiredCount = 0;

    coordinator.start(
      canContinue: () => true,
      readRemainingSeconds: () {
        return remainingSeconds;
      },
      onTick: (value) {
        remainingSeconds = value;
        tickCount++;
      },
      onExpired: () {
        expiredCount++;
      },
    );

    coordinator.cancel();

    expect(coordinator.isRunning, isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 1150));

    expect(tickCount, 0);

    expect(expiredCount, 0);

    expect(remainingSeconds, 3);
  });

  test('start baharu membatalkan timer sebelumnya', () async {
    final coordinator = QuizSessionTimerCoordinator();

    addTearDown(coordinator.cancel);

    var firstRemaining = 5;
    var secondRemaining = 4;

    var firstTickCount = 0;
    var secondTickCount = 0;

    coordinator.start(
      canContinue: () => true,
      readRemainingSeconds: () {
        return firstRemaining;
      },
      onTick: (value) {
        firstRemaining = value;
        firstTickCount++;
      },
      onExpired: () {},
    );

    /*
       * Mulakan timer kedua sebelum timer
       * pertama sempat menghasilkan tick.
       */
    await Future<void>.delayed(const Duration(milliseconds: 200));

    coordinator.start(
      canContinue: () => true,
      readRemainingSeconds: () {
        return secondRemaining;
      },
      onTick: (value) {
        secondRemaining = value;
        secondTickCount++;
      },
      onExpired: () {},
    );

    await Future<void>.delayed(const Duration(milliseconds: 1150));

    expect(firstTickCount, 0);

    expect(firstRemaining, 5);

    expect(secondTickCount, 1);

    expect(secondRemaining, 3);

    expect(coordinator.isRunning, isTrue);
  });

  test('expiry dipanggil sekali dan timer berhenti', () async {
    final coordinator = QuizSessionTimerCoordinator();

    addTearDown(coordinator.cancel);

    var remainingSeconds = 1;
    final tickValues = <int>[];
    var expiredCount = 0;

    coordinator.start(
      canContinue: () => true,
      readRemainingSeconds: () {
        return remainingSeconds;
      },
      onTick: (value) {
        remainingSeconds = value;
        tickValues.add(value);
      },
      onExpired: () {
        expiredCount++;
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 1250));

    expect(tickValues, [0]);

    expect(remainingSeconds, 0);

    expect(expiredCount, 1);

    expect(coordinator.isRunning, isFalse);

    /*
       * Tunggu melepasi satu interval tambahan.
       * Tiada expiry kedua sepatutnya berlaku.
       */
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(tickValues, [0]);

    expect(expiredCount, 1);

    expect(coordinator.isRunning, isFalse);
  });
}
