import 'package:equatable/equatable.dart';

import 'metronome_settings.dart';

class MetronomeTick extends Equatable {
  const MetronomeTick({
    required this.beatIndex,
    required this.subdivisionIndex,
    required this.timestampMs,
    required this.accent,
  });

  final int beatIndex;
  final int subdivisionIndex;
  final int timestampMs;
  final BeatAccent accent;

  @override
  List<Object> get props => [
        beatIndex,
        subdivisionIndex,
        timestampMs,
        accent,
      ];
}
