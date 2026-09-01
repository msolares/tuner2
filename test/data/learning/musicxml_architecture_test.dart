import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MusicXML parser types remain owned by Data', () {
    for (final root in const ['lib/domain', 'lib/presentation', 'lib/app']) {
      for (final file in _dartFiles(root)) {
        final source = file.readAsStringSync();
        expect(
          source,
          isNot(contains("package:xml/")),
          reason: '${file.path} must not import XML parser types',
        );
      }
    }

    for (final file in _dartFiles('lib/data/learning')) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains("package:afinador/presentation/")),
        reason: '${file.path} must not import Presentation',
      );
      expect(
        source,
        isNot(contains("package:afinador/app/")),
        reason: '${file.path} must not import the composition root',
      );
    }
  });
}

Iterable<File> _dartFiles(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));
