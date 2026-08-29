import 'package:afinador/domain/entities/guitar_tuning.dart';
import 'package:afinador/domain/entities/song_tuning_query.dart';
import 'package:afinador/domain/entities/song_tuning_result.dart';
import 'package:afinador/presentation/screens/tuning_display_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tuningDisplayStringsForPreset', () {
    test('guitar_standard usa E B G D A E en la UI', () {
      expect(
        tuningDisplayStringsForPreset('guitar_standard'),
        ['E', 'B', 'G', 'D', 'A', 'E'],
      );
    });

    test('ukulele_standard usa A E C G en la UI', () {
      expect(
        tuningDisplayStringsForPreset('ukulele_standard'),
        ['A', 'E', 'C', 'G'],
      );
    });

    test('preset desconocido cae a afinacion estandar de guitarra', () {
      expect(
        tuningDisplayStringsForPreset('unknown'),
        ['E', 'B', 'G', 'D', 'A', 'E'],
      );
    });
  });

  group('tuningDisplayStringsFromSongResult', () {
    test('normaliza octavas y mantiene accidentales', () {
      final result = SongTuningResult(
        query: const SongTuningQuery(songName: 'Everlong'),
        primaryTuning: const GuitarTuning(
          id: 'drop_db',
          displayName: 'Drop Db',
          stringsLowToHigh: ['Db2', 'Ab2', 'Db3', 'Gb3', 'Bb3', 'Eb4'],
        ),
      );

      expect(
        tuningDisplayStringsFromSongResult(result),
        ['Eb', 'Bb', 'Gb', 'Db', 'Ab', 'Db'],
      );
    });
  });

  group('resolveHeaderTuningStrings', () {
    test('prioriza resultado de cancion cuando esta activo', () {
      final result = SongTuningResult(
        query: const SongTuningQuery(songName: 'Everlong'),
        primaryTuning: const GuitarTuning(
          id: 'drop_d',
          displayName: 'Drop D',
          stringsLowToHigh: ['D2', 'A2', 'D3', 'G3', 'B3', 'E4'],
        ),
      );

      expect(
        resolveHeaderTuningStrings(
          presetId: 'guitar_standard',
          songTuningResult: result,
          useSongTuningResult: true,
        ),
        ['E', 'B', 'G', 'D', 'A', 'D'],
      );
    });

    test('usa preset cuando song tuning no esta activo', () {
      final result = SongTuningResult(
        query: const SongTuningQuery(songName: 'Everlong'),
        primaryTuning: const GuitarTuning(
          id: 'drop_d',
          displayName: 'Drop D',
          stringsLowToHigh: ['D2', 'A2', 'D3', 'G3', 'B3', 'E4'],
        ),
      );

      expect(
        resolveHeaderTuningStrings(
          presetId: 'violin_standard',
          songTuningResult: result,
          useSongTuningResult: false,
        ),
        ['E', 'A', 'D', 'G'],
      );
    });
  });
}
