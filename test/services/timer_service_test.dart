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

void main() {
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
      expect(timerNotifier.state.remainingDuration, const Duration(minutes: 10));
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
      expect(timerNotifier.state.remainingDuration, const Duration(minutes: 10));
    });

    test('multiple pause/resume cycles maintain correct time', () async {
      timerNotifier.setDuration(const Duration(seconds: 10));
      
      // Start timer.
      timerNotifier.start();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // First pause.
      timerNotifier.pause();
      final firstPauseRemaining = timerNotifier.state.remainingDuration;
      expect(firstPauseRemaining.inMilliseconds, 
             lessThan(const Duration(seconds: 10).inMilliseconds));
      
      // Wait while paused (time should not decrease).
      await Future.delayed(const Duration(milliseconds: 500));
      expect(timerNotifier.state.remainingDuration, firstPauseRemaining);
      
      // Resume.
      timerNotifier.resume();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Second pause.
      timerNotifier.pause();
      final secondPauseRemaining = timerNotifier.state.remainingDuration;
      expect(secondPauseRemaining.inMilliseconds, 
             lessThan(firstPauseRemaining.inMilliseconds));
    });

    test('timer updates remaining time while running', () async {
      timerNotifier.setDuration(const Duration(seconds: 5));
      timerNotifier.start();
      
      final initialRemaining = timerNotifier.state.remainingDuration;
      await Future.delayed(const Duration(milliseconds: 500));
      final afterDelay = timerNotifier.state.remainingDuration;
      
      expect(afterDelay.inMilliseconds, 
             lessThan(initialRemaining.inMilliseconds));
    });

    test('timer completes and returns to idle when time runs out', () async {
      timerNotifier.setDuration(const Duration(milliseconds: 500));
      timerNotifier.start();
      
      await Future.delayed(const Duration(seconds: 1));
      
      expect(timerNotifier.state.status, TimerStatus.idle);
      expect(timerNotifier.state.remainingDuration, Duration.zero);
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