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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eleumind/app.dart';
import 'package:eleumind/services/audio_service_provider.dart';
import 'package:eleumind/services/timer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/fake_audio_service.dart';

late DateTime _t0;
DateTime _fakeNow() => _t0;

// Give listeners/microtasks a moment to run.
Future<void> _flush(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

/// Advance logical time by [delta] (in 1s steps so periodic timers tick)
/// and pump the tester to deliver timer callbacks.
Future<void> _advance(WidgetTester tester, Duration delta) async {
  final secs = delta.inSeconds;
  for (var i = 0; i < secs; i++) {
    _t0 = _t0.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }
  final leftoverMs = delta.inMilliseconds - secs * 1000;
  if (leftoverMs > 0) {
    _t0 = _t0.add(Duration(milliseconds: leftoverMs));
    await tester.pump(Duration(milliseconds: leftoverMs));
  }
}

/// Wait long enough for N bells in the backfill **sequence** to complete.
/// In app code, we space bells by ~500ms. We add slack.
Future<void> _waitForBellSequence(WidgetTester tester, int bells) async {
  if (bells <= 0) return;
  await tester.pump(Duration(milliseconds: 600 * bells));
  await _flush(tester);
}

ProviderScope _scopeWith({
  required CountingFakeAudioService audioFake,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      audioServiceProvider.overrideWithValue(audioFake),
      timerProvider.overrideWith((ref) => TimerNotifier(now: _fakeNow)),
    ],
    child: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    // Stable starting instant for the fake clock.
    _t0 = DateTime(2025, 1, 1, 12, 0, 0);
  });

  testWidgets('Bells chime each minute with backfill (no duplicates)',
      (tester) async {
    final audio = CountingFakeAudioService();
    await tester
        .pumpWidget(_scopeWith(audioFake: audio, child: const EleuMindApp()));

    // Select a long session (20 min)
    await tester.tap(find.text('20 min'));
    await tester.pump();

    await tester.tap(find.text('Start'));
    await tester.pump();

    // Arm the first aligned tick.
    await _advance(tester, const Duration(milliseconds: 1200));

    // Advance 5 minutes -> expect bells at 1,2,3,4,5 (5 total).
    await _advance(tester, const Duration(minutes: 5));
    await _waitForBellSequence(tester, 5);
    expect(audio.bellCount, 5);

    // Advancing a few seconds within the same minute shouldn't add bells.
    await _advance(tester, const Duration(seconds: 5));
    await _flush(tester);
    expect(audio.bellCount, 5);

    // Advance 2 more minutes -> bells at 6 and 7 (2 more, total 7).
    await _advance(tester, const Duration(minutes: 2));
    await _waitForBellSequence(tester, 2);
    expect(audio.bellCount, 7);
  });

  testWidgets('Gong plays exactly once at finish (no interval bell at finish)',
      (tester) async {
    final audio = CountingFakeAudioService();
    await tester
        .pumpWidget(_scopeWith(audioFake: audio, child: const EleuMindApp()));

    // 1-minute session
    await tester.tap(find.text('1 min'));
    await tester.pump();

    await tester.tap(find.text('Start'));
    await tester.pump();

    await _advance(tester, const Duration(milliseconds: 1200)); // arm tick.

    // Approach finish
    await _advance(tester, const Duration(seconds: 58));
    expect(audio.gongCount, 0);

    // Cross finish and wait a beat
    await _advance(tester, const Duration(seconds: 3));
    await _flush(tester);

    expect(audio.gongCount, 1);
    expect(audio.bellCount,
        0); // interval is 1 minute; we clamp away finish-bucket.
  });

  testWidgets('STOP resets bell index so next session rings again',
      (tester) async {
    final audio = CountingFakeAudioService();
    await tester
        .pumpWidget(_scopeWith(audioFake: audio, child: const EleuMindApp()));

    await tester.tap(find.text('20 min'));
    await tester.pump();

    await tester.tap(find.text('Start'));
    await tester.pump();

    await _advance(tester, const Duration(milliseconds: 1200)); // arm tick.

    // First session: 5 minutes -> 5 bells.
    await _advance(tester, const Duration(minutes: 5));
    await _waitForBellSequence(tester, 5);
    expect(audio.bellCount, 5);

    // STOP resets the bucket.
    await tester.tap(find.text('Stop'));
    await tester.pump();
    await _flush(tester);

    // New session.
    await tester.tap(find.text('Start'));
    await tester.pump();
    await _advance(tester, const Duration(milliseconds: 1200)); // arm tick.

    // Another 5 minutes -> +5 bells (total 10).
    await _advance(tester, const Duration(minutes: 5));
    await _waitForBellSequence(tester, 5);
    expect(audio.bellCount, 10);
  });
}
