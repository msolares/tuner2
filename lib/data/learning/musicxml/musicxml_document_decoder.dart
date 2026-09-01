import 'dart:convert';

import 'package:afinador/data/learning/musicxml/musicxml_document.dart';
import 'package:afinador/domain/learning/learning.dart';
import 'package:xml/xml.dart';

final class MusicXmlDocumentDecoder {
  factory MusicXmlDocumentDecoder({
    int inputByteLimit = maxInputBytes,
    int nodeLimit = maxNodeCount,
  }) {
    if (inputByteLimit <= 0 || inputByteLimit > maxInputBytes) {
      throw RangeError.range(
          inputByteLimit, 1, maxInputBytes, 'inputByteLimit');
    }
    if (nodeLimit <= 0 || nodeLimit > maxNodeCount) {
      throw RangeError.range(nodeLimit, 1, maxNodeCount, 'nodeLimit');
    }
    return MusicXmlDocumentDecoder._(inputByteLimit, nodeLimit);
  }

  const MusicXmlDocumentDecoder._(this.inputByteLimit, this.nodeLimit);

  static const int maxInputBytes = 10 * 1024 * 1024;
  static const int maxNodeCount = 200000;
  static const Set<String> supportedVersions = {'2.0', '3.0', '3.1', '4.0'};

  final int inputByteLimit;
  final int nodeLimit;

  MusicXmlScoreData decode(
    LessonDocument document,
    LessonImportOptions options,
  ) {
    if (document.bytes.length > inputByteLimit) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        'MusicXML exceeds $inputByteLimit bytes',
      );
    }

    try {
      final source = utf8.decode(document.bytes, allowMalformed: false);
      final safeSource = _removeSupportedExternalDoctype(source);
      final xml = XmlDocument.parse(safeSource);
      if (xml.descendants.whereType<XmlElement>().length + 1 > nodeLimit) {
        throw _lessonError(
          LessonErrorCode.invalidLessonDocument,
          'MusicXML exceeds $nodeLimit nodes',
        );
      }
      return _decodeDocument(xml, options);
    } on LessonException {
      rethrow;
    } on FormatException catch (error) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        error.message,
      );
    } catch (error) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        error.toString(),
      );
    }
  }

  String _removeSupportedExternalDoctype(String source) {
    if (RegExp(r'<!ENTITY\b', caseSensitive: false).hasMatch(source)) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        'Entity declarations are not allowed',
      );
    }

    final declarations = RegExp(
      r'<!DOCTYPE\b[\s\S]*?>',
      caseSensitive: false,
    ).allMatches(source).toList(growable: false);
    if (declarations.isEmpty) {
      return source;
    }
    if (declarations.length != 1) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        'Multiple DOCTYPE declarations are not allowed',
      );
    }

    final declaration = declarations.single.group(0)!;
    final supported = RegExp(
      r'''^<!DOCTYPE\s+score-partwise\s+PUBLIC\s+(['"])-//Recordare//DTD\s+MusicXML\s+(2\.0|3\.0|3\.1|4\.0)\s+Partwise//EN\1\s+(['"])https?://www\.musicxml\.org/dtds/\2/partwise\.dtd\3\s*>$''',
      caseSensitive: false,
    );
    if (!supported.hasMatch(declaration)) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        'DTD declarations are not allowed',
      );
    }

    return source.replaceRange(
      declarations.single.start,
      declarations.single.end,
      '',
    );
  }

  MusicXmlScoreData _decodeDocument(
    XmlDocument document,
    LessonImportOptions options,
  ) {
    final root = document.rootElement;
    if (root.name.local != 'score-partwise') {
      throw _lessonError(
        LessonErrorCode.unsupportedMusicXmlVersion,
        'Only score-partwise is supported',
      );
    }
    final version = root.getAttribute('version');
    if (version == null || !supportedVersions.contains(version)) {
      throw _lessonError(
        LessonErrorCode.unsupportedMusicXmlVersion,
        'Unsupported MusicXML version: ${version ?? 'missing'}',
      );
    }

    _rejectUnsupportedNavigation(root);
    final partNames = <String, String>{};
    final partList = _child(root, 'part-list');
    if (partList != null) {
      for (final scorePart in _children(partList, 'score-part')) {
        final id = scorePart.getAttribute('id');
        final name = _text(_child(scorePart, 'part-name'));
        if (id != null && id.trim().isNotEmpty) {
          partNames[id] = name ?? id;
        }
      }
    }

    final parts = _children(root, 'part').toList(growable: false);
    final selectedPart = _selectPart(parts, options.partId);
    final partId = selectedPart.getAttribute('id')!;
    final tablatureStaff = _findTablatureStaff(selectedPart);
    final measures = <MusicXmlMeasureData>[];
    var tuning = <int, int>{};
    var capo = 0;
    var transpose = const MusicXmlTransposeData(
      diatonic: 0,
      chromatic: 0,
      octaveChange: 0,
    );

    for (final measure in _children(selectedPart, 'measure')) {
      final decoded = _decodeMeasure(
        measure,
        tablatureStaff,
        tuning,
        capo,
        transpose,
      );
      measures.add(decoded.measure);
      tuning = decoded.tuning;
      capo = decoded.capo;
      transpose = decoded.transpose;
    }
    if (measures.isEmpty) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        'Selected part has no measures',
      );
    }

    return MusicXmlScoreData(
      version: version,
      partId: partId,
      partName: partNames[partId] ?? partId,
      tablatureStaff: tablatureStaff,
      measures: measures,
    );
  }

  XmlElement _selectPart(List<XmlElement> parts, String? requestedPartId) {
    if (requestedPartId != null) {
      for (final part in parts) {
        if (part.getAttribute('id') == requestedPartId) {
          if (_tryFindTablatureStaff(part) == null) {
            throw _lessonError(
              LessonErrorCode.tablatureNotFound,
              'Part $requestedPartId has no supported TAB staff',
            );
          }
          return part;
        }
      }
      throw _lessonError(
        LessonErrorCode.partNotFound,
        'Part $requestedPartId was not found',
      );
    }

    for (final part in parts) {
      if (_tryFindTablatureStaff(part) != null) {
        return part;
      }
    }
    throw _lessonError(
      LessonErrorCode.tablatureNotFound,
      'No supported TAB staff was found',
    );
  }

  int _findTablatureStaff(XmlElement part) {
    final staff = _tryFindTablatureStaff(part);
    if (staff == null) {
      throw _lessonError(
        LessonErrorCode.tablatureNotFound,
        'Selected part has no supported TAB staff',
      );
    }
    return staff;
  }

  int? _tryFindTablatureStaff(XmlElement part) {
    final tabStaffs = <int>[];
    for (final clef in _descendants(part, 'clef')) {
      if (_text(_child(clef, 'sign'))?.toUpperCase() == 'TAB') {
        tabStaffs.add(_positiveIntAttribute(clef, 'number', fallback: 1));
      }
    }
    for (final staff in tabStaffs) {
      final hasTechnicalNotes = _descendants(part, 'note').any((note) {
        final noteStaff = _optionalPositiveIntField(
              _text(_child(note, 'staff')),
              'staff',
            ) ??
            1;
        final technical = _descendant(note, 'technical');
        return noteStaff == staff &&
            technical != null &&
            _child(technical, 'string') != null &&
            _child(technical, 'fret') != null;
      });
      if (hasTechnicalNotes) {
        return staff;
      }
    }
    return null;
  }

  _DecodedMeasure _decodeMeasure(
    XmlElement measure,
    int tabStaff,
    Map<int, int> currentTuning,
    int currentCapo,
    MusicXmlTransposeData currentTranspose,
  ) {
    final items = <MusicXmlMeasureItemData>[];
    var tuning = Map<int, int>.of(currentTuning);
    var capo = currentCapo;
    var transpose = currentTranspose;

    for (final element in measure.childElements) {
      switch (element.name.local) {
        case 'attributes':
          final attributes = _decodeAttributes(element, tabStaff);
          if (attributes.tuning != null) {
            tuning = Map.of(attributes.tuning!.openMidiByString);
          }
          capo = attributes.capo ?? capo;
          transpose = attributes.transpose ?? transpose;
          items.add(attributes);
        case 'direction':
          final tempo = _decodeTempo(element);
          if (tempo != null) {
            items.add(MusicXmlDirectionData(tempo: tempo));
          }
        case 'backup':
          items.add(MusicXmlBackupData(_requiredDuration(element)));
        case 'forward':
          items.add(
            MusicXmlForwardData(
              duration: _requiredDuration(element),
              voice: _text(_child(element, 'voice')),
            ),
          );
        case 'note':
          final staff = _optionalPositiveIntField(
                _text(_child(element, 'staff')),
                'staff',
              ) ??
              1;
          if (staff == tabStaff) {
            items.add(
              _decodeNote(element, staff, tuning, capo, transpose),
            );
          } else {
            final isGrace = _child(element, 'grace') != null;
            final durationText = _text(_child(element, 'duration'));
            items.add(
              MusicXmlSkippedNoteData(
                duration: durationText == null
                    ? null
                    : _positiveInt(durationText, 'note duration'),
                isChordMember: _child(element, 'chord') != null,
                isGrace: isGrace,
              ),
            );
          }
        case 'barline':
          items.add(_decodeBarline(element));
      }
    }
    return _DecodedMeasure(
      MusicXmlMeasureData(
        number: measure.getAttribute('number') ?? '${0}',
        items: items,
      ),
      tuning,
      capo,
      transpose,
    );
  }

  MusicXmlAttributesData _decodeAttributes(XmlElement element, int tabStaff) {
    final divisionsText = _text(_child(element, 'divisions'));
    final divisions =
        divisionsText == null ? null : _positiveInt(divisionsText, 'divisions');
    final time = _child(element, 'time');
    MusicXmlMeterData? meter;
    if (time != null) {
      meter = MusicXmlMeterData(
        _positiveInt(_requiredText(time, 'beats'), 'beats'),
        _positiveInt(_requiredText(time, 'beat-type'), 'beat-type'),
      );
    }

    XmlElement? staffDetails;
    for (final candidate in _children(element, 'staff-details')) {
      if (_positiveIntAttribute(candidate, 'number', fallback: 1) == tabStaff) {
        staffDetails = candidate;
        break;
      }
    }
    MusicXmlTuningData? tuning;
    int? capo;
    if (staffDetails != null) {
      final lineCount = _optionalPositiveIntField(
        _text(_child(staffDetails, 'staff-lines')),
        'staff-lines',
      );
      final tuningElements = _children(staffDetails, 'staff-tuning').toList();
      if (lineCount != null && lineCount != 6) {
        throw _lessonError(
          LessonErrorCode.invalidTuning,
          'TAB staff must contain exactly six lines',
        );
      }
      if (tuningElements.isNotEmpty) {
        if (tuningElements.length != 6) {
          throw _lessonError(
            LessonErrorCode.invalidTuning,
            'TAB tuning must contain exactly six strings',
          );
        }
        final openMidi = <int, int>{};
        for (final entry in tuningElements) {
          final line = _positiveIntAttribute(entry, 'line');
          if (line > 6) {
            throw _lessonError(
                LessonErrorCode.invalidTuning, 'Invalid tuning line');
          }
          final stringNumber = 7 - line;
          if (openMidi.containsKey(stringNumber)) {
            throw _lessonError(
                LessonErrorCode.invalidTuning, 'Duplicate tuning line');
          }
          openMidi[stringNumber] = _pitchMidi(
            _requiredText(entry, 'tuning-step'),
            _text(_child(entry, 'tuning-alter')),
            _requiredText(entry, 'tuning-octave'),
            context: 'staff-tuning',
          );
        }
        if (openMidi.length != 6) {
          throw _lessonError(
              LessonErrorCode.invalidTuning, 'Incomplete tuning');
        }
        tuning = MusicXmlTuningData(openMidi);
      }
      final capoText = _text(_child(staffDetails, 'capo'));
      if (capoText != null) {
        capo = _nonNegativeInt(capoText, 'capo');
        if (capo > 24) {
          throw _lessonError(
              LessonErrorCode.invalidTuning, 'Capo exceeds fret 24');
        }
      }
    }

    MusicXmlTransposeData? transpose;
    for (final candidate in _children(element, 'transpose')) {
      final number = _optionalPositiveIntField(
        candidate.getAttribute('number'),
        'transpose@number',
      );
      if (number == null || number == tabStaff) {
        transpose = MusicXmlTransposeData(
          diatonic: _optionalIntField(
                _text(_child(candidate, 'diatonic')),
                'transpose/diatonic',
              ) ??
              0,
          chromatic: _optionalIntField(
                _text(_child(candidate, 'chromatic')),
                'transpose/chromatic',
              ) ??
              0,
          octaveChange: _optionalIntField(
                _text(_child(candidate, 'octave-change')),
                'transpose/octave-change',
              ) ??
              0,
        );
        break;
      }
    }

    return MusicXmlAttributesData(
      divisions: divisions,
      meter: meter,
      tuning: tuning,
      capo: capo,
      transpose: transpose,
    );
  }

  MusicXmlNoteData _decodeNote(
    XmlElement note,
    int staff,
    Map<int, int> tuning,
    int capo,
    MusicXmlTransposeData transpose,
  ) {
    final isRest = _child(note, 'rest') != null;
    final isGrace = _child(note, 'grace') != null;
    final durationText = _text(_child(note, 'duration'));
    final duration = durationText == null
        ? null
        : _positiveInt(durationText, 'note duration');
    if (!isGrace && duration == null) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        'Non-grace note is missing duration',
      );
    }
    final voice = _text(_child(note, 'voice')) ?? '1';
    if (voice.trim().isEmpty) {
      throw _lessonError(LessonErrorCode.invalidLessonDocument, 'Empty voice');
    }

    int? midi;
    int? stringNumber;
    int? fret;
    if (!isRest) {
      final pitch = _child(note, 'pitch');
      final technical = _descendant(note, 'technical');
      if (pitch == null || technical == null) {
        throw _lessonError(
          LessonErrorCode.invalidLessonDocument,
          'TAB note requires pitch and technical position',
        );
      }
      midi = _pitchMidi(
        _requiredText(pitch, 'step'),
        _text(_child(pitch, 'alter')),
        _requiredText(pitch, 'octave'),
        context: 'pitch',
      );
      stringNumber = _positiveInt(
        _requiredText(technical, 'string'),
        'string',
      );
      fret = _nonNegativeInt(_requiredText(technical, 'fret'), 'fret');
      if (stringNumber > 6 || fret > 24) {
        throw _lessonError(
          LessonErrorCode.inconsistentPitchAndFret,
          'Invalid string/fret position',
        );
      }
      if (!tuning.containsKey(stringNumber)) {
        throw _lessonError(
          LessonErrorCode.invalidTuning,
          'No tuning is defined for string $stringNumber',
        );
      }
      final soundingMidi = midi + transpose.semitones;
      final expectedMidi = tuning[stringNumber]! + capo + fret;
      if (soundingMidi != expectedMidi) {
        throw _lessonError(
          LessonErrorCode.inconsistentPitchAndFret,
          'Pitch $soundingMidi does not match string $stringNumber fret $fret ($expectedMidi)',
        );
      }
    }

    final tieTypes = <String>{
      ..._children(note, 'tie')
          .map((element) => element.getAttribute('type'))
          .whereType<String>(),
      ..._descendants(note, 'tied')
          .map((element) => element.getAttribute('type'))
          .whereType<String>(),
    };
    final timeModificationElement = _child(note, 'time-modification');
    MusicXmlTimeModificationData? timeModification;
    if (timeModificationElement != null) {
      timeModification = MusicXmlTimeModificationData(
        actualNotes: _positiveInt(
          _requiredText(timeModificationElement, 'actual-notes'),
          'actual-notes',
        ),
        normalNotes: _positiveInt(
          _requiredText(timeModificationElement, 'normal-notes'),
          'normal-notes',
        ),
      );
    }
    final tuplets = <MusicXmlTupletData>[];
    for (final tuplet in _descendants(note, 'tuplet')) {
      final type = tuplet.getAttribute('type');
      if (type != 'start' && type != 'stop') {
        throw _lessonError(
          LessonErrorCode.invalidLessonDocument,
          'Tuplet type must be start or stop',
        );
      }
      tuplets.add(
        MusicXmlTupletData(
          number: _optionalPositiveIntField(
                tuplet.getAttribute('number'),
                'tuplet@number',
              ) ??
              1,
          type: type!,
        ),
      );
    }
    final technical = _descendant(note, 'technical');
    final techniques = <String>{};
    if (technical != null) {
      for (final name in const [
        'hammer-on',
        'slide',
        'bend',
        'harmonic',
        'up-bow',
        'down-bow',
      ]) {
        if (_descendant(technical, name) != null) {
          techniques.add(name);
        }
      }
    }
    final bend = technical == null ? null : _descendant(technical, 'bend');
    final bendAlterText =
        bend == null ? null : _text(_child(bend, 'bend-alter'));
    final bendAlter = bendAlterText == null
        ? null
        : _finiteDouble(bendAlterText, 'bend-alter');

    return MusicXmlNoteData(
      voice: voice,
      staff: staff,
      duration: duration,
      isChordMember: _child(note, 'chord') != null,
      isRest: isRest,
      isGrace: isGrace,
      midi: midi,
      stringNumber: stringNumber,
      fret: fret,
      tieStart: tieTypes.contains('start'),
      tieStop: tieTypes.contains('stop'),
      timeModification: timeModification,
      tuplets: tuplets,
      techniques: techniques,
      bendAlter: bendAlter,
      preBend: bend != null && _child(bend, 'pre-bend') != null,
      release: bend != null && _child(bend, 'release') != null,
    );
  }

  double? _decodeTempo(XmlElement direction) {
    final sound = _child(direction, 'sound');
    final soundTempo = sound?.getAttribute('tempo');
    final metronome = _descendant(direction, 'metronome');
    final metronomeTempo =
        metronome == null ? null : _text(_child(metronome, 'per-minute'));
    final value = soundTempo ?? metronomeTempo;
    return value == null ? null : _finitePositiveDouble(value, 'tempo');
  }

  MusicXmlBarlineData _decodeBarline(XmlElement barline) {
    final repeat = _child(barline, 'repeat');
    final ending = _child(barline, 'ending');
    final repeatDirection = repeat?.getAttribute('direction');
    if (repeatDirection != null &&
        repeatDirection != 'forward' &&
        repeatDirection != 'backward') {
      throw _lessonError(
        LessonErrorCode.unsupportedNavigation,
        'Unsupported repeat direction',
      );
    }
    int? repeatTimes;
    if (repeatDirection != null) {
      repeatTimes = _optionalPositiveIntField(
            repeat!.getAttribute('times'),
            'repeat@times',
          ) ??
          2;
      if (repeatTimes < 2) {
        throw _lessonError(
          LessonErrorCode.unsupportedNavigation,
          'Repeat times must be at least 2',
        );
      }
    }
    int? endingNumber;
    String? endingType;
    if (ending != null) {
      final number = ending.getAttribute('number');
      if (number != '1' && number != '2') {
        throw _lessonError(
          LessonErrorCode.unsupportedNavigation,
          'Only endings 1 and 2 are supported',
        );
      }
      endingNumber = int.parse(number!);
      endingType = ending.getAttribute('type');
    }
    return MusicXmlBarlineData(
      location: barline.getAttribute('location') ?? 'right',
      repeatDirection: repeatDirection,
      repeatTimes: repeatTimes,
      endingNumber: endingNumber,
      endingType: endingType,
    );
  }

  void _rejectUnsupportedNavigation(XmlElement root) {
    for (final sound in _descendants(root, 'sound')) {
      for (final attribute in const ['dacapo', 'dalsegno', 'tocoda', 'fine']) {
        if (sound.getAttribute(attribute) != null) {
          throw _lessonError(
            LessonErrorCode.unsupportedNavigation,
            'Unsupported navigation attribute: $attribute',
          );
        }
      }
    }
    if (_descendants(root, 'segno').isNotEmpty ||
        _descendants(root, 'coda').isNotEmpty) {
      throw _lessonError(
        LessonErrorCode.unsupportedNavigation,
        'Segno and Coda are not supported',
      );
    }
  }

  int _requiredDuration(XmlElement element) => _positiveInt(
        _requiredText(element, 'duration'),
        '${element.name.local} duration',
      );

  int _pitchMidi(
    String stepText,
    String? alterText,
    String octaveText, {
    required String context,
  }) {
    const semitones = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
    final step = semitones[stepText.trim().toUpperCase()];
    final octave = int.tryParse(octaveText.trim());
    final alter = alterText == null ? 0 : int.tryParse(alterText.trim());
    if (step == null || octave == null || alter == null) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        'Invalid or microtonal $context pitch',
      );
    }
    final midi = ((octave + 1) * 12) + step + alter;
    if (midi < 0 || midi > 127) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        '$context MIDI is outside 0..127',
      );
    }
    return midi;
  }

  int _positiveInt(String value, String field) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        '$field must be a positive integer',
      );
    }
    return parsed;
  }

  int _nonNegativeInt(String value, String field) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        '$field must be a non-negative integer',
      );
    }
    return parsed;
  }

  int _positiveIntAttribute(
    XmlElement element,
    String name, {
    int? fallback,
  }) {
    final value = element.getAttribute(name);
    if (value == null && fallback != null) {
      return fallback;
    }
    return _positiveInt(value ?? '', '${element.name.local}@$name');
  }

  int? _optionalPositiveIntField(String? value, String field) {
    if (value == null) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        '$field must be a positive integer',
      );
    }
    return parsed;
  }

  int? _optionalIntField(String? value, String field) {
    if (value == null) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        '$field must be an integer',
      );
    }
    return parsed;
  }

  double _finiteDouble(String value, String field) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null || !parsed.isFinite) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        '$field must be finite',
      );
    }
    return parsed;
  }

  double _finitePositiveDouble(String value, String field) {
    final parsed = _finiteDouble(value, field);
    if (parsed <= 0) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        '$field must be positive',
      );
    }
    return parsed;
  }

  String _requiredText(XmlElement parent, String name) {
    final value = _text(_child(parent, name));
    if (value == null || value.trim().isEmpty) {
      throw _lessonError(
        LessonErrorCode.invalidLessonDocument,
        'Missing $name',
      );
    }
    return value;
  }

  String? _text(XmlElement? element) => element?.innerText.trim();

  XmlElement? _child(XmlElement element, String name) {
    for (final child in element.childElements) {
      if (child.name.local == name) return child;
    }
    return null;
  }

  Iterable<XmlElement> _children(XmlElement element, String name) =>
      element.childElements.where((child) => child.name.local == name);

  XmlElement? _descendant(XmlElement element, String name) {
    for (final descendant in element.descendants.whereType<XmlElement>()) {
      if (descendant.name.local == name) return descendant;
    }
    return null;
  }

  List<XmlElement> _descendants(XmlElement element, String name) =>
      element.descendants
          .whereType<XmlElement>()
          .where((descendant) => descendant.name.local == name)
          .toList(growable: false);

  LessonException _lessonError(LessonErrorCode code, String context) =>
      LessonException(code, context: context);
}

final class _DecodedMeasure {
  const _DecodedMeasure(
    this.measure,
    this.tuning,
    this.capo,
    this.transpose,
  );

  final MusicXmlMeasureData measure;
  final Map<int, int> tuning;
  final int capo;
  final MusicXmlTransposeData transpose;
}
