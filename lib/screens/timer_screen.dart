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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/timer_service.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(timerProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        notifier.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        notifier.onAppResumed();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);
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
                  // Timer duration selector (only visible when idle).
                  if (timerState.status == TimerStatus.idle) ...[
                    _DurationSelector(
                      duration: timerState.totalDuration,
                      onDurationChanged: (duration) {
                        timerNotifier.setDuration(duration);
                      },
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Countdown display.
                  ExcludeSemantics(
                    child: Text(
                      formatDuration(timerState.remainingDuration),
                      key: const Key('timerText'),
                      style: textTheme.displayLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status label.
                  Text(
                    _getStatusLabel(timerState.status),
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),

                  // Control buttons.
                  _ControlButtons(
                    status: timerState.status,
                    onStart: timerNotifier.start,
                    onPause: timerNotifier.pause,
                    onResume: timerNotifier.resume,
                    onStop: timerNotifier.stop,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(TimerStatus status) {
    switch (status) {
      case TimerStatus.running:
        return 'Running';
      case TimerStatus.paused:
        return 'Paused';
      case TimerStatus.idle:
        return 'Ready';
    }
  }
}

class _DurationSelector extends StatelessWidget {
  final Duration duration;
  final ValueChanged<Duration> onDurationChanged;

  const _DurationSelector({
    required this.duration,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Select Duration',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DurationChip(
              label: '1 min',
              duration: const Duration(minutes: 1),
              isSelected: duration == const Duration(minutes: 1),
              onSelected: onDurationChanged,
            ),
            _DurationChip(
              label: '5 min',
              duration: const Duration(minutes: 5),
              isSelected: duration == const Duration(minutes: 5),
              onSelected: onDurationChanged,
            ),
            _DurationChip(
              label: '10 min',
              duration: const Duration(minutes: 10),
              isSelected: duration == const Duration(minutes: 10),
              onSelected: onDurationChanged,
            ),
            _DurationChip(
              label: '15 min',
              duration: const Duration(minutes: 15),
              isSelected: duration == const Duration(minutes: 15),
              onSelected: onDurationChanged,
            ),
            _DurationChip(
              label: '20 min',
              duration: const Duration(minutes: 20),
              isSelected: duration == const Duration(minutes: 20),
              onSelected: onDurationChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final Duration duration;
  final bool isSelected;
  final ValueChanged<Duration> onSelected;

  const _DurationChip({
    required this.label,
    required this.duration,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(duration),
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final TimerStatus status;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const _ControlButtons({
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        if (status == TimerStatus.idle)
          ElevatedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
          ),
        if (status == TimerStatus.running)
          ElevatedButton.icon(
            onPressed: onPause,
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
          ),
        if (status == TimerStatus.paused) ...[
          ElevatedButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
          ),
          ElevatedButton.icon(
            onPressed: onStop,
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
          ),
        ],
        if (status == TimerStatus.running)
          ElevatedButton.icon(
            onPressed: onStop,
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
          ),
      ],
    );
  }
}
