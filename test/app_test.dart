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
import 'package:eleumind/screens/timer_screen.dart';
import 'package:eleumind/services/audio_service.dart';
import 'package:eleumind/services/audio_service_provider.dart';

class _FakeAudioService implements AudioService {
  @override
  Future<void> dispose() async {}
  @override
  Future<void> playBell() async {}
  @override
  Future<void> playGong() async {}
  @override
  Future<void> preload() async {}
}

void main() {
  testWidgets('App provides a MaterialApp shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(_FakeAudioService()),
        ],
        child: const EleuMindApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App uses dark theme mode by default', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(_FakeAudioService()),
        ],
        child: const EleuMindApp(),
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('App home is TimerScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(_FakeAudioService()),
        ],
        child: const EleuMindApp(),
      ),
    );

    expect(find.byType(TimerScreen), findsOneWidget);
  });
}
