import 'package:flutter_test/flutter_test.dart';

import 'package:afinador/main.dart';

void main() {
  testWidgets('renderiza pantalla MVP del afinador', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Afinador MVP'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
  });
}
