import 'package:equatable/equatable.dart';

import '../../domain/entities/metronome_settings.dart';

enum MetronomeStatus { initial, idle, playing, failure }

class MetronomeState extends Equatable {
  const MetronomeState({
    required this.status,
    required this.settings,
    this.activeBeatIndex,
    this.activeSubdivisionIndex,
    this.errorMessage,
  });

  factory MetronomeState.initial(MetronomeSettings settings) {
    return MetronomeState(
      status: MetronomeStatus.initial,
      settings: settings,
    );
  }

  final MetronomeStatus status;
  final MetronomeSettings settings;
  final int? activeBeatIndex;
  final int? activeSubdivisionIndex;
  final String? errorMessage;

  bool get isPlaying => status == MetronomeStatus.playing;

  MetronomeState copyWith({
    MetronomeStatus? status,
    MetronomeSettings? settings,
    int? activeBeatIndex,
    int? activeSubdivisionIndex,
    String? errorMessage,
    bool clearActiveTick = false,
    bool clearError = false,
  }) {
    return MetronomeState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      activeBeatIndex:
          clearActiveTick ? null : activeBeatIndex ?? this.activeBeatIndex,
      activeSubdivisionIndex: clearActiveTick
          ? null
          : activeSubdivisionIndex ?? this.activeSubdivisionIndex,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        settings,
        activeBeatIndex,
        activeSubdivisionIndex,
        errorMessage,
      ];
}
