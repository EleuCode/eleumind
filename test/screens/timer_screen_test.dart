import 'package:flutter_test/flutter_test.dart';
import 'package:eleumind/app.dart';

void main() {
  group('TimerScreen', () {
    testWidgets('shows 00:00 and Idle initially', (tester) async {
      await tester.pumpWidget(const EleuMindApp());
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('Idle'), findsOneWidget);
    });

    testWidgets('goes to Running when Start tapped', (tester) async {
      await tester.pumpWidget(const EleuMindApp());
      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('goes Paused then back to Idle via Stop', (tester) async {
      await tester.pumpWidget(const EleuMindApp());
      await tester.tap(find.text('Start'));
      await tester.pump();
      await tester.tap(find.text('Pause'));
      await tester.pump();
      await tester.tap(find.text('Stop'));
      await tester.pump();
      expect(find.text('Idle'), findsOneWidget);
    });
  });
}
