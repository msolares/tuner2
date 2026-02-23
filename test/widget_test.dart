import 'package:flutter_test/flutter_test.dart';

import 'package:afinador/main.dart';

void main() {
  testWidgets('renderiza pantalla redisenada del afinador', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('CHROMATIC TUNER'), findsOneWidget);
    expect(find.text('AUTO'), findsOneWidget);
    expect(find.text('TUNER'), findsOneWidget);
  });
}
