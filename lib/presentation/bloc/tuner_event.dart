import 'package:equatable/equatable.dart';

abstract class TunerEvent extends Equatable {
  const TunerEvent();

  @override
  List<Object?> get props => const [];
}

class StartListening extends TunerEvent {
  const StartListening();
}

class StopListening extends TunerEvent {
  const StopListening();
}

class UpdateA4 extends TunerEvent {
  const UpdateA4(this.a4Hz);

  final double a4Hz;

  @override
  List<Object?> get props => [a4Hz];
}

class SelectPreset extends TunerEvent {
  const SelectPreset(this.instrumentPreset);

  final String instrumentPreset;

  @override
  List<Object?> get props => [instrumentPreset];
}

class AudioPermissionChecked extends TunerEvent {
  const AudioPermissionChecked(this.granted);

  final bool granted;

  @override
  List<Object?> get props => [granted];
}
