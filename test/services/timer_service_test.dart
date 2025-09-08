/*
 * EleuMind
 * A privacy-first, offline meditation timer.
 * 
 * Copyright (C) 2025 EleuCode
 *
 * This file is part of EleuMind.
 *
 * EleuMind is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * EleuMind is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with EleuMind.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:eleumind/services/timer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitForCondition(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 3),
  Duration pollEvery = const Duration(milliseconds: 25),
}) async {
  final start = DateTime.now();
  while (!condition()) {
    if (DateTime.now().difference(start) > timeout) {
      fail('Condition not met within $timeout');
    }
    await Future.delayed(pollEvery);
  }
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TimerNotifier', () {
    late TimerNotifier timerNotifier;

    setUp(() {
      timerNotifier = TimerNotifier();
    });

    tearDown(() {
      timerNotifier.dispose();
    });

    test('initial state is idle with 5 minutes duration', () {
      expect(timerNotifier.state.status, TimerStatus.idle);
      expect(timerNotifier.state.totalDuration, const Duration(minutes: 5));
      expect(timerNotifier.state.remainingDuration, const Duration(minutes: 5));
    });

    test('setDuration updates duration when idle', () {
      timerNotifier.setDuration(const Duration(minutes: 10));

      expect(timerNotifier.state.totalDuration, const Duration(minutes: 10));
      expect(
          timerNotifier.state.remainingDuration, const Duration(minutes: 10));
    });

    test('setDuration does not update when running', () {
      timerNotifier.start();
      timerNotifier.setDuration(const Duration(minutes: 10));

      expect(timerNotifier.state.totalDuration, const Duration(minutes: 5));
    });

    test('start changes status to running', () {
      timerNotifier.start();

      expect(timerNotifier.state.status, TimerStatus.running);
      expect(timerNotifier.state.startedAt, isNotNull);
    });

    test('pause changes status to paused', () {
      timerNotifier.start();
      timerNotifier.pause();

      expect(timerNotifier.state.status, TimerStatus.paused);
    });

    test('resume from pause changes status back to running', () {
      timerNotifier.start();
      timerNotifier.pause();
      timerNotifier.resume();

      expect(timerNotifier.state.status, TimerStatus.running);
    });

    test('stop resets to initial state', () {
      timerNotifier.setDuration(const Duration(minutes: 10));
      timerNotifier.start();
      timerNotifier.stop();

      expect(timerNotifier.state.status, TimerStatus.idle);
      expect(timerNotifier.state.totalDuration, const Duration(minutes: 10));
      expect(
          timerNotifier.state.remainingDuration, const Duration(minutes: 10));
    });

    test('multiple pause/resume cycles maintain correct time (approx)',
        () async {
      timerNotifier.setDuration(const Duration(seconds: 4));
      timerNotifier.start();
      await Future.delayed(const Duration(milliseconds: 400));
      timerNotifier.pause();
      final firstPauseRemaining = timerNotifier.state.remainingDuration;

      await Future.delayed(const Duration(milliseconds: 400));
      expect(timerNotifier.state.remainingDuration, firstPauseRemaining);

      timerNotifier.resume();
      await Future.delayed(const Duration(milliseconds: 400));
      timerNotifier.pause();
      final secondPauseRemaining = timerNotifier.state.remainingDuration;

      expect(secondPauseRemaining.inMilliseconds,
          lessThan(firstPauseRemaining.inMilliseconds));
    });

    test('timer updates remaining time while running', () async {
      timerNotifier.setDuration(const Duration(seconds: 2));
      timerNotifier.start();

      final initialRemaining = timerNotifier.state.remainingDuration;
      await Future.delayed(const Duration(milliseconds: 1200));
      final afterDelay = timerNotifier.state.remainingDuration;

      expect(
          afterDelay.inMilliseconds, lessThan(initialRemaining.inMilliseconds));
    });

    test('timer completes and returns to idle when time runs out', () async {
      timerNotifier.setDuration(const Duration(milliseconds: 900));
      timerNotifier.start();

      await _waitForCondition(
        () => timerNotifier.state.status == TimerStatus.idle,
        timeout: const Duration(seconds: 3),
      );

      expect(timerNotifier.state.status, TimerStatus.idle);
      expect(timerNotifier.state.remainingDuration, Duration.zero);
    });
  });

  group('Lifecycle + recompute', () {
    test('rehydrates and recomputes after background/foreground with no drift',
        () async {
      DateTime t0 = DateTime(2025, 1, 1, 12, 0, 0);

      DateTime now() => t0;

      final notifier = TimerNotifier(now: now);
      notifier.setDuration(const Duration(seconds: 10));
      notifier.start();

      // Simulate 3s running, then app pause (persist)
      t0 = t0.add(const Duration(seconds: 3));
      await notifier.onAppPaused();

      // Background for 5s (no timers running)
      t0 = t0.add(const Duration(seconds: 5));

      // Foreground (restore + recompute)
      await notifier.onAppResumed();

      // Remaining should be 10 - 8 = 2s
      expect(notifier.state.remainingDuration.inSeconds, 2);
      expect(notifier.state.status, TimerStatus.running);

      notifier.dispose();
    });

    test('process kill safety: new instance can resume from persisted snapshot',
        () async {
      DateTime t0 = DateTime(2025, 1, 1, 12, 0, 0);

      DateTime now() => t0;

      // Instance A
      final a = TimerNotifier(now: now);
      a.setDuration(const Duration(seconds: 6));
      a.start();

      // Run 2s then pause app (persist)
      t0 = t0.add(const Duration(seconds: 2));
      await a.onAppPaused();
      a.dispose();

      // Background for 3s
      t0 = t0.add(const Duration(seconds: 3));

      // Instance B (like cold start)
      final b = TimerNotifier(now: now);
      await b.onAppResumed();

      // Should have 6 - 5 = 1s left and running
      expect(b.state.remainingDuration.inSeconds, 1);
      expect(b.state.status, TimerStatus.running);
      b.dispose();
    });
  });

  group('formatDuration', () {
    test('formats duration correctly', () {
      expect(formatDuration(const Duration(minutes: 5, seconds: 30)), '05:30');
      expect(formatDuration(const Duration(minutes: 0, seconds: 5)), '00:05');
      expect(formatDuration(const Duration(minutes: 10)), '10:00');
      expect(formatDuration(const Duration(hours: 1, minutes: 5)), '65:00');
    });
  });
}
