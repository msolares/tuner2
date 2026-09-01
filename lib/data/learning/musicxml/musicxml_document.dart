import 'dart:collection';

final class MusicXmlScoreData {
  MusicXmlScoreData({
    required this.version,
    required this.partId,
    required this.partName,
    required this.tablatureStaff,
    required List<MusicXmlMeasureData> measures,
  }) : measures = List.unmodifiable(measures);

  final String version;
  final String partId;
  final String partName;
  final int tablatureStaff;
  final List<MusicXmlMeasureData> measures;
}

final class MusicXmlMeasureData {
  MusicXmlMeasureData({
    required this.number,
    required List<MusicXmlMeasureItemData> items,
  }) : items = List.unmodifiable(items);

  final String number;
  final List<MusicXmlMeasureItemData> items;
}

sealed class MusicXmlMeasureItemData {
  const MusicXmlMeasureItemData();
}

final class MusicXmlAttributesData extends MusicXmlMeasureItemData {
  MusicXmlAttributesData({
    required this.divisions,
    required this.meter,
    required this.tuning,
    required this.capo,
    required this.transpose,
  });

  final int? divisions;
  final MusicXmlMeterData? meter;
  final MusicXmlTuningData? tuning;
  final int? capo;
  final MusicXmlTransposeData? transpose;
}

final class MusicXmlMeterData {
  const MusicXmlMeterData(this.beats, this.beatType);

  final int beats;
  final int beatType;
}

final class MusicXmlTuningData {
  MusicXmlTuningData(Map<int, int> openMidiByString)
      : openMidiByString = UnmodifiableMapView(Map.of(openMidiByString));

  final Map<int, int> openMidiByString;
}

final class MusicXmlTransposeData {
  const MusicXmlTransposeData({
    required this.diatonic,
    required this.chromatic,
    required this.octaveChange,
  });

  final int diatonic;
  final int chromatic;
  final int octaveChange;

  int get semitones => chromatic + (octaveChange * 12);
}

final class MusicXmlDirectionData extends MusicXmlMeasureItemData {
  const MusicXmlDirectionData({required this.tempo});

  final double tempo;
}

final class MusicXmlBackupData extends MusicXmlMeasureItemData {
  const MusicXmlBackupData(this.duration);

  final int duration;
}

final class MusicXmlForwardData extends MusicXmlMeasureItemData {
  const MusicXmlForwardData({required this.duration, required this.voice});

  final int duration;
  final String? voice;
}

/// Conserva el avance temporal de una nota de otro pentagrama sin importar
/// contenido tonal ni crear un evento educativo duplicado.
final class MusicXmlSkippedNoteData extends MusicXmlMeasureItemData {
  const MusicXmlSkippedNoteData({
    required this.duration,
    required this.isChordMember,
    required this.isGrace,
  });

  final int? duration;
  final bool isChordMember;
  final bool isGrace;
}

final class MusicXmlBarlineData extends MusicXmlMeasureItemData {
  const MusicXmlBarlineData({
    required this.location,
    required this.repeatDirection,
    required this.repeatTimes,
    required this.endingNumber,
    required this.endingType,
  });

  final String location;
  final String? repeatDirection;
  final int? repeatTimes;
  final int? endingNumber;
  final String? endingType;
}

final class MusicXmlNoteData extends MusicXmlMeasureItemData {
  MusicXmlNoteData({
    required this.voice,
    required this.staff,
    required this.duration,
    required this.isChordMember,
    required this.isRest,
    required this.isGrace,
    required this.midi,
    required this.stringNumber,
    required this.fret,
    required this.tieStart,
    required this.tieStop,
    required this.timeModification,
    required List<MusicXmlTupletData> tuplets,
    required Set<String> techniques,
    required this.bendAlter,
    required this.preBend,
    required this.release,
  })  : tuplets = List.unmodifiable(tuplets),
        techniques = Set.unmodifiable(techniques);

  final String voice;
  final int staff;
  final int? duration;
  final bool isChordMember;
  final bool isRest;
  final bool isGrace;
  final int? midi;
  final int? stringNumber;
  final int? fret;
  final bool tieStart;
  final bool tieStop;
  final MusicXmlTimeModificationData? timeModification;
  final List<MusicXmlTupletData> tuplets;
  final Set<String> techniques;
  final double? bendAlter;
  final bool preBend;
  final bool release;
}

final class MusicXmlTupletData {
  const MusicXmlTupletData({required this.number, required this.type});

  final int number;
  final String type;
}

final class MusicXmlTimeModificationData {
  const MusicXmlTimeModificationData({
    required this.actualNotes,
    required this.normalNotes,
  });

  final int actualNotes;
  final int normalNotes;
}
