import 'package:flutter/material.dart';

import '../../../../domain/learning/learning.dart';
import '../../../../app/app_theme.dart';

final class LessonChordDiagram extends StatelessWidget {
  const LessonChordDiagram({
    required this.chord,
    required this.observation,
    required this.pitchClassNames,
    required this.evidenceLabel,
    required this.pendingLabel,
    this.compact = false,
    super.key,
  });

  final LessonChordEvent chord;
  final ChordPerformanceObservation? observation;
  final List<String> pitchClassNames;
  final String evidenceLabel;
  final String pendingLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final requiredPitchClasses = chord.requiredPitchClasses.toList()..sort();
    return Semantics(
      container: true,
      label: '${chord.symbol}. $evidenceLabel',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                chord.symbol,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: compact ? 4 : 8),
              SizedBox(
                height: compact ? 64 : 116,
                child: CustomPaint(
                  key: const ValueKey('lesson-chord-diagram'),
                  painter: _ChordDiagramPainter(chord),
                ),
              ),
              SizedBox(height: compact ? 4 : 10),
              if (!compact) ...[
                Text(
                  evidenceLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 6),
              ],
              for (final pitchClass in requiredPitchClasses)
                _PitchEvidenceRow(
                  name: pitchClassNames[pitchClass],
                  value: observation?.pitchClassStrengths[pitchClass],
                  pendingLabel: pendingLabel,
                  compact: compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _PitchEvidenceRow extends StatelessWidget {
  const _PitchEvidenceRow({
    required this.name,
    required this.value,
    required this.pendingLabel,
    required this.compact,
  });

  final String name;
  final double? value;
  final String pendingLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final percentage = value == null ? pendingLabel : '${(value! * 100).round()}%';
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Semantics(
        label: '$name, $percentage',
        child: Row(
          children: [
            SizedBox(
              width: compact ? 42 : 70,
              child: Text(name, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: LinearProgressIndicator(
                value: value ?? 0,
                minHeight: 7,
                borderRadius: BorderRadius.circular(7),
                backgroundColor: AppTheme.outlineMuted,
                color: AppTheme.tuneBlue,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: compact ? 42 : 58,
              child: Text(
                percentage,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ChordDiagramPainter extends CustomPainter {
  const _ChordDiagramPainter(this.chord);

  final LessonChordEvent chord;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textSecondary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const top = 18.0;
    final bottom = size.height - 8;
    final left = size.width * 0.16;
    final right = size.width * 0.84;
    final stringGap = (right - left) / 5;
    final fretGap = (bottom - top) / 4;

    for (var stringIndex = 0; stringIndex < 6; stringIndex++) {
      final x = left + stringGap * stringIndex;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
    for (var fretIndex = 0; fretIndex <= 4; fretIndex++) {
      final y = top + fretGap * fretIndex;
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }

    final tonePaint = Paint()
      ..color = AppTheme.tuneBlue
      ..style = PaintingStyle.fill;
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    final byString = <int, ChordToneTarget>{
      for (final tone in chord.tones) tone.position.stringNumber: tone,
    };
    for (var stringNumber = 6; stringNumber >= 1; stringNumber--) {
      final x = left + (6 - stringNumber) * stringGap;
      final tone = byString[stringNumber];
      if (tone == null) {
        labelPainter.text = const TextSpan(
          text: '×',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
        );
        labelPainter.layout();
        labelPainter.paint(canvas, Offset(x - labelPainter.width / 2, 0));
      } else if (tone.position.fret == 0) {
        canvas.drawCircle(Offset(x, 7), 4, paint);
      } else {
        final visibleFret = tone.position.fret.clamp(1, 4).toDouble();
        final y = top + (visibleFret - .5) * fretGap;
        canvas.drawCircle(Offset(x, y), 7, tonePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ChordDiagramPainter oldDelegate) =>
      oldDelegate.chord != chord;
}
