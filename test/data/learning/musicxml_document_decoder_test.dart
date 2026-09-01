import 'dart:convert';
import 'dart:io';

import 'package:afinador/data/learning/musicxml/musicxml_document.dart';
import 'package:afinador/data/learning/musicxml/musicxml_document_decoder.dart';
import 'package:afinador/domain/learning/learning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MusicXmlDocumentDecoder', () {
    final decoder = MusicXmlDocumentDecoder();

    test('discovers a non-hardcoded part, TAB staff and voice', () {
      final score = decoder.decode(
        _fixture('dynamic-tab.musicxml'),
        LessonImportOptions(),
      );

      expect(score.version, '4.0');
      expect(score.partId, 'lead');
      expect(score.partName, 'Lead Guitar');
      expect(score.tablatureStaff, 3);
      expect(score.measures, hasLength(1));

      final items = score.measures.single.items;
      final attributes = items.whereType<MusicXmlAttributesData>().single;
      expect(attributes.divisions, 3);
      expect(attributes.meter?.beats, 6);
      expect(attributes.meter?.beatType, 8);
      expect(attributes.capo, 2);
      expect(attributes.transpose?.diatonic, 1);
      expect(attributes.transpose?.chromatic, 2);
      expect(attributes.tuning?.openMidiByString, {
        1: 64,
        2: 59,
        3: 55,
        4: 50,
        5: 45,
        6: 40,
      });

      final notes = items.whereType<MusicXmlNoteData>().toList();
      expect(notes, hasLength(2));
      expect(notes.first.voice, '9');
      expect(notes.first.staff, 3);
      expect(notes.first.midi, 43);
      expect(notes.first.stringNumber, 6);
      expect(notes.first.fret, 3);
      expect(notes.first.duration, 2);
      expect(notes.first.tieStart, isTrue);
      expect(notes.first.tieStop, isFalse);
      expect(notes.first.timeModification?.actualNotes, 3);
      expect(notes.first.timeModification?.normalNotes, 2);
      expect(notes.first.tuplets.single.number, 2);
      expect(notes.first.tuplets.single.type, 'start');
      expect(notes.first.techniques, {
        'hammer-on',
        'slide',
        'bend',
        'harmonic',
        'up-bow',
        'down-bow',
      });
      expect(notes.first.bendAlter, 1);
      expect(notes.first.preBend, isTrue);
      expect(notes.first.release, isTrue);
      expect(notes.last.isRest, isTrue);

      expect(items.whereType<MusicXmlDirectionData>().single.tempo, 90);
      expect(items.whereType<MusicXmlBackupData>().single.duration, 2);
      expect(items.whereType<MusicXmlForwardData>().single.duration, 1);
      expect(items.whereType<MusicXmlForwardData>().single.voice, '9');
      final barline = items.whereType<MusicXmlBarlineData>().single;
      expect(barline.repeatDirection, 'backward');
      expect(barline.repeatTimes, 3);
      expect(barline.endingNumber, 1);
      expect(barline.endingType, 'start');
    });

    test('selects an explicit part and returns typed selection errors', () {
      final document = _fixture('dynamic-tab.musicxml');
      expect(
        decoder.decode(document, LessonImportOptions(partId: 'lead')).partId,
        'lead',
      );
      expect(
        () => decoder.decode(document, LessonImportOptions(partId: 'missing')),
        throwsA(_lessonError(LessonErrorCode.partNotFound)),
      );
      expect(
        () => decoder.decode(document, LessonImportOptions(partId: 'keys')),
        throwsA(_lessonError(LessonErrorCode.tablatureNotFound)),
      );
    });

    test('accepts every supported score-partwise version', () {
      final source = _fixtureText('dynamic-tab.musicxml');
      for (final version in MusicXmlDocumentDecoder.supportedVersions) {
        final score = decoder.decode(
          _document(source.replaceFirst('version="4.0"', 'version="$version"')),
          LessonImportOptions(),
        );
        expect(score.version, version);
      }
    });

    test('rejects unsupported version and score-timewise with typed error', () {
      final source = _fixtureText('dynamic-tab.musicxml');
      expect(
        () => decoder.decode(
          _document(source.replaceFirst('version="4.0"', 'version="1.0"')),
          LessonImportOptions(),
        ),
        throwsA(_lessonError(LessonErrorCode.unsupportedMusicXmlVersion)),
      );
      expect(
        () => decoder.decode(
          _document(source.replaceAll('score-partwise', 'score-timewise')),
          LessonImportOptions(),
        ),
        throwsA(_lessonError(LessonErrorCode.unsupportedMusicXmlVersion)),
      );
    });

    test('strips the known MusicXML doctype without resolving it', () {
      final source = _fixtureText('dynamic-tab.musicxml').replaceFirst(
        '<score-partwise',
        "<!DOCTYPE score-partwise PUBLIC '-//Recordare//DTD MusicXML 4.0 Partwise//EN' 'http://www.musicxml.org/dtds/4.0/partwise.dtd'>\n<score-partwise",
      );

      expect(
        decoder.decode(_document(source), LessonImportOptions()).partId,
        'lead',
      );
    });

    test('rejects DTD subsets, entities and unknown external declarations', () {
      final source = _fixtureText('dynamic-tab.musicxml');
      final malicious = source.replaceFirst(
        '<score-partwise',
        '<!DOCTYPE score-partwise [<!ENTITY xxe SYSTEM "file:///secret">]>\n<score-partwise',
      );
      final unknownExternal = source.replaceFirst(
        '<score-partwise',
        '<!DOCTYPE score-partwise SYSTEM "https://example.invalid/evil.dtd">\n<score-partwise',
      );

      expect(
        () => decoder.decode(_document(malicious), LessonImportOptions()),
        throwsA(_lessonError(LessonErrorCode.invalidLessonDocument)),
      );
      expect(
        () => decoder.decode(_document(unknownExternal), LessonImportOptions()),
        throwsA(_lessonError(LessonErrorCode.invalidLessonDocument)),
      );
    });

    test('enforces byte and node limits before returning a result', () {
      final byteLimited = MusicXmlDocumentDecoder(inputByteLimit: 32);
      expect(
        () => byteLimited.decode(
          _fixture('dynamic-tab.musicxml'),
          LessonImportOptions(),
        ),
        throwsA(_lessonError(LessonErrorCode.invalidLessonDocument)),
      );

      final nodeLimited = MusicXmlDocumentDecoder(nodeLimit: 8);
      expect(
        () => nodeLimited.decode(
          _fixture('dynamic-tab.musicxml'),
          LessonImportOptions(),
        ),
        throwsA(_lessonError(LessonErrorCode.invalidLessonDocument)),
      );
      expect(
        () => MusicXmlDocumentDecoder(
          inputByteLimit: MusicXmlDocumentDecoder.maxInputBytes + 1,
        ),
        throwsRangeError,
      );
    });

    test('rejects malformed UTF-8 and malformed XML', () {
      expect(
        () => decoder.decode(
          LessonDocument(
            id: LessonId('invalid'),
            sourceName: 'invalid.musicxml',
            bytes: const [0xC3, 0x28],
          ),
          LessonImportOptions(),
        ),
        throwsA(_lessonError(LessonErrorCode.invalidLessonDocument)),
      );
      expect(
        () => decoder.decode(
            _document('<score-partwise>'), LessonImportOptions()),
        throwsA(_lessonError(LessonErrorCode.invalidLessonDocument)),
      );
    });

    test('rejects inconsistent pitch, string and fret as a typed error', () {
      expect(
        () => decoder.decode(
          _fixture('inconsistent-pitch.musicxml'),
          LessonImportOptions(),
        ),
        throwsA(_lessonError(LessonErrorCode.inconsistentPitchAndFret)),
      );
    });

    test('rejects invalid tuning and unsupported navigation', () {
      final source = _fixtureText('dynamic-tab.musicxml');
      final invalidTuning = source.replaceFirst(
        '<staff-lines>6</staff-lines>',
        '<staff-lines>7</staff-lines>',
      );
      final unsupportedNavigation = source.replaceFirst(
        '<direction>',
        '<direction><sound dacapo="yes"/>',
      );

      expect(
        () => decoder.decode(_document(invalidTuning), LessonImportOptions()),
        throwsA(_lessonError(LessonErrorCode.invalidTuning)),
      );
      expect(
        () => decoder.decode(
          _document(unsupportedNavigation),
          LessonImportOptions(),
        ),
        throwsA(_lessonError(LessonErrorCode.unsupportedNavigation)),
      );
    });

    test('decodes the real fixture without hardcoded identifiers', () {
      final score = decoder.decode(
        _documentFromPath('docs/partituras/prueba-tablatura.xml'),
        LessonImportOptions(),
      );

      expect(score.partId, 'P1');
      expect(score.tablatureStaff, 2);
      expect(score.measures, hasLength(82));
      final pitchedNotes = score.measures
          .expand((measure) => measure.items)
          .whereType<MusicXmlNoteData>()
          .where((note) => !note.isRest)
          .toList();
      expect(pitchedNotes, hasLength(455));
      expect(
        pitchedNotes.where((note) => !note.isChordMember),
        hasLength(454),
      );
    });

    test('returns defensive, non-modifiable DTO collections', () {
      final score = decoder.decode(
        _fixture('dynamic-tab.musicxml'),
        LessonImportOptions(),
      );
      final attributes = score.measures.single.items
          .whereType<MusicXmlAttributesData>()
          .single;
      final note =
          score.measures.single.items.whereType<MusicXmlNoteData>().first;

      expect(() => score.measures.add(score.measures.single),
          throwsUnsupportedError);
      expect(
        () => score.measures.single.items.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => attributes.tuning!.openMidiByString[1] = 0,
        throwsUnsupportedError,
      );
      expect(() => note.techniques.add('other'), throwsUnsupportedError);
    });
  });
}

LessonDocument _fixture(String name) =>
    _documentFromPath('test/data/learning/fixtures/$name');

String _fixtureText(String name) =>
    File('test/data/learning/fixtures/$name').readAsStringSync();

LessonDocument _documentFromPath(String path) => LessonDocument(
      id: LessonId(path),
      sourceName: path,
      bytes: File(path).readAsBytesSync(),
    );

LessonDocument _document(String source) => LessonDocument(
      id: LessonId('inline'),
      sourceName: 'inline.musicxml',
      bytes: utf8.encode(source),
    );

Matcher _lessonError(LessonErrorCode code) => isA<LessonException>().having(
      (error) => error.code,
      'code',
      code,
    );
