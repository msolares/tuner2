import 'package:equatable/equatable.dart';

import '../../domain/entities/pitch_sample.dart';
import '../../domain/entities/tuner_settings.dart';

abstract class TunerState extends Equatable {
  const TunerState({
    required this.settings,
    this.sample,
  });

  final TunerSettings settings;
  final PitchSample? sample;

  @override
  List<Object?> get props => [settings, sample];
}

class Idle extends TunerState {
  const Idle({
    required super.settings,
    super.sample,
  });
}

class Listening extends TunerState {
  const Listening({
    required super.settings,
    super.sample,
  });
}

class InTune extends TunerState {
  const InTune({
    required super.settings,
    required PitchSample super.sample,
  });
}

class OutOfTune extends TunerState {
  const OutOfTune({
    required super.settings,
    required PitchSample super.sample,
  });
}

class ErrorState extends TunerState {
  const ErrorState({
    required super.settings,
    required this.code,
    required this.message,
    required this.recoverable,
    super.sample,
  });

  final String code;
  final String message;
  final bool recoverable;

  @override
  List<Object?> get props => [...super.props, code, message, recoverable];
}
