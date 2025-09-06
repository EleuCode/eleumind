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
import 'dart:ui';

enum TimerStatus { idle, running, paused }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  TimerStatus _status = TimerStatus.idle;

  String get _statusLabel {
    switch (_status) {
      case TimerStatus.running:
        return 'Running';
      case TimerStatus.paused:
        return 'Paused';
      case TimerStatus.idle:
      default:
        return 'Idle';
    }
  }

  void _onStart() => setState(() => _status = TimerStatus.running);
  void _onPause() => setState(() => _status = TimerStatus.paused);
  void _onStop() => setState(() => _status = TimerStatus.idle);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EleuMind'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Countdown placeholder.
                  ExcludeSemantics(
                    child: Text(
                      '00:00',
                      style: textTheme.displayLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_statusLabel, style: textTheme.titleMedium),
                  const SizedBox(height: 32),

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _onStart,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _onPause,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _onStop,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'UI scaffold only — countdown logic will be added later.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
