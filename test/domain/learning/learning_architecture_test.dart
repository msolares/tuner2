import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('learning domain has no forbidden layer or platform imports', () {
    final directory = Directory('lib/domain/learning');
    final dartFiles = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final forbiddenFragments = <String>[
      'package:flutter/',
      'package:flutter_bloc/',
      '/data/',
      '/presentation/',
      '/app/',
      'dart:ffi',
      'dart:html',
      'package:xml/',
      'package:ffi/',
    ];

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      for (final fragment in forbiddenFragments) {
        expect(
          source,
          isNot(contains(fragment)),
          reason: '${file.path} contiene dependencia prohibida $fragment',
        );
      }
    }
  });
}
