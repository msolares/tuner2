import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/learning/learning.dart';
import 'lesson_event.dart';
import 'lesson_state.dart';

final class LessonBloc extends Bloc<LessonEvent, LessonBlocState> {
  LessonBloc({
    required LoadLessonUseCase loadLesson,
    required PrepareLessonSessionUseCase prepareSession,
    required PerformanceAnalyzer analyzer,
    required LessonClock clock,
    LessonEvaluationPolicy? evaluationPolicy,
    PerformanceAnalyzerSettings? analyzerSettings,
  })  : _loadLesson = loadLesson,
        _prepareSession = prepareSession,
        _analyzer = analyzer,
        _clock = clock,
        _evaluationPolicy =
            evaluationPolicy ?? LessonEvaluationPolicy.defaults,
        _analyzerSettings =
            analyzerSettings ?? PerformanceAnalyzerSettings(a4Hz: 440),
        super(const LessonBlocState.initial()) {
    on<LessonEvent>(_onEvent, transformer: _sequential());
  }

  final LoadLessonUseCase _loadLesson;
  final PrepareLessonSessionUseCase _prepareSession;
  final PerformanceAnalyzer _analyzer;
  final LessonClock _clock;
  final LessonEvaluationPolicy _evaluationPolicy;
  final PerformanceAnalyzerSettings _analyzerSettings;

  LessonSessionController? _controller;
  StreamSubscription<LessonClockTick>? _clockSubscription;
  StreamSubscription<PerformanceObservation>? _observationSubscription;

  Future<void> _onEvent(
    LessonEvent event,
    Emitter<LessonBlocState> emit,
  ) async {
    switch (event) {
      case LessonLoadRequested():
        await _onLoad(event, emit);
      case LessonStartRequested():
        await _onStart(emit);
      case LessonStopRequested():
        await _onStop(emit);
      case LessonPauseRequested():
        await _runControllerOperation((controller) => controller.pause(), emit);
      case LessonResumeRequested():
        await _runControllerOperation(
          (controller) => controller.resume(),
          emit,
        );
      case LessonSpeedChanged():
        await _runControllerOperation(
          (controller) => controller.setSpeed(event.speed),
          emit,
        );
      case LessonSectionSelected():
        await _onSectionSelected(event, emit);
      case LessonSectionRepeated():
        await _onRepeatSection(emit);
      case LessonClockTickReceived():
        await _runControllerOperation(
          (controller) => controller.processTick(event.tick),
          emit,
        );
      case LessonObservationReceived():
        await _runControllerOperation(
          (controller) => controller.processObservation(event.observation),
          emit,
          observation: event.observation,
        );
      case LessonClockStreamFailed():
        await _onStreamFailure(
          const LessonException(LessonErrorCode.lessonClockFailure),
          emit,
        );
      case LessonAnalyzerStreamFailed():
        await _onStreamFailure(
          const LessonException(
            LessonErrorCode.performanceAnalyzerUnavailable,
          ),
          emit,
        );
      case LessonBackgrounded():
        await _onStop(emit);
      case LessonForegrounded():
        _emitSession(
          emit,
          _controller?.state,
          latestObservation: state.latestObservation,
        );
    }
  }

  Future<void> _onLoad(
    LessonLoadRequested event,
    Emitter<LessonBlocState> emit,
  ) async {
    await _disposeCurrentSession();
    emit(const LessonBlocState(isLoading: true));
    try {
      final chart = await _loadLesson(
        event.lessonId,
        options: event.importOptions,
      );
      final session = _prepareSession(
        chart,
        sectionId: event.sectionId,
        speed: event.speed,
      );
      _controller = _buildController(session);
      emit(LessonBlocState(isLoading: false, session: session));
    } on LessonException catch (error) {
      emit(LessonBlocState(isLoading: false, error: error));
    } catch (_) {
      emit(
        const LessonBlocState(
          isLoading: false,
          error: LessonException(LessonErrorCode.sessionInvariantViolation),
        ),
      );
    }
  }

  Future<void> _onStart(Emitter<LessonBlocState> emit) async {
    final controller = _controller;
    if (controller == null) return;
    await _subscribeToInputs();
    await _runControllerOperation(
      (value) => value.start(),
      emit,
      clearObservation: true,
    );
  }

  Future<void> _onStop(Emitter<LessonBlocState> emit) async {
    final controller = _controller;
    await _cancelSubscriptions();
    if (controller == null) return;
    final session = await controller.stop();
    _emitSession(emit, session, latestObservation: null);
  }

  Future<void> _onSectionSelected(
    LessonSectionSelected event,
    Emitter<LessonBlocState> emit,
  ) async {
    final previous = _controller;
    if (previous == null) return;
    await _cancelSubscriptions();
    final stopped = await previous.stop();
    try {
      final session = _prepareSession(
        stopped.chart,
        sectionId: event.sectionId,
        speed: stopped.speed,
      );
      _controller = _buildController(session);
      _emitSession(emit, session, latestObservation: null);
    } on LessonException catch (error) {
      _controller = _buildController(stopped);
      emit(
        LessonBlocState(
          isLoading: false,
          session: stopped,
          error: error,
        ),
      );
    } catch (_) {
      _controller = _buildController(stopped);
      emit(
        LessonBlocState(
          isLoading: false,
          session: stopped,
          error: const LessonException(
            LessonErrorCode.sessionInvariantViolation,
          ),
        ),
      );
    }
  }

  Future<void> _onRepeatSection(Emitter<LessonBlocState> emit) async {
    final controller = _controller;
    if (controller == null) return;
    await _subscribeToInputs();
    await _runControllerOperation(
      (value) => value.repeatSection(),
      emit,
      clearObservation: true,
    );
  }

  Future<void> _onStreamFailure(
    LessonException error,
    Emitter<LessonBlocState> emit,
  ) async {
    final controller = _controller;
    await _cancelSubscriptions();
    if (controller == null) {
      emit(LessonBlocState(isLoading: false, error: error));
      return;
    }
    final session = await controller.stop(reason: LessonStopReason.failure);
    emit(
      LessonBlocState(
        isLoading: false,
        session: session,
        error: error,
        latestObservation: null,
      ),
    );
  }

  Future<void> _runControllerOperation(
    Future<LessonSessionState> Function(LessonSessionController controller)
        operation,
    Emitter<LessonBlocState> emit, {
    PerformanceObservation? observation,
    bool clearObservation = false,
  }) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final previousSession = state.session;
      final session = await operation(controller);
      final targetChanged = previousSession?.currentTarget?.id !=
          session.currentTarget?.id;
      final latestObservation = clearObservation || targetChanged
          ? null
          : observation != null &&
                  _canExposeObservation(previousSession, observation)
              ? observation
              : state.latestObservation;
      _emitSession(
        emit,
        session,
        latestObservation: latestObservation,
      );
      if (session.status == LessonSessionStatus.completed ||
          session.status == LessonSessionStatus.failure) {
        await _cancelSubscriptions();
      }
    } on LessonException catch (error) {
      emit(
        LessonBlocState(
          isLoading: false,
          session: controller.state,
          error: error,
          latestObservation: state.latestObservation,
        ),
      );
    } catch (_) {
      emit(
        LessonBlocState(
          isLoading: false,
          session: controller.state,
          error: const LessonException(
            LessonErrorCode.sessionInvariantViolation,
          ),
          latestObservation: state.latestObservation,
        ),
      );
    }
  }

  void _emitSession(
    Emitter<LessonBlocState> emit,
    LessonSessionState? session, {
    PerformanceObservation? latestObservation,
  }) {
    if (session == null) return;
    emit(
      LessonBlocState(
        isLoading: false,
        session: session,
        error: session.error,
        latestObservation: latestObservation,
      ),
    );
  }

  bool _canExposeObservation(
    LessonSessionState? session,
    PerformanceObservation observation,
  ) {
    if (session == null ||
        (session.status != LessonSessionStatus.waitingForTarget &&
            session.status != LessonSessionStatus.validating)) {
      return false;
    }
    final waitStartedTimestampMs = session.waitStartedTimestampMs;
    if (waitStartedTimestampMs == null ||
        observation.timestampMs <= waitStartedTimestampMs) {
      return false;
    }
    return switch ((session.currentTarget, observation)) {
      (LessonNoteEvent(), NotePerformanceObservation()) => true,
      (LessonChordEvent(), ChordPerformanceObservation()) => true,
      _ => false,
    };
  }

  LessonSessionController _buildController(LessonSessionState session) {
    return LessonSessionController(
      initialState: session,
      policy: _evaluationPolicy,
      analyzer: _analyzer,
      clock: _clock,
      analyzerSettings: _analyzerSettings,
    );
  }

  Future<void> _subscribeToInputs() async {
    await _cancelSubscriptions();
    _clockSubscription = _clock.ticks().listen(
      (tick) {
        if (!isClosed) add(LessonClockTickReceived(tick));
      },
      onError: (_) {
        if (!isClosed) add(const LessonClockStreamFailed());
      },
    );
    _observationSubscription = _analyzer.observations().listen(
      (observation) {
        if (!isClosed) add(LessonObservationReceived(observation));
      },
      onError: (_) {
        if (!isClosed) add(const LessonAnalyzerStreamFailed());
      },
    );
  }

  Future<void> _cancelSubscriptions() async {
    await _clockSubscription?.cancel();
    await _observationSubscription?.cancel();
    _clockSubscription = null;
    _observationSubscription = null;
  }

  Future<void> _disposeCurrentSession() async {
    final controller = _controller;
    await _cancelSubscriptions();
    _controller = null;
    if (controller != null) await controller.stop();
  }

  @override
  Future<void> close() async {
    await _disposeCurrentSession();
    return super.close();
  }
}

EventTransformer<E> _sequential<E>() {
  return (events, mapper) => events.asyncExpand(mapper);
}
