import 'package:equatable/equatable.dart';

import '../../../domain/learning/learning.dart';

final class LessonBlocState extends Equatable {
  const LessonBlocState({
    required this.isLoading,
    this.session,
    this.error,
    this.latestObservation,
  });

  const LessonBlocState.initial()
      : isLoading = false,
        session = null,
        error = null,
        latestObservation = null;

  static const Object _notProvided = Object();

  final bool isLoading;
  final LessonSessionState? session;
  final LessonException? error;
  final PerformanceObservation? latestObservation;

  LessonSessionStatus get status =>
      session?.status ?? LessonSessionStatus.idle;

  bool get hasLoadedLesson => session != null;

  bool get canStart => status == LessonSessionStatus.ready;

  LessonBlocState copyWith({
    bool? isLoading,
    Object? session = _notProvided,
    Object? error = _notProvided,
    Object? latestObservation = _notProvided,
  }) {
    return LessonBlocState(
      isLoading: isLoading ?? this.isLoading,
      session: identical(session, _notProvided)
          ? this.session
          : session as LessonSessionState?,
      error: identical(error, _notProvided)
          ? this.error
          : error as LessonException?,
      latestObservation: identical(latestObservation, _notProvided)
          ? this.latestObservation
          : latestObservation as PerformanceObservation?,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        session,
        error,
        latestObservation,
      ];
}
