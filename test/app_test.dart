import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eleumind/app.dart';
import 'package:eleumind/screens/timer_screen.dart';

void main() {
  testWidgets('App provides a MaterialApp shell', (tester) async {
    await tester.pumpWidget(const EleuMindApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App uses dark theme mode by default', (tester) async {
    await tester.pumpWidget(const EleuMindApp());
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('App home is TimerScreen', (tester) async {
    await tester.pumpWidget(const EleuMindApp());
    expect(find.byType(TimerScreen), findsOneWidget);
  });
}
