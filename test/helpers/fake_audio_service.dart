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

import 'package:eleumind/services/audio_service.dart';

class CountingFakeAudioService implements AudioService {
  int bellCount = 0;
  int gongCount = 0;

  @override
  Future<void> preload() async {}

  @override
  Future<void> playBell() async {
    bellCount++;
  }

  @override
  Future<void> playGong() async {
    gongCount++;
  }

  @override
  Future<void> dispose() async {}
}
