import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fretboard_render_model.dart';

final class FretboardProjection {
  const FretboardProjection();

  static const double horizonDepthY = 0.10;
  static const double executionLineY = 0.72;
  static const double bottomY = 0.98;
  static const double horizonLeft = 0.37;
  static const double horizonRight = 0.63;
  static const double bottomLeft = 0.06;
  static const double bottomRight = 0.94;

  double yForDepth(Size size, double depth) {
    if (depth >= 0) {
      return _lerp(
        size.height * executionLineY,
        size.height * horizonDepthY,
        depth,
      );
    }
    return _lerp(
      size.height * executionLineY,
      size.height * bottomY,
      -depth,
    );
  }

  Offset pointFor(Size size, int stringNumber, double depth) {
    final y = yForDepth(size, depth);
    final horizonY = size.height * horizonDepthY;
    final roadBottomY = size.height * bottomY;
    final verticalProgress =
        ((y - horizonY) / (roadBottomY - horizonY)).clamp(0.0, 1.0).toDouble();
    final left = _lerp(
      size.width * horizonLeft,
      size.width * bottomLeft,
      verticalProgress,
    );
    final right = _lerp(
      size.width * horizonRight,
      size.width * bottomRight,
      verticalProgress,
    );
    final lane =
        (fretboardStringCount - stringNumber) / (fretboardStringCount - 1);
    return Offset(_lerp(left, right, lane), y);
  }

  double laneSpacing(Size size, double depth) {
    final first = pointFor(size, 6, depth);
    final second = pointFor(size, 5, depth);
    return (second.dx - first.dx).abs();
  }
}

final class FretboardPainter extends CustomPainter {
  FretboardPainter({
    required this.model,
    this.pulsePhase = 0,
    this.reduceMotion = false,
    FretboardProjection projection = const FretboardProjection(),
  }) : _projection = projection {
    for (var stringNumber = 1;
        stringNumber <= fretboardStringCount;
        stringNumber++) {
      _stringLabels[stringNumber] = TextPainter(
        text: TextSpan(
          text: '$stringNumber',
          style: TextStyle(
            color: stringColors[stringNumber - 1],
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    for (final block in model.blocks) {
      _labels[block.id] = TextPainter(
        text: TextSpan(
          text: '${block.fret}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
    }
  }

  final FretboardRenderModel model;
  final double pulsePhase;
  final bool reduceMotion;
  final FretboardProjection _projection;
  final Map<int, TextPainter> _stringLabels = {};
  final Map<String, TextPainter> _labels = {};

  static const List<Color> stringColors = [
    Color(0xFF8D5CE6),
    Color(0xFF36B8F4),
    Color(0xFF58C94B),
    Color(0xFFF4D22E),
    Color(0xFFFF9D23),
    Color(0xFFEB5748),
  ];

  final Paint _roadPaint = Paint()..color = const Color(0xFF0B1725);
  final Paint _roadEdgePaint = Paint()
    ..color = const Color(0xFF6D7785)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _fretPaint = Paint()
    ..color = const Color(0x334C5C70)
    ..strokeWidth = 1;
  final Paint _stringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _blockPaint = Paint()..style = PaintingStyle.fill;
  final Paint _blockBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;
  final Paint _executionPaint = Paint()
    ..color = const Color(0xFF73D9FF)
    ..strokeWidth = 3;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF030912));
    _paintRoad(canvas, size);
    _paintFrets(canvas, size);
    _paintStrings(canvas, size);
    _paintStringLabels(canvas, size);
    _paintExecutionLine(canvas, size);
    for (final block in model.blocks) {
      _paintBlock(canvas, size, block);
    }
  }

  void _paintRoad(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * FretboardProjection.horizonLeft,
          size.height * FretboardProjection.horizonDepthY)
      ..lineTo(size.width * FretboardProjection.horizonRight,
          size.height * FretboardProjection.horizonDepthY)
      ..lineTo(size.width * FretboardProjection.bottomRight,
          size.height * FretboardProjection.bottomY)
      ..lineTo(size.width * FretboardProjection.bottomLeft,
          size.height * FretboardProjection.bottomY)
      ..close();
    canvas.drawPath(path, _roadPaint);
    canvas.drawPath(path, _roadEdgePaint);
  }

  void _paintFrets(Canvas canvas, Size size) {
    for (var index = 1; index <= 8; index++) {
      final depth = index / 8;
      canvas.drawLine(
        _projection.pointFor(size, 6, depth),
        _projection.pointFor(size, 1, depth),
        _fretPaint,
      );
    }
    for (var index = 1; index <= 2; index++) {
      final depth = -index / 2;
      canvas.drawLine(
        _projection.pointFor(size, 6, depth),
        _projection.pointFor(size, 1, depth),
        _fretPaint,
      );
    }
  }

  void _paintStrings(Canvas canvas, Size size) {
    for (var stringNumber = 1;
        stringNumber <= fretboardStringCount;
        stringNumber++) {
      _stringPaint
        ..color = stringColors[stringNumber - 1]
        ..strokeWidth = stringNumber == 6 ? 3 : 2;
      canvas.drawLine(
        _projection.pointFor(size, stringNumber, 1),
        _projection.pointFor(size, stringNumber, -1),
        _stringPaint,
      );
    }
  }

  void _paintStringLabels(Canvas canvas, Size size) {
    for (var stringNumber = 1;
        stringNumber <= fretboardStringCount;
        stringNumber++) {
      final point = _projection.pointFor(size, stringNumber, -0.94);
      final label = _stringLabels[stringNumber]!;
      label.paint(
        canvas,
        Offset(point.dx - label.width / 2, point.dy - label.height),
      );
    }
  }

  void _paintBlock(
    Canvas canvas,
    Size size,
    FretboardRenderBlock block,
  ) {
    final start = _projection.pointFor(
      size,
      block.stringNumber,
      block.startDepth,
    );
    final endY = _projection.yForDepth(size, block.endDepth);
    final rawTop = math.min(start.dy, endY);
    final rawBottom = math.max(start.dy, endY);
    final height = math.max(22.0, rawBottom - rawTop);
    final centerY = (rawTop + rawBottom) / 2;
    final width = _projection
        .laneSpacing(size, block.startDepth)
        .clamp(34.0, 92.0)
        .toDouble();
    final rect = Rect.fromCenter(
      center: Offset(start.dx, centerY),
      width: width * 0.78,
      height: height,
    );
    final radius = Radius.circular(math.min(12.0, height / 2));
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final baseColor = stringColors[block.stringNumber - 1];
    final opacity = _blockOpacity(block);
    _blockPaint.color =
        _blockColor(block, baseColor).withValues(alpha: opacity);
    canvas.drawRRect(rrect, _blockPaint);

    _blockBorderPaint
      ..color = block.isTarget ? Colors.white : baseColor.withValues(alpha: 0.9)
      ..strokeWidth = block.isTarget ? _targetStrokeWidth : 1.5;
    canvas.drawRRect(rrect, _blockBorderPaint);

    final label = _labels[block.id]!;
    label.paint(
      canvas,
      Offset(
        rect.center.dx - label.width / 2,
        rect.center.dy - label.height / 2,
      ),
    );
  }

  double _blockOpacity(FretboardRenderBlock block) {
    if (block.isPast) return 0.42;
    if (model.isWaiting && !block.isTarget) return 0.32;
    return 0.94;
  }

  Color _blockColor(FretboardRenderBlock block, Color baseColor) {
    if (!block.isTarget) return baseColor;
    return switch (model.status) {
      FretboardVisualStatus.validating => const Color(0xFFFFB928),
      FretboardVisualStatus.successFeedback => const Color(0xFF42D66A),
      FretboardVisualStatus.failure => const Color(0xFFFF5B61),
      _ => baseColor,
    };
  }

  double get _targetStrokeWidth {
    if (reduceMotion) return 3;
    final normalized = (math.sin(pulsePhase * math.pi * 2) + 1) / 2;
    return 2.5 + normalized * 1.5;
  }

  void _paintExecutionLine(Canvas canvas, Size size) {
    _executionPaint.color = switch (model.status) {
      FretboardVisualStatus.waitingForTarget ||
      FretboardVisualStatus.validating =>
        const Color(0xFFFFC52E),
      FretboardVisualStatus.successFeedback => const Color(0xFF42D66A),
      FretboardVisualStatus.failure => const Color(0xFFFF5B61),
      _ => const Color(0xFF73D9FF),
    };
    canvas.drawLine(
      _projection.pointFor(size, 6, 0),
      _projection.pointFor(size, 1, 0),
      _executionPaint,
    );
    for (var stringNumber = 1;
        stringNumber <= fretboardStringCount;
        stringNumber++) {
      canvas.drawCircle(
        _projection.pointFor(size, stringNumber, 0),
        4,
        _executionPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FretboardPainter oldDelegate) {
    return model != oldDelegate.model ||
        pulsePhase != oldDelegate.pulsePhase ||
        reduceMotion != oldDelegate.reduceMotion;
  }
}

double _lerp(double start, double end, double amount) {
  return start + (end - start) * amount;
}
