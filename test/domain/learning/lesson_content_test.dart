import 'package:afinador/domain/learning/learning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lesson content contracts', () {
    test('summary validates metadata and uses value equality', () {
      final summary = LessonSummary(
        id: LessonId('pentatonic-a-minor-position-1'),
        title: 'Pentatonica menor de La',
        subtitle: 'Primera posicion',
        sequenceIndex: 0,
        estimatedMinutes: 3,
        kind: LessonKind.exercise,
      );

      expect(summary, summary.copyWith());
      expect(summary.copyWith(estimatedMinutes: 4).estimatedMinutes, 4);
      expect(
        () => summary.copyWith(sequenceIndex: -1),
        throwsRangeError,
      );
      expect(
        () => summary.copyWith(estimatedMinutes: 0),
        throwsRangeError,
      );
      expect(() => summary.copyWith(title: ' '), throwsArgumentError);
    });

    test('document copies bytes defensively and rejects invalid content', () {
      final source = <int>[60, 63, 120, 109, 108, 62];
      final document = LessonDocument(
        id: LessonId('lesson'),
        sourceName: 'lesson.musicxml',
        bytes: source,
      );
      source[0] = 0;

      expect(document.bytes.first, 60);
      expect(() => document.bytes.add(1), throwsUnsupportedError);
      expect(document, document.copyWith());
      expect(
        () => LessonDocument(
          id: LessonId('lesson'),
          sourceName: 'lesson.musicxml',
          bytes: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => document.copyWith(bytes: const [256]),
        throwsArgumentError,
      );
    });

    test('import options reject blank selectors', () {
      final options = LessonImportOptions(partId: 'P1', sectionTitle: 'Intro');
      expect(options, LessonImportOptions(partId: 'P1', sectionTitle: 'Intro'));
      expect(options.copyWith(partId: null).partId, isNull);
      expect(options.copyWith(sectionTitle: null).sectionTitle, isNull);
      expect(() => LessonImportOptions(partId: ''), throwsArgumentError);
      expect(
        () => LessonImportOptions(sectionTitle: '   '),
        throwsArgumentError,
      );
    });
  });
}
