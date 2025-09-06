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

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TimerStatus { idle, running, paused }

class TimerState {
  final Duration totalDuration;
  final Duration remainingDuration;
  final TimerStatus status;
  final DateTime? startedAt;
  final Duration? pausedDuration;

  const TimerState({
    required this.totalDuration,
    required this.remainingDuration,
    required this.status,
    this.startedAt,
    this.pausedDuration,
  });

  TimerState copyWith({
    Duration? totalDuration,
    Duration? remainingDuration,
    TimerStatus? status,
    DateTime? startedAt,
    Duration? pausedDuration,
  }) {
    return TimerState(
      totalDuration: totalDuration ?? this.totalDuration,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      pausedDuration: pausedDuration ?? this.pausedDuration,
    );
  }

  static TimerState initial({Duration duration = const Duration(minutes: 5)}) {
    return TimerState(
      totalDuration: duration,
      remainingDuration: duration,
      status: TimerStatus.idle,
    );
  }
}

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _ticker;

  TimerNotifier() : super(TimerState.initial());

  void setDuration(Duration duration) {
    if (state.status == TimerStatus.idle) {
      state = TimerState(
        totalDuration: duration,
        remainingDuration: duration,
        status: TimerStatus.idle,
      );
    }
  }

  void start() {
    if (state.status == TimerStatus.idle) {
      state = state.copyWith(
        status: TimerStatus.running,
        startedAt: DateTime.now(),
        pausedDuration: Duration.zero,
      );
      _startTicker();
    } else if (state.status == TimerStatus.paused) {
      resume();
    }
  }

  void pause() {
    if (state.status == TimerStatus.running) {
      _ticker?.cancel();
      
      // Calculate elapsed time since start or last resume.
      final elapsed = DateTime.now().difference(state.startedAt!);
      final totalElapsed = elapsed + (state.pausedDuration ?? Duration.zero);
      final remaining = state.totalDuration - totalElapsed;

      state = state.copyWith(
        status: TimerStatus.paused,
        remainingDuration: remaining.isNegative ? Duration.zero : remaining,
        pausedDuration: totalElapsed,
      );
    }
  }

  void resume() {
    if (state.status == TimerStatus.paused) {
      state = state.copyWith(
        status: TimerStatus.running,
        startedAt: DateTime.now(),
        // Keep the pausedDuration to calculate total elapsed correctly.
      );
      _startTicker();
    }
  }

  void stop() {
    _ticker?.cancel();
    state = TimerState.initial(duration: state.totalDuration);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    if (state.status != TimerStatus.running) return;

    // Wall-clock safe calculation.
    final elapsed = DateTime.now().difference(state.startedAt!);
    final totalElapsed = elapsed + (state.pausedDuration ?? Duration.zero);
    final remaining = state.totalDuration - totalElapsed;

    if (remaining <= Duration.zero) {
      _ticker?.cancel();
      state = state.copyWith(
        remainingDuration: Duration.zero,
        status: TimerStatus.idle,
      );
      // Timer completed - could trigger a callback here.
    } else {
      state = state.copyWith(remainingDuration: remaining);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

// Provider definition.
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier();
});

// Convenience providers.
final timerStatusProvider = Provider<TimerStatus>((ref) {
  return ref.watch(timerProvider).status;
});

final remainingDurationProvider = Provider<Duration>((ref) {
  return ref.watch(timerProvider).remainingDuration;
});

// Format duration for display (total minutes:seconds).
String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
