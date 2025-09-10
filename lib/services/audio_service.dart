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

import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _bell = AudioPlayer();
  final AudioPlayer _gong = AudioPlayer();

  bool _preloaded = false;

  Future<void> preload() async {
    if (_preloaded) return;
    await Future.wait([
      _bell.setAsset('assets/audio/bell.mp3'),
      _gong.setAsset('assets/audio/gong.mp3'),
    ]);
    _preloaded = true;
  }

  /// Plays the bell and resolves **after** the bell finishes, so consecutive calls are distinct.
  Future<void> playBell() async {
    if (!_preloaded) await preload();
    try {
      await _bell.seek(Duration.zero);
      await _bell.play();

      // Wait for completion so multiple backfilled bells are heard as separate chimes.
      await _bell.processingStateStream.firstWhere(
        (s) => s == ProcessingState.completed,
      );

      // Leave completed state to be ready for the next play on all platforms.
      await _bell.pause();
    } catch (_) {
      // Swallow audio errors so they don't crash the timer flow.
    }
  }

  /// Plays the gong and resolves **after** it finishes.
  Future<void> playGong() async {
    if (!_preloaded) await preload();
    try {
      await _gong.seek(Duration.zero);
      await _gong.play();

      await _gong.processingStateStream.firstWhere(
        (s) => s == ProcessingState.completed,
      );

      await _gong.pause();
    } catch (_) {
      // Swallow audio errors so they don't crash the timer flow.
    }
  }

  Future<void> dispose() async {
    await Future.wait([_bell.dispose(), _gong.dispose()]);
  }
}
