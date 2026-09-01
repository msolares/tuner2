import 'package:afinador/data/learning/catalog/asset_lesson_catalog.dart';
import 'package:afinador/data/learning/musicxml/musicxml_document_decoder.dart';
import 'package:afinador/data/learning/musicxml/musicxml_lesson_chart_decoder.dart';
import 'package:afinador/data/learning/musicxml/musicxml_timeline_normalizer.dart';
import 'package:afinador/domain/learning/learning.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetLessonCatalog', () {
    final catalog = AssetLessonCatalog(rootBundle);
    final lessonId = LessonId(AssetLessonCatalog.pentatonicLessonId);

    test('lists the normative local metadata without leaking an asset path',
        () async {
      final lessons = await ListLessonsUseCase(catalog)();

      expect(lessons, hasLength(1));
      expect(
        lessons.single,
        LessonSummary(
          id: lessonId,
          title: 'Pentatonica menor de La',
          subtitle: 'Primera posicion · nota a nota',
          sequenceIndex: 0,
          estimatedMinutes: 3,
          kind: LessonKind.exercise,
        ),
      );
      expect(
        '${lessons.single.title} ${lessons.single.subtitle}',
        isNot(anyOf(contains('/'), contains('.musicxml'))),
      );
      expect(() => lessons.clear(), throwsUnsupportedError);
    });

    test('loads and decodes the initial lesson through the domain ports',
        () async {
      final chart = await LoadLessonUseCase(
        catalog,
        MusicXmlLessonChartDecoder(),
      )(lessonId, options: LessonImportOptions());

      expect(chart.id, lessonId);
      expect(chart.events, hasLength(23));
      expect(chart.events, everyElement(isA<LessonNoteEvent>()));
      expect(chart.events.whereType<LessonChordEvent>(), isEmpty);
      expect(chart.totalTicks, 23040);
    });

    test('the owned lesson parses without diagnostics', () async {
      final document = await catalog.getById(lessonId);
      final options = LessonImportOptions();
      final result = MusicXmlTimelineNormalizer().normalizeWithDiagnostics(
        MusicXmlDocumentDecoder().decode(document, options),
        document,
        options,
      );

      expect(document.sourceName, 'pentatonica-menor-la-posicion-1.musicxml');
      expect(result.diagnostics, isEmpty);
      expect(
        result.chart.events.whereType<LessonNoteEvent>().map(
              (event) => (
                event.midi,
                event.position.stringNumber,
                event.position.fret,
              ),
            ),
        hasLength(23),
      );
    });

    test('returns typed errors for unknown IDs and unavailable assets',
        () async {
      await expectLater(
        catalog.getById(LessonId('missing')),
        throwsA(_lessonError(LessonErrorCode.lessonNotFound)),
      );
      await expectLater(
        AssetLessonCatalog(_FailingAssetBundle()).getById(lessonId),
        throwsA(_lessonError(LessonErrorCode.lessonCatalogUnavailable)),
      );
    });
  });
}

Matcher _lessonError(LessonErrorCode code) => isA<LessonException>().having(
      (error) => error.code,
      'code',
      code,
    );

final class _FailingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => Future.error(StateError(key));
}
