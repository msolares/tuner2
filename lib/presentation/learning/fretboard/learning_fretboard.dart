import 'package:flutter/material.dart';

import 'fretboard_painter.dart';
import 'fretboard_render_model.dart';

final class LearningFretboard extends StatelessWidget {
  const LearningFretboard({
    required this.model,
    this.pulsePhase = 0,
    this.reduceMotion = false,
    this.rotateMessage = 'Gira el dispositivo para comenzar la practica',
    super.key,
  });

  final FretboardRenderModel model;
  final double pulsePhase;
  final bool reduceMotion;
  final String rotateMessage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight > constraints.maxWidth) {
          return ColoredBox(
            color: const Color(0xFF030912),
            child: Semantics(
              container: true,
              header: true,
              label: rotateMessage,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    rotateMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
            ),
          );
        }
        return Semantics(
          container: true,
          liveRegion: model.isWaiting ||
              model.status == FretboardVisualStatus.successFeedback ||
              model.status == FretboardVisualStatus.failure,
          label: model.semanticSummary,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                key: const ValueKey('learning-fretboard-boundary'),
                child: CustomPaint(
                  key: const ValueKey('learning-fretboard-canvas'),
                  painter: FretboardPainter(
                    model: model,
                    pulsePhase: pulsePhase,
                    reduceMotion: reduceMotion,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xDD09121E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _instructionColor(model)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        model.instruction.toUpperCase(),
                        style: TextStyle(
                          color: _instructionColor(model),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Color _instructionColor(FretboardRenderModel model) {
  return switch (model.status) {
    FretboardVisualStatus.waitingForTarget ||
    FretboardVisualStatus.validating =>
      const Color(0xFFFFC52E),
    FretboardVisualStatus.successFeedback => const Color(0xFF42D66A),
    FretboardVisualStatus.failure => const Color(0xFFFF5B61),
    _ => const Color(0xFF73D9FF),
  };
}
