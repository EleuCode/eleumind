/*
 * EleuMind - AudioService
 * Plays local asset sounds for interval bells and end gong.
 */

import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _bell = AudioPlayer();
  final AudioPlayer _gong = AudioPlayer();

  bool _preloaded = false;

  Future<void> preload() async {
    if (_preloaded) return;
    // Preload both assets so playback is instant.
    await Future.wait([
      _bell.setAsset('assets/audio/bell.mp3'),
      _gong.setAsset('assets/audio/gong.mp3'),
    ]);
    _preloaded = true;
  }

  Future<void> playBell() async {
    if (!_preloaded) await preload();
    // For rapid taps, stop any current playback first to retrigger promptly.
    try {
      await _bell.seek(Duration.zero);
      await _bell.play();
    } catch (_) {}
  }

  Future<void> playGong() async {
    if (!_preloaded) await preload();
    try {
      await _gong.seek(Duration.zero);
      await _gong.play();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await Future.wait([_bell.dispose(), _gong.dispose()]);
  }
}
