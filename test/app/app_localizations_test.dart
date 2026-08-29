import 'package:afinador/app/app_localizations.dart';
import 'package:afinador/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAppLocale', () {
    test('usa español para cualquier variante regional es', () {
      const l10n = AppLocalizations(Locale('es'));
      expect(
        resolveAppLocale(
          const Locale('es', 'MX'),
          AppLocalizations.supportedLocales,
        ),
        const Locale('es'),
      );
      expect(l10n.ready, 'LISTO');
      expect(l10n.presetName('guitar_standard'), 'Guitarra (EADGBE)');
    });

    test('usa inglés para locales no soportados', () {
      expect(
        resolveAppLocale(
          const Locale('fr', 'FR'),
          AppLocalizations.supportedLocales,
        ),
        const Locale('en'),
      );
      expect(
        resolveAppLocale(null, AppLocalizations.supportedLocales),
        const Locale('en'),
      );
    });
  });

  testWidgets('MyApp sigue el idioma español del dispositivo', (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [
      Locale('es', 'ES'),
    ];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('AFINADOR'), findsOneWidget);
    expect(find.text('METRÓNOMO'), findsOneWidget);
  });

  testWidgets('MyApp usa inglés con locale no soportado', (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [
      Locale('de', 'DE'),
    ];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('TUNER'), findsOneWidget);
    expect(find.text('METRONOME'), findsOneWidget);
  });
}
