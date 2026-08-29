import 'package:afinador/domain/entities/metronome_settings.dart';
import 'package:afinador/domain/entities/time_signature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetronomeSettings', () {
    test('defaults are valid 120 BPM in 4/4', () {
      final settings = MetronomeSettings.defaults;

      expect(settings.bpm, 120);
      expect(
          settings.timeSignature, TimeSignature(numerator: 4, denominator: 4));
      expect(settings.beats, hasLength(4));
      expect(settings.beats.first.accent, BeatAccent.strong);
    });

    test('rejects BPM outside supported range', () {
      expect(
        () => MetronomeSettings.defaults.copyWith(bpm: 19),
        throwsRangeError,
      );
      expect(
        () => MetronomeSettings.defaults.copyWith(bpm: 301),
        throwsRangeError,
      );
    });

    test('rejects mismatched beat count and multiple strong beats', () {
      final signature = TimeSignature(numerator: 3, denominator: 4);
      expect(
        () => MetronomeSettings(
          bpm: 120,
          timeSignature: signature,
          beats: const [
            BeatConfig(
              accent: BeatAccent.strong,
              subdivision: BeatSubdivision.single,
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => MetronomeSettings(
          bpm: 120,
          timeSignature: signature,
          beats: const [
            BeatConfig(
              accent: BeatAccent.strong,
              subdivision: BeatSubdivision.single,
            ),
            BeatConfig(
              accent: BeatAccent.strong,
              subdivision: BeatSubdivision.single,
            ),
            BeatConfig.normal(),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('normalizes beats while preserving compatible configuration', () {
      final customized = MetronomeSettings.defaults
          .withStrongBeat(2)
          .withBeatSubdivision(1, BeatSubdivision.triplet)
          .copyWith(
            timeSignature: TimeSignature(numerator: 6, denominator: 8),
          );

      expect(customized.beats, hasLength(6));
      expect(customized.beats[1].subdivision, BeatSubdivision.triplet);
      expect(customized.beats[2].accent, BeatAccent.strong);
      expect(customized.beats[4], const BeatConfig.normal());

      final reduced = customized.copyWith(
        timeSignature: TimeSignature(numerator: 2, denominator: 4),
      );
      expect(reduced.beats, hasLength(2));
      expect(reduced.beats.first.accent, BeatAccent.strong);
    });

    test('moves the strong beat and protects it from muting', () {
      final settings = MetronomeSettings.defaults.withStrongBeat(3);

      expect(settings.beats[0].accent, BeatAccent.normal);
      expect(settings.beats[3].accent, BeatAccent.strong);
      expect(() => settings.withBeatMuted(3, true), throwsStateError);
    });

    test('serializes and restores a versioned configuration', () {
      final settings = MetronomeSettings.defaults
          .copyWith(bpm: 156)
          .withBeatSubdivision(2, BeatSubdivision.quadruplet);

      expect(MetronomeSettings.fromJson(settings.toJson()), settings);
    });
  });

  group('TimeSignature', () {
    test('validates numerator and denominator', () {
      expect(
        () => TimeSignature(numerator: 0, denominator: 4),
        throwsRangeError,
      );
      expect(
        () => TimeSignature(numerator: 4, denominator: 3),
        throwsArgumentError,
      );
    });

    test('uses value equality', () {
      expect(
        TimeSignature(numerator: 7, denominator: 8),
        TimeSignature(numerator: 7, denominator: 8),
      );
    });
  });
}
