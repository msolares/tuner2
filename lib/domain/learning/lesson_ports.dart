import 'lesson_chart.dart';
import 'lesson_content.dart';
import 'performance.dart';

abstract interface class LessonCatalog {
  Future<List<LessonSummary>> list();

  Future<LessonDocument> getById(LessonId id);
}

abstract interface class LessonChartDecoder {
  LessonChart decode(
    LessonDocument document,
    LessonImportOptions options,
  );
}

abstract interface class PerformanceAnalyzer {
  Future<void> start(PerformanceAnalyzerSettings settings);

  Future<void> setTarget(PerformanceTarget? target);

  Stream<PerformanceObservation> observations();

  Future<void> stop();
}

abstract interface class LessonClock {
  Future<void> start({required int initialTick, required double speed});

  Future<void> pause();

  Future<void> resume();

  Future<void> seek(int tick);

  Future<void> setSpeed(double speed);

  Stream<LessonClockTick> ticks();

  Future<void> stop();
}
