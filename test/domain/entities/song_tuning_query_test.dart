import 'package:afinador/domain/entities/song_tuning_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongTuningQuery', () {
    test('normaliza song y artista trimmeando espacios', () {
      const query = SongTuningQuery(
        songName: '  Hotel California  ',
        artistName: '  Eagles  ',
      );

      expect(query.normalizedSongName, 'Hotel California');
      expect(query.normalizedArtistName, 'Eagles');
      expect(query.isValid, isTrue);
    });

    test('isValid es false cuando songName queda vacio', () {
      const query = SongTuningQuery(songName: '   ');

      expect(query.isValid, isFalse);
      expect(query.normalizedArtistName, isNull);
    });
  });
}

