import 'dart:async';

import 'package:afinador/domain/learning/learning.dart';

/// Fake manual reutilizable para probar BLoC/casos de uso sin tiempo real.
final class DeterministicLessonClock implements LessonClock {
  final StreamController<LessonClockTick> _controller =
      StreamController<LessonClockTick>.broadcast(sync: true);

  int startCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  int stopCalls = 0;
  int? initialTick;
  double? speed;
  List<TempoPoint> tempoMap = const [];
  bool running = false;

  @override
  Stream<LessonClockTick> ticks() => _controller.stream;

  @override
  Future<void> start({
    required int initialTick,
    required double speed,
    required List<TempoPoint> tempoMap,
  }) async {
    startCalls++;
    this.initialTick = initialTick;
    this.speed = speed;
    this.tempoMap = List.unmodifiable(tempoMap);
    running = true;
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    running = false;
  }

  @override
  Future<void> resume() async {
    resumeCalls++;
    running = true;
  }

  @override
  Future<void> seek(int tick) async => initialTick = tick;

  @override
  Future<void> setSpeed(double speed) async => this.speed = speed;

  @override
  Future<void> stop() async {
    stopCalls++;
    running = false;
  }

  void emit({required double positionTicks, required int timestampMs}) {
    _controller.add(
      LessonClockTick(
        positionTicks: positionTicks,
        monotonicTimestampMs: timestampMs,
      ),
    );
  }

  Future<void> close() => _controller.close();
}
