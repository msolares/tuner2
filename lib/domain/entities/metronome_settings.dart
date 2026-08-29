import 'package:equatable/equatable.dart';

import 'time_signature.dart';

enum BeatAccent { strong, normal, muted }

enum BeatSubdivision {
  single(1),
  duplet(2),
  triplet(3),
  quadruplet(4);

  const BeatSubdivision(this.pulses);

  final int pulses;
}

class BeatConfig extends Equatable {
  const BeatConfig({
    required this.accent,
    required this.subdivision,
  });

  const BeatConfig.normal({
    this.subdivision = BeatSubdivision.single,
  }) : accent = BeatAccent.normal;

  final BeatAccent accent;
  final BeatSubdivision subdivision;

  BeatConfig copyWith({
    BeatAccent? accent,
    BeatSubdivision? subdivision,
  }) {
    return BeatConfig(
      accent: accent ?? this.accent,
      subdivision: subdivision ?? this.subdivision,
    );
  }

  Map<String, Object> toJson() => {
        'accent': accent.name,
        'subdivision': subdivision.name,
      };

  factory BeatConfig.fromJson(Map<String, dynamic> json) {
    return BeatConfig(
      accent: BeatAccent.values.byName(json['accent'] as String),
      subdivision: BeatSubdivision.values.byName(
        json['subdivision'] as String,
      ),
    );
  }

  @override
  List<Object> get props => [accent, subdivision];
}

/// Configuración completa e inmutable del metrónomo.
class MetronomeSettings extends Equatable {
  factory MetronomeSettings({
    required int bpm,
    required TimeSignature timeSignature,
    required List<BeatConfig> beats,
  }) {
    if (bpm < minBpm || bpm > maxBpm) {
      throw RangeError.range(bpm, minBpm, maxBpm, 'bpm');
    }
    if (beats.length != timeSignature.numerator) {
      throw ArgumentError.value(
        beats.length,
        'beats',
        'Debe coincidir con el numerador ${timeSignature.numerator}.',
      );
    }
    final strongCount =
        beats.where((beat) => beat.accent == BeatAccent.strong).length;
    if (strongCount != 1) {
      throw ArgumentError.value(
        strongCount,
        'beats',
        'Debe existir exactamente un tiempo fuerte.',
      );
    }
    return MetronomeSettings._(
      bpm,
      timeSignature,
      List<BeatConfig>.unmodifiable(beats),
    );
  }

  const MetronomeSettings._(this.bpm, this.timeSignature, this.beats);

  static const int minBpm = 20;
  static const int maxBpm = 300;
  static const int defaultBpm = 120;

  final int bpm;
  final TimeSignature timeSignature;
  final List<BeatConfig> beats;

  static MetronomeSettings get defaults => MetronomeSettings(
        bpm: defaultBpm,
        timeSignature: TimeSignature(numerator: 4, denominator: 4),
        beats: const [
          BeatConfig(
            accent: BeatAccent.strong,
            subdivision: BeatSubdivision.single,
          ),
          BeatConfig.normal(),
          BeatConfig.normal(),
          BeatConfig.normal(),
        ],
      );

  MetronomeSettings copyWith({
    int? bpm,
    TimeSignature? timeSignature,
    List<BeatConfig>? beats,
  }) {
    final nextSignature = timeSignature ?? this.timeSignature;
    return MetronomeSettings(
      bpm: bpm ?? this.bpm,
      timeSignature: nextSignature,
      beats: beats ??
          (nextSignature == this.timeSignature
              ? this.beats
              : normalizeBeats(this.beats, nextSignature.numerator)),
    );
  }

  MetronomeSettings withStrongBeat(int index) {
    RangeError.checkValidIndex(index, beats, 'index');
    final nextBeats = [
      for (var current = 0; current < beats.length; current++)
        beats[current].copyWith(
          accent: current == index
              ? BeatAccent.strong
              : beats[current].accent == BeatAccent.strong
                  ? BeatAccent.normal
                  : beats[current].accent,
        ),
    ];
    return copyWith(beats: nextBeats);
  }

  MetronomeSettings withBeatSubdivision(
    int index,
    BeatSubdivision subdivision,
  ) {
    RangeError.checkValidIndex(index, beats, 'index');
    final nextBeats = List<BeatConfig>.of(beats);
    nextBeats[index] = nextBeats[index].copyWith(subdivision: subdivision);
    return copyWith(beats: nextBeats);
  }

  MetronomeSettings withBeatMuted(int index, bool muted) {
    RangeError.checkValidIndex(index, beats, 'index');
    if (beats[index].accent == BeatAccent.strong && muted) {
      throw StateError('La tónica no se puede silenciar.');
    }
    final nextBeats = List<BeatConfig>.of(beats);
    nextBeats[index] = nextBeats[index].copyWith(
      accent: muted ? BeatAccent.muted : BeatAccent.normal,
    );
    return copyWith(beats: nextBeats);
  }

  static List<BeatConfig> normalizeBeats(
    List<BeatConfig> current,
    int targetLength,
  ) {
    if (targetLength < TimeSignature.minNumerator ||
        targetLength > TimeSignature.maxNumerator) {
      throw RangeError.range(
        targetLength,
        TimeSignature.minNumerator,
        TimeSignature.maxNumerator,
        'targetLength',
      );
    }
    final normalized = <BeatConfig>[
      for (var index = 0; index < targetLength; index++)
        index < current.length ? current[index] : const BeatConfig.normal(),
    ];
    if (!normalized.any((beat) => beat.accent == BeatAccent.strong)) {
      normalized[0] = normalized[0].copyWith(accent: BeatAccent.strong);
    }
    var foundStrong = false;
    for (var index = 0; index < normalized.length; index++) {
      if (normalized[index].accent != BeatAccent.strong) {
        continue;
      }
      if (!foundStrong) {
        foundStrong = true;
      } else {
        normalized[index] = normalized[index].copyWith(
          accent: BeatAccent.normal,
        );
      }
    }
    return List<BeatConfig>.unmodifiable(normalized);
  }

  Map<String, Object> toJson() => {
        'version': 1,
        'bpm': bpm,
        'timeSignature': timeSignature.toJson(),
        'beats': beats.map((beat) => beat.toJson()).toList(),
      };

  factory MetronomeSettings.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Versión de configuración no soportada.');
    }
    return MetronomeSettings(
      bpm: json['bpm'] as int,
      timeSignature: TimeSignature.fromJson(
        Map<String, dynamic>.from(json['timeSignature'] as Map),
      ),
      beats: (json['beats'] as List)
          .map(
            (beat) => BeatConfig.fromJson(
              Map<String, dynamic>.from(beat as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  List<Object> get props => [bpm, timeSignature, beats];
}
