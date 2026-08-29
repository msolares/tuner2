import 'package:afinador/data/engines/common/pitch_reliability_gate.dart';
import 'package:afinador/data/engines/common/pitch_reliability_profile.dart';
import 'package:afinador/domain/entities/pitch_sample.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PitchReliabilityGate', () {
    test('requires stable confirmation before locking a guitar string', () {
      final gate = PitchReliabilityGate();
      final profile = reliabilityProfileForPreset('guitar_standard');

      final first = gate.filter(
        sample: _sample(
            note: 'E2',
            hz: 82.41,
            cents: 6.0,
            confidence: 0.92,
            timestampMs: 100),
        profile: profile,
      );
      final second = gate.filter(
        sample: _sample(
            note: 'E2',
            hz: 82.70,
            cents: 11.0,
            confidence: 0.90,
            timestampMs: 220),
        profile: profile,
      );
      final third = gate.filter(
        sample: _sample(
            note: 'E2',
            hz: 82.55,
            cents: 8.0,
            confidence: 0.91,
            timestampMs: 340),
        profile: profile,
      );

      expect(first.note, '--');
      expect(second.note, 'E2');
      expect(third.note, 'E2');
      expect(third.confidence, greaterThan(0.4));
    });

    test('suppresses a transient wrong string while a lock is active', () {
      final gate = PitchReliabilityGate();
      final profile = reliabilityProfileForPreset('guitar_standard');

      gate.filter(
        sample: _sample(
            note: 'E2',
            hz: 82.41,
            cents: 5.0,
            confidence: 0.92,
            timestampMs: 100),
        profile: profile,
      );
      gate.filter(
        sample: _sample(
            note: 'E2',
            hz: 82.55,
            cents: 8.0,
            confidence: 0.91,
            timestampMs: 220),
        profile: profile,
      );
      final locked = gate.filter(
        sample: _sample(
            note: 'E2',
            hz: 82.60,
            cents: 9.0,
            confidence: 0.93,
            timestampMs: 340),
        profile: profile,
      );
      final transient = gate.filter(
        sample: _sample(
            note: 'A2',
            hz: 110.0,
            cents: 1.0,
            confidence: 0.88,
            timestampMs: 460),
        profile: profile,
      );
      final recovered = gate.filter(
        sample: _sample(
            note: 'E2',
            hz: 82.48,
            cents: 7.0,
            confidence: 0.91,
            timestampMs: 580),
        profile: profile,
      );

      expect(locked.note, 'E2');
      expect(transient.note, '--');
      expect(recovered.note, 'E2');
    });

    test('switches to a new string after sustained real change', () {
      final gate = PitchReliabilityGate();
      final profile = reliabilityProfileForPreset('guitar_standard');

      gate.filter(
        sample: _sample(
            note: 'E2',
            hz: 82.41,
            cents: 5.0,
            confidence: 0.92,
            timestampMs: 100),
        profile: profile,
      );
      gate.filter(
        sample: _sample(
            note: 'E2',
            hz: 82.55,
            cents: 7.0,
            confidence: 0.91,
            timestampMs: 220),
        profile: profile,
      );
      gate.filter(
        sample: _sample(
            note: 'E2',
            hz: 82.60,
            cents: 8.0,
            confidence: 0.93,
            timestampMs: 340),
        profile: profile,
      );

      final firstSwitchFrame = gate.filter(
        sample: _sample(
            note: 'A2',
            hz: 110.0,
            cents: 3.0,
            confidence: 0.91,
            timestampMs: 460),
        profile: profile,
      );
      final switched = gate.filter(
        sample: _sample(
            note: 'A2',
            hz: 110.25,
            cents: 7.0,
            confidence: 0.92,
            timestampMs: 580),
        profile: profile,
      );

      expect(firstSwitchFrame.note, '--');
      expect(switched.note, 'A2');
      expect(switched.cents, closeTo(signedCentsBetween(110.25, 110.0), 0.5));
    });

    test('rejects voiced input outside the guitar string set', () {
      final gate = PitchReliabilityGate();
      final profile = reliabilityProfileForPreset('guitar_standard');

      final first = gate.filter(
        sample: _sample(
            note: 'A3',
            hz: 220.0,
            cents: 2.0,
            confidence: 0.90,
            timestampMs: 100),
        profile: profile,
      );
      final second = gate.filter(
        sample: _sample(
            note: 'A3',
            hz: 220.0,
            cents: 1.0,
            confidence: 0.90,
            timestampMs: 220),
        profile: profile,
      );
      expect(first.note, '--');
      expect(second.note, '--');
      expect(second.confidence, 0.0);
    });

    test('allows strong chromatic detection after note confirmation', () {
      final gate = PitchReliabilityGate();
      final profile = reliabilityProfileForPreset('chromatic');

      gate.filter(
        sample: _sample(
            note: 'A4',
            hz: 440.0,
            cents: 1.0,
            confidence: 0.88,
            timestampMs: 100),
        profile: profile,
      );
      final confirmed = gate.filter(
        sample: _sample(
            note: 'A4',
            hz: 440.0,
            cents: 0.5,
            confidence: 0.90,
            timestampMs: 220),
        profile: profile,
      );

      expect(confirmed.note, 'A4');
      expect(confirmed.confidence, greaterThan(0.5));
    });

    test('keeps guitar acquisition across one brief confidence dropout', () {
      final gate = PitchReliabilityGate();
      final profile = reliabilityProfileForPreset('guitar_standard');

      final first = gate.filter(
        sample: _sample(
            note: 'E2',
            hz: 82.41,
            cents: 4.0,
            confidence: 0.58,
            timestampMs: 100),
        profile: profile,
      );
      final dropout = gate.filter(
        sample: _sample(
            note: '--', hz: 0.0, cents: 0.0, confidence: 0.0, timestampMs: 150),
        profile: profile,
      );
      final acquired = gate.filter(
        sample: _sample(
            note: 'E2',
            hz: 82.55,
            cents: 7.0,
            confidence: 0.55,
            timestampMs: 200),
        profile: profile,
      );

      expect(first.note, '--');
      expect(dropout.note, '--');
      expect(acquired.note, 'E2');
    });

    test('keeps a chromatic lock across one weak frame', () {
      final gate = PitchReliabilityGate();
      final profile = reliabilityProfileForPreset('chromatic');

      gate.filter(
        sample: _sample(
            note: 'A4',
            hz: 440.0,
            cents: 0.0,
            confidence: 0.55,
            timestampMs: 100),
        profile: profile,
      );
      final locked = gate.filter(
        sample: _sample(
            note: 'A4',
            hz: 440.0,
            cents: 0.0,
            confidence: 0.54,
            timestampMs: 150),
        profile: profile,
      );
      gate.filter(
        sample: _sample(
            note: '--', hz: 0.0, cents: 0.0, confidence: 0.0, timestampMs: 200),
        profile: profile,
      );
      final recovered = gate.filter(
        sample: _sample(
            note: 'A4',
            hz: 440.2,
            cents: 0.8,
            confidence: 0.52,
            timestampMs: 250),
        profile: profile,
      );

      expect(locked.note, 'A4');
      expect(recovered.note, 'A4');
    });

    test('acquires a guitar string far enough out to require tuning', () {
      final gate = PitchReliabilityGate();
      final profile = reliabilityProfileForPreset('guitar_standard');

      gate.filter(
        sample: _sample(
            note: 'F2',
            hz: 89.85,
            cents: 148.0,
            confidence: 0.82,
            timestampMs: 100),
        profile: profile,
      );
      final acquired = gate.filter(
        sample: _sample(
            note: 'F2',
            hz: 89.75,
            cents: 146.0,
            confidence: 0.80,
            timestampMs: 160),
        profile: profile,
      );

      expect(acquired.note, 'E2');
      expect(acquired.cents, greaterThan(140.0));
      expect(acquired.confidence, greaterThan(profile.minReliableConfidence));
    });

    test('all instrument presets acquire a clean target with modest confidence',
        () {
      const presets = <String>[
        'guitar_standard',
        'bass_standard',
        'ukulele_standard',
        'violin_standard',
      ];

      for (final preset in presets) {
        final gate = PitchReliabilityGate();
        final profile = reliabilityProfileForPreset(preset);
        final target = profile.targets.first;
        PitchSample result = _sample(
          note: target.note,
          hz: target.hz,
          cents: 0.0,
          confidence: 0.55,
          timestampMs: 100,
        );
        for (var frame = 0; frame < profile.confirmationFrames; frame++) {
          result = gate.filter(
            sample: _sample(
              note: target.note,
              hz: target.hz,
              cents: 0.0,
              confidence: 0.55,
              timestampMs: 100 + frame * 60,
            ),
            profile: profile,
          );
        }
        expect(result.note, target.note, reason: preset);
      }
    });

    test('acquires a quiet A2 across rejected bright-harmonic outliers', () {
      final gate = PitchReliabilityGate();
      final profile = reliabilityProfileForPreset('guitar_standard');

      final firstA2 = gate.filter(
        sample: _sample(
            note: 'A2',
            hz: 110.85,
            cents: 13.4,
            confidence: 0.24,
            timestampMs: 100),
        profile: profile,
      );
      final brightOutlier = gate.filter(
        sample: _sample(
            note: 'G4',
            hz: 401.0,
            cents: 40.0,
            confidence: 0.62,
            timestampMs: 160),
        profile: profile,
      );
      final acquired = gate.filter(
        sample: _sample(
            note: 'A2',
            hz: 110.75,
            cents: 11.8,
            confidence: 0.26,
            timestampMs: 220),
        profile: profile,
      );

      expect(firstA2.note, '--');
      expect(brightOutlier.note, '--');
      expect(acquired.note, 'A2');
    });
  });
}

PitchSample _sample({
  required String note,
  required double hz,
  required double cents,
  required double confidence,
  required int timestampMs,
}) {
  return PitchSample(
    hz: hz,
    note: note,
    cents: cents,
    confidence: confidence,
    timestampMs: timestampMs,
  );
}
