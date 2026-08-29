import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:afinador/main.dart';
import 'package:afinador/presentation/screens/metronome_screen.dart';
import 'package:afinador/presentation/screens/tuner_screen.dart';

void main() {
  testWidgets('renderiza shell principal WeBand', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(TunerScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('tuner-brand-logo')), findsOneWidget);
    expect(find.text('AUTO'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-tuner')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-metronome')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-metronome')));
    await tester.pumpAndSettle();

    expect(find.byType(MetronomeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('metronome-tempo-card')), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
  });
}
