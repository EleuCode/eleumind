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
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

typedef Now = DateTime Function();

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _ticker;
  final Now _now;

  TimerNotifier({Now now = DateTime.now})
      : _now = now,
        super(TimerState.initial());

  static const _prefsKey = 'eleumind.timer.v1';

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
        startedAt: _now(),
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
      final elapsed = _now().difference(state.startedAt!);
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
        startedAt: _now(),
      );
      _startTicker();
    }
  }

  void stop() {
    _ticker?.cancel();
    state = TimerState.initial(duration: state.totalDuration);
  }

  Future<void> onAppPaused() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _toPersistable(state);
    await prefs.setString(_prefsKey, raw);
    _ticker?.cancel();
  }

  Future<void> onAppResumed() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null) return;

    final restored = _fromPersistable(saved);
    if (restored != null) {
      final recomputed = _recompute(restored);
      state = recomputed;
      if (state.status == TimerStatus.running) {
        _startTicker();
      }
    }
    await prefs.remove(_prefsKey);
  }

  void _startTicker() {
    _ticker?.cancel();

    final now = _now();
    final msToNextSecond = 1000 - now.millisecond;
    final adjusted = msToNextSecond - (now.microsecond > 0 ? 1 : 0);
    final initialDelay = Duration(milliseconds: adjusted.clamp(1, 1000));

    _ticker = Timer(initialDelay, () {
      _updateRemainingTime();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateRemainingTime();
      });
    });
  }

  void _updateRemainingTime() {
    if (state.status != TimerStatus.running) return;

    final elapsed = _now().difference(state.startedAt!);
    final totalElapsed = elapsed + (state.pausedDuration ?? Duration.zero);
    final remaining = state.totalDuration - totalElapsed;

    if (remaining <= Duration.zero) {
      _ticker?.cancel();
      state = state.copyWith(
        remainingDuration: Duration.zero,
        status: TimerStatus.idle,
      );
    } else {
      state = state.copyWith(remainingDuration: remaining);
    }
  }

  TimerState _recompute(TimerState snapshot) {
    if (snapshot.status == TimerStatus.running) {
      final elapsed = _now().difference(snapshot.startedAt!);
      final totalElapsed = elapsed + (snapshot.pausedDuration ?? Duration.zero);
      final remaining = snapshot.totalDuration - totalElapsed;
      if (remaining <= Duration.zero) {
        return snapshot.copyWith(
          status: TimerStatus.idle,
          remainingDuration: Duration.zero,
        );
      }
      return snapshot.copyWith(remainingDuration: remaining);
    }
    return snapshot;
  }

  String _toPersistable(TimerState s) {
    final json = {
      'total': s.totalDuration.inMilliseconds,
      'remaining': s.remainingDuration.inMilliseconds,
      'status': s.status.index,
      'startedAt': s.startedAt?.toIso8601String(),
      'paused': s.pausedDuration?.inMilliseconds,
    };
    return jsonEncode(json);
  }

  TimerState? _fromPersistable(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return TimerState(
        totalDuration: Duration(milliseconds: j['total'] as int),
        remainingDuration: Duration(milliseconds: j['remaining'] as int),
        status: TimerStatus.values[j['status'] as int],
        startedAt: (j['startedAt'] as String?) != null
            ? DateTime.parse(j['startedAt'] as String)
            : null,
        pausedDuration: (j['paused'] as int?) != null
            ? Duration(milliseconds: j['paused'] as int)
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier();
});

final timerStatusProvider = Provider<TimerStatus>((ref) {
  return ref.watch(timerProvider).status;
});

final remainingDurationProvider = Provider<Duration>((ref) {
  return ref.watch(timerProvider).remainingDuration;
});

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
