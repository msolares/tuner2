import 'dart:convert';
import 'dart:io';

import 'package:afinador/data/learning/musicxml/musicxml_document_decoder.dart';
import 'package:afinador/data/learning/musicxml/musicxml_lesson_chart_decoder.dart';
import 'package:afinador/data/learning/musicxml/musicxml_timeline_normalizer.dart';
import 'package:afinador/domain/learning/learning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MusicXmlLessonChartDecoder', () {
    final decoder = MusicXmlLessonChartDecoder();

    test('normalizes the initial pentatonic lesson', () {
      final chart = decoder.decode(
        _document('docs/partituras/pentatonica-menor-la-posicion-1.musicxml'),
        LessonImportOptions(sectionTitle: 'Pentatonica menor de La'),
      );

      expect(chart.schemaVersion, 1);
      expect(chart.title, 'Pentatonica menor de La');
      expect(chart.totalTicks, 23040);
      expect(chart.events, hasLength(23));
      expect(chart.events, everyElement(isA<LessonNoteEvent>()));
      expect(chart.tempoMap, [TempoPoint(tick: 0, bpm: 70)]);
      expect(
        chart.meterMap,
        [MeterPoint(tick: 0, numerator: 4, denominator: 4)],
      );
      expect(
        chart.tuning.strings.map((string) => string.openMidi),
        [64, 59, 55, 50, 45, 40],
      );
    });

    test('matches the normative real fixture totals', () {
      final document = _document('docs/partituras/prueba-tablatura.xml');
      final options = LessonImportOptions(partId: 'P1');
      final chart = decoder.decode(document, options);
      final result = MusicXmlTimelineNormalizer().normalizeWithDiagnostics(
        MusicXmlDocumentDecoder().decode(document, options),
        document,
        options,
      );
      expect(chart.totalTicks, 620160);
      expect(chart.events, hasLength(874));
      expect(chart.events.map((event) => event.id).toSet(), hasLength(874));
      expect(chart.tempoMap.first, TempoPoint(tick: 0, bpm: 124));
      expect(
        chart.meterMap.first,
        MeterPoint(tick: 0, numerator: 2, denominator: 4),
      );
      expect(
        chart.meterMap,
        contains(MeterPoint(tick: 1920, numerator: 4, denominator: 4)),
      );
      expect(chart.events.whereType<LessonChordEvent>(), isNotEmpty);
      expect(
        result.diagnostics.where(
          (entry) =>
              entry.code == MusicXmlImportDiagnosticCode.graceNoteIgnored,
        ),
        hasLength(5),
      );
      expect(
        result.diagnostics.where(
          (entry) =>
              entry.code ==
              MusicXmlImportDiagnosticCode.measureDurationNormalized,
        ),
        hasLength(3),
      );
    });

    test('normalizes backup, ties, chord, grace and endings', () {
      final chart = decoder.decode(
        _document('test/data/learning/fixtures/timeline-features.musicxml'),
        LessonImportOptions(),
      );

      expect(chart.totalTicks, 15360);
      expect(chart.events, hasLength(4));
      expect(chart.events.map((event) => event.id).toSet(), hasLength(4));
      final chords = chart.events.whereType<LessonChordEvent>().toList();
      expect(chords, hasLength(2));
      expect(chords.map((chord) => chord.symbol), everyElement('C5'));
      expect(chords.map((chord) => chord.durationTicks), everyElement(1920));
      expect(chords.map((chord) => chord.startTick), [0, 7680]);
      expect(
        chart.events.whereType<LessonNoteEvent>().map((note) => note.midi),
        [69, 71],
      );
    });

    test('rejects a rhythm that is not exact at 960 PPQ', () {
      final source = File(
        'test/data/learning/fixtures/timeline-features.musicxml',
      ).readAsStringSync().replaceFirst(
            '<divisions>1</divisions>',
            '<divisions>7</divisions>',
          );

      expect(
        () => decoder.decode(_inline(source), LessonImportOptions()),
        throwsA(_lessonError(LessonErrorCode.unsupportedRhythmResolution)),
      );
    });

    test('normalizes only measure discrepancies up to 120 ticks', () {
      final accepted = decoder.decode(
        _inline(_restMeasure(divisions: 8, duration: 31)),
        LessonImportOptions(),
      );
      expect(accepted.totalTicks, 3840);
      expect(accepted.events, isEmpty);

      expect(
        () => decoder.decode(
          _inline(_restMeasure(divisions: 8, duration: 30)),
          LessonImportOptions(),
        ),
        throwsA(_lessonError(LessonErrorCode.invalidLessonDocument)),
      );
    });

    test('rejects nested repeat navigation', () {
      final source = File(
        'test/data/learning/fixtures/timeline-features.musicxml',
      ).readAsStringSync().replaceFirst(
            '<barline location="left"><ending number="1" type="start"/></barline>',
            '<barline location="left"><ending number="1" type="start"/><repeat direction="forward" times="2"/></barline>',
          );

      expect(
        () => decoder.decode(_inline(source), LessonImportOptions()),
        throwsA(_lessonError(LessonErrorCode.unsupportedNavigation)),
      );
    });
  });
}

LessonDocument _document(String path) => LessonDocument(
      id: LessonId(path),
      sourceName: path,
      bytes: File(path).readAsBytesSync(),
    );

LessonDocument _inline(String source) => LessonDocument(
      id: LessonId('inline'),
      sourceName: 'inline.musicxml',
      bytes: utf8.encode(source),
    );

Matcher _lessonError(LessonErrorCode code) => isA<LessonException>().having(
      (error) => error.code,
      'code',
      code,
    );

String _restMeasure({required int divisions, required int duration}) => '''
<score-partwise version="4.0">
  <part-list><score-part id="P1"><part-name>Rest</part-name></score-part></part-list>
  <part id="P1"><measure number="1">
    <attributes>
      <divisions>$divisions</divisions><time><beats>4</beats><beat-type>4</beat-type></time>
      <clef number="1"><sign>TAB</sign></clef>
      <staff-details number="1"><staff-lines>6</staff-lines>
        <staff-tuning line="1"><tuning-step>E</tuning-step><tuning-octave>2</tuning-octave></staff-tuning>
        <staff-tuning line="2"><tuning-step>A</tuning-step><tuning-octave>2</tuning-octave></staff-tuning>
        <staff-tuning line="3"><tuning-step>D</tuning-step><tuning-octave>3</tuning-octave></staff-tuning>
        <staff-tuning line="4"><tuning-step>G</tuning-step><tuning-octave>3</tuning-octave></staff-tuning>
        <staff-tuning line="5"><tuning-step>B</tuning-step><tuning-octave>3</tuning-octave></staff-tuning>
        <staff-tuning line="6"><tuning-step>E</tuning-step><tuning-octave>4</tuning-octave></staff-tuning>
      </staff-details>
    </attributes>
    <direction><sound tempo="120"/></direction>
    <note><rest/><duration>$duration</duration><voice>1</voice><staff>1</staff></note>
    <note><grace/><pitch><step>E</step><octave>4</octave></pitch><voice>1</voice><staff>1</staff><notations><technical><string>1</string><fret>0</fret></technical></notations></note>
  </measure></part>
</score-partwise>
''';
