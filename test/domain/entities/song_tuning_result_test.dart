import 'package:afinador/domain/entities/guitar_tuning.dart';
import 'package:afinador/domain/entities/song_tuning_query.dart';
import 'package:afinador/domain/entities/song_tuning_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongTuningResult', () {
    const query = SongTuningQuery(songName: 'Everlong', artistName: 'Foo Fighters');

    test('representa afinacion principal y alternativas', () {
      const dropD = GuitarTuning(
        id: 'drop_d',
        displayName: 'Drop D',
        stringsLowToHigh: ['D2', 'A2', 'D3', 'G3', 'B3', 'E4'],
      );
      const halfStepDown = GuitarTuning(
        id: 'half_step_down',
        displayName: 'Eb Standard',
        stringsLowToHigh: ['Eb2', 'Ab2', 'Db3', 'Gb3', 'Bb3', 'Eb4'],
      );

      const result = SongTuningResult(
        query: query,
        primaryTuning: dropD,
        alternativeTunings: [halfStepDown],
      );

      expect(result.primaryTuning.id, 'drop_d');
      expect(result.hasAlternatives, isTrue);
      expect(result.alternativeTunings.single.id, 'half_step_down');
    });

    test('permite afinacion estandar sin alternativas', () {
      const result = SongTuningResult(
        query: query,
        primaryTuning: GuitarTuning.standard,
      );

      expect(result.primaryTuning.id, 'standard_e');
      expect(result.primaryTuning.stringsLowToHigh, GuitarTuning.standardStringsLowToHigh);
      expect(result.hasAlternatives, isFalse);
    });
  });
}

