import '../../domain/entities/song_tuning_result.dart';

const List<String> _defaultGuitarStringsLowToHigh = [
  'E',
  'A',
  'D',
  'G',
  'B',
  'E'
];

const Map<String, List<String>> _presetStringsLowToHigh = {
  'chromatic': _defaultGuitarStringsLowToHigh,
  'guitar_standard': _defaultGuitarStringsLowToHigh,
  'ukulele_standard': ['G', 'C', 'E', 'A'],
  'bass_standard': ['E', 'A', 'D', 'G'],
  'violin_standard': ['G', 'D', 'A', 'E'],
};

List<String> tuningDisplayStringsForPreset(String presetId) {
  final stringsLowToHigh =
      _presetStringsLowToHigh[presetId] ?? _defaultGuitarStringsLowToHigh;
  return _toDisplayStrings(stringsLowToHigh);
}

List<String> tuningDisplayStringsFromSongResult(SongTuningResult result) {
  return _toDisplayStrings(result.primaryTuning.stringsLowToHigh);
}

List<String> resolveHeaderTuningStrings({
  required String presetId,
  SongTuningResult? songTuningResult,
  required bool useSongTuningResult,
}) {
  if (useSongTuningResult && songTuningResult != null) {
    return tuningDisplayStringsFromSongResult(songTuningResult);
  }
  return tuningDisplayStringsForPreset(presetId);
}

List<String> _toDisplayStrings(List<String> stringsLowToHigh) {
  return stringsLowToHigh.reversed
      .map(_extractPitchClass)
      .toList(growable: false);
}

String _extractPitchClass(String note) {
  final trimmed = note.trim();
  final match = RegExp(r'^([A-Ga-g])([#b]?)').firstMatch(trimmed);
  if (match == null) {
    return trimmed.toUpperCase();
  }
  final letter = match.group(1)!.toUpperCase();
  final accidental = match.group(2)!;
  return '$letter$accidental';
}
