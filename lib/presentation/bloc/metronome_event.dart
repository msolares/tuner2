import 'package:equatable/equatable.dart';

import '../../domain/entities/metronome_settings.dart';
import '../../domain/entities/metronome_tick.dart';
import '../../domain/entities/time_signature.dart';

sealed class MetronomeEvent extends Equatable {
  const MetronomeEvent();

  @override
  List<Object?> get props => const [];
}

class MetronomeInitialized extends MetronomeEvent {
  const MetronomeInitialized();
}

class MetronomeStarted extends MetronomeEvent {
  const MetronomeStarted();
}

class MetronomeStopped extends MetronomeEvent {
  const MetronomeStopped();
}

class TempoChanged extends MetronomeEvent {
  const TempoChanged(this.bpm);
  final int bpm;

  @override
  List<Object> get props => [bpm];
}

class TapTempoPressed extends MetronomeEvent {
  const TapTempoPressed();
}

class TimeSignatureChanged extends MetronomeEvent {
  const TimeSignatureChanged(this.timeSignature);
  final TimeSignature timeSignature;

  @override
  List<Object> get props => [timeSignature];
}

class StrongBeatChanged extends MetronomeEvent {
  const StrongBeatChanged(this.beatIndex);
  final int beatIndex;

  @override
  List<Object> get props => [beatIndex];
}

class BeatMutedChanged extends MetronomeEvent {
  const BeatMutedChanged(this.beatIndex, this.muted);
  final int beatIndex;
  final bool muted;

  @override
  List<Object> get props => [beatIndex, muted];
}

class BeatSubdivisionChanged extends MetronomeEvent {
  const BeatSubdivisionChanged(this.beatIndex, this.subdivision);
  final int beatIndex;
  final BeatSubdivision subdivision;

  @override
  List<Object> get props => [beatIndex, subdivision];
}

class MetronomeTickReceived extends MetronomeEvent {
  const MetronomeTickReceived(this.tick);
  final MetronomeTick tick;

  @override
  List<Object> get props => [tick];
}

class MetronomeFailed extends MetronomeEvent {
  const MetronomeFailed(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
