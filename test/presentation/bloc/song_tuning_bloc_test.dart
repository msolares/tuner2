import 'package:afinador/domain/entities/guitar_tuning.dart';
import 'package:afinador/domain/entities/song_tuning_query.dart';
import 'package:afinador/domain/entities/song_tuning_result.dart';
import 'package:afinador/domain/services/song_tuning_lookup_exception.dart';
import 'package:afinador/domain/services/song_tuning_service.dart';
import 'package:afinador/presentation/bloc/song_tuning_bloc.dart';
import 'package:afinador/presentation/bloc/song_tuning_event.dart';
import 'package:afinador/presentation/bloc/song_tuning_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongTuningBloc', () {
    test('flujo exito: loading -> success con resultado', () async {
      final service = _FakeSongTuningService(
        result: SongTuningResult(
          query: const SongTuningQuery(songName: 'Everlong'),
          primaryTuning: const GuitarTuning(
            id: 'drop_d',
            displayName: 'Drop D',
            stringsLowToHigh: ['D2', 'A2', 'D3', 'G3', 'B3', 'E4'],
          ),
        ),
      );
      final bloc = SongTuningBloc(songTuningService: service);

      bloc.add(const SongNameChanged('Everlong'));
      bloc.add(const SongTuningSubmitted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SongTuningState>().having((s) => s.songName, 'songName', 'Everlong'),
          isA<SongTuningState>().having((s) => s.status, 'status', SongTuningStatus.loading),
          isA<SongTuningState>().having((s) => s.status, 'status', SongTuningStatus.success),
        ]),
      );
      expect(service.calls, 1);
      expect(bloc.state.result?.primaryTuning.id, 'drop_d');

      await bloc.close();
    });

    test('input vacio: emite error invalidQuery y no consulta servicio', () async {
      final service = _FakeSongTuningService();
      final bloc = SongTuningBloc(songTuningService: service);

      bloc.add(const SongTuningSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.status, SongTuningStatus.error);
      expect(bloc.state.errorCode, SongTuningErrorCode.invalidQuery.name);
      expect(service.calls, 0);

      await bloc.close();
    });

    test('error del servicio: emite estado error con codigo mapeado', () async {
      final service = _FakeSongTuningService(
        error: const SongTuningLookupException(SongTuningErrorCode.timeout),
      );
      final bloc = SongTuningBloc(songTuningService: service);

      bloc.add(const SongNameChanged('Everlong'));
      bloc.add(const SongTuningSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.status, SongTuningStatus.error);
      expect(bloc.state.errorCode, SongTuningErrorCode.timeout.name);
      expect(service.calls, 1);

      await bloc.close();
    });
  });
}

class _FakeSongTuningService implements SongTuningService {
  _FakeSongTuningService({
    this.result,
    this.error,
  });

  final SongTuningResult? result;
  final SongTuningLookupException? error;
  int calls = 0;

  @override
  Future<SongTuningResult> resolve(SongTuningQuery query) async {
    calls += 1;
    if (error != null) {
      throw error!;
    }
    if (result != null) {
      return result!;
    }
    throw const SongTuningLookupException(SongTuningErrorCode.unknown);
  }
}

