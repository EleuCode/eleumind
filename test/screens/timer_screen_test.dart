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
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TimerScreen', () {
    testWidgets('shows initial duration and Ready status', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EleuMindApp(),
        ),
      );

      expect(find.text('05:00'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
    });

    testWidgets('shows duration selector when idle', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EleuMindApp(),
        ),
      );

      expect(find.text('Select Duration'), findsOneWidget);
      expect(find.text('1 min'), findsOneWidget);
      expect(find.text('5 min'), findsOneWidget);
      expect(find.text('10 min'), findsOneWidget);
    });

    testWidgets('changes duration when chip is selected', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EleuMindApp(),
        ),
      );

      await tester.tap(find.text('10 min'));
      await tester.pump();

      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('goes to Running when Start tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EleuMindApp(),
        ),
      );

      await tester.tap(find.text('Start'));
      await tester.pump();

      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('hides duration selector when running', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EleuMindApp(),
        ),
      );

      await tester.tap(find.text('Start'));
      await tester.pump();

      expect(find.text('Select Duration'), findsNothing);
    });

    testWidgets('goes to Paused when Pause tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EleuMindApp(),
        ),
      );

      await tester.tap(find.text('Start'));
      await tester.pump();

      await tester.tap(find.text('Pause'));
      await tester.pump();

      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('resumes when Resume tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EleuMindApp(),
        ),
      );

      await tester.tap(find.text('Start'));
      await tester.pump();

      await tester.tap(find.text('Pause'));
      await tester.pump();

      await tester.tap(find.text('Resume'));
      await tester.pump();

      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('resets to Ready when Stop tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EleuMindApp(),
        ),
      );

      await tester.tap(find.text('Start'));
      await tester.pump();

      await tester.tap(find.text('Stop'));
      await tester.pump();

      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget);
    });

    testWidgets('countdown decrements while running (robust to alignment)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EleuMindApp(),
        ),
      );

      await tester.tap(find.text('1 min'));
      await tester.pump();

      await tester.tap(find.text('Start'));
      await tester.pump();

      final timerFinder = find.byKey(const Key('timerText'));
      expect(timerFinder, findsOneWidget);

      String read() => (tester.widget<Text>(timerFinder).data)!;
      final initial = read();
      expect(initial, anyOf('01:00', '00:59'));

      await tester.pump(const Duration(seconds: 2));
      final after = read();
      expect(after, isNot(initial));
    });
  });
}
