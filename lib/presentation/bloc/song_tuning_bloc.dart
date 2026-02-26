import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/song_tuning_query.dart';
import '../../domain/services/song_tuning_lookup_exception.dart';
import '../../domain/services/song_tuning_service.dart';
import 'song_tuning_event.dart';
import 'song_tuning_state.dart';

class SongTuningBloc extends Bloc<SongTuningEvent, SongTuningState> {
  SongTuningBloc({
    required SongTuningService songTuningService,
  })  : _songTuningService = songTuningService,
        super(const SongTuningState()) {
    on<SongNameChanged>(_onSongNameChanged);
    on<SongTuningSubmitted>(_onSongTuningSubmitted);
  }

  final SongTuningService _songTuningService;

  void _onSongNameChanged(
    SongNameChanged event,
    Emitter<SongTuningState> emit,
  ) {
    emit(
      state.copyWith(
        songName: event.songName,
        status: SongTuningStatus.idle,
        clearError: true,
      ),
    );
  }

  Future<void> _onSongTuningSubmitted(
    SongTuningSubmitted event,
    Emitter<SongTuningState> emit,
  ) async {
    final normalizedSongName = state.songName.trim();
    if (normalizedSongName.isEmpty) {
      emit(
        state.copyWith(
          status: SongTuningStatus.error,
          errorCode: SongTuningErrorCode.invalidQuery.name,
          errorMessage: 'Ingresa una cancion para consultar la afinacion.',
          clearResult: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SongTuningStatus.loading,
        clearError: true,
      ),
    );
    try {
      final result = await _songTuningService.resolve(
        SongTuningQuery(songName: normalizedSongName),
      );
      emit(
        state.copyWith(
          status: SongTuningStatus.success,
          result: result,
          clearError: true,
        ),
      );
    } on SongTuningLookupException catch (error) {
      emit(
        state.copyWith(
          status: SongTuningStatus.error,
          errorCode: error.code.name,
          errorMessage: _mapErrorMessage(error),
          clearResult: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SongTuningStatus.error,
          errorCode: SongTuningErrorCode.unknown.name,
          errorMessage: 'No se pudo obtener la afinacion en este momento.',
          clearResult: true,
        ),
      );
    }
  }

  String _mapErrorMessage(SongTuningLookupException error) {
    if (error.code == SongTuningErrorCode.unauthorized) {
      if (error.message == 'openai_api_key_missing') {
        return 'No hay API key configurada. Ejecuta con --dart-define=OPENAI_API_KEY=tu_api_key';
      }
      return 'OpenAI rechazo la API key o los permisos del proyecto (401/403).';
    }

    return switch (error.code) {
      SongTuningErrorCode.invalidQuery => 'Ingresa una cancion valida para consultar.',
      SongTuningErrorCode.notFound => 'No encontramos una afinacion para esa cancion.',
      SongTuningErrorCode.ambiguousSong => 'Hay varias coincidencias. Prueba con un titulo mas especifico.',
      SongTuningErrorCode.timeout => 'La consulta tardo demasiado. Reintenta.',
      SongTuningErrorCode.rateLimited => 'Demasiadas consultas seguidas. Espera unos segundos.',
      SongTuningErrorCode.providerUnavailable => 'Servicio temporalmente no disponible. Reintenta.',
      SongTuningErrorCode.invalidResponse => 'Respuesta no valida del servicio de afinacion.',
      SongTuningErrorCode.unknown => 'No se pudo obtener la afinacion en este momento.',
      SongTuningErrorCode.unauthorized => 'OpenAI rechazo la API key o los permisos del proyecto (401/403).',
    };
  }
}
