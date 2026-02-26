import 'package:equatable/equatable.dart';

import '../../domain/entities/song_tuning_result.dart';

enum SongTuningStatus {
  idle,
  loading,
  success,
  error,
}

class SongTuningState extends Equatable {
  const SongTuningState({
    this.songName = '',
    this.status = SongTuningStatus.idle,
    this.result,
    this.errorCode,
    this.errorMessage,
  });

  final String songName;
  final SongTuningStatus status;
  final SongTuningResult? result;
  final String? errorCode;
  final String? errorMessage;

  bool get canSubmit => songName.trim().isNotEmpty && status != SongTuningStatus.loading;
  bool get isLoading => status == SongTuningStatus.loading;

  SongTuningState copyWith({
    String? songName,
    SongTuningStatus? status,
    SongTuningResult? result,
    String? errorCode,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return SongTuningState(
      songName: songName ?? this.songName,
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        songName,
        status,
        result,
        errorCode,
        errorMessage,
      ];
}

