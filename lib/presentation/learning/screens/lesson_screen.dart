import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_localizations.dart';
import '../../../app/app_theme.dart';
import '../../../domain/learning/learning.dart';
import '../bloc/lesson_bloc.dart';
import '../bloc/lesson_event.dart';
import '../bloc/lesson_state.dart';
import '../fretboard/fretboard_render_mapper.dart';
import '../fretboard/learning_fretboard.dart';
import 'widgets/lesson_chord_diagram.dart';

final class LessonScreen extends StatefulWidget {
  const LessonScreen({
    required this.lessonId,
    this.importOptions,
    this.sectionId,
    super.key,
  });

  final LessonId lessonId;
  final LessonImportOptions? importOptions;
  final String? sectionId;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

final class _LessonScreenState extends State<LessonScreen>
    with WidgetsBindingObserver {
  bool _stopRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<LessonBloc>().add(
          LessonLoadRequested(
            lessonId: widget.lessonId,
            importOptions: widget.importOptions ?? LessonImportOptions(),
            sectionId: widget.sectionId,
          ),
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bloc = context.read<LessonBloc>();
    if (state == AppLifecycleState.resumed) {
      bloc.add(const LessonForegrounded());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      bloc.add(const LessonBackgrounded());
    }
  }

  bool _isActive(LessonSessionStatus status) {
    return status != LessonSessionStatus.idle &&
        status != LessonSessionStatus.ready &&
        status != LessonSessionStatus.completed &&
        status != LessonSessionStatus.failure;
  }

  Future<void> _stopBeforeExit() async {
    final bloc = context.read<LessonBloc>();
    if (_stopRequested || !_isActive(bloc.state.status)) return;
    _stopRequested = true;
    bloc.add(const LessonStopRequested());
    await bloc.stream.firstWhere((state) => !_isActive(state.status));
  }

  Future<void> _close() async {
    await _stopBeforeExit();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final bloc = context.read<LessonBloc>();
    if (!_stopRequested && _isActive(bloc.state.status) && !bloc.isClosed) {
      bloc.add(const LessonStopRequested());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LessonBloc>();
    return WillPopScope(
      onWillPop: () async {
        await _stopBeforeExit();
        return true;
      },
      child: BlocBuilder<LessonBloc, LessonBlocState>(
        builder: (context, state) {
          return LessonScreenView(
            state: state,
            onClose: _close,
            onStart: () => bloc.add(const LessonStartRequested()),
            onStop: () => bloc.add(const LessonStopRequested()),
            onPause: () => bloc.add(const LessonPauseRequested()),
            onResume: () => bloc.add(const LessonResumeRequested()),
            onRepeat: () => bloc.add(const LessonSectionRepeated()),
            onSpeedChanged: (speed) => bloc.add(LessonSpeedChanged(speed)),
            onRetry: () => bloc.add(
              LessonLoadRequested(
                lessonId: widget.lessonId,
                importOptions:
                    widget.importOptions ?? LessonImportOptions(),
                sectionId: widget.sectionId,
              ),
            ),
          );
        },
      ),
    );
  }
}

final class LessonScreenView extends StatelessWidget {
  const LessonScreenView({
    required this.state,
    required this.onClose,
    required this.onStart,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onRepeat,
    required this.onSpeedChanged,
    required this.onRetry,
    this.viewportSlice = const GetLessonViewportSliceUseCase(),
    this.renderMapper = const FretboardRenderMapper(),
    super.key,
  });

  final LessonBlocState state;
  final VoidCallback onClose;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRepeat;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onRetry;
  final GetLessonViewportSliceUseCase viewportSlice;
  final FretboardRenderMapper renderMapper;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxHeight > constraints.maxWidth) {
              return _RotateView(message: l10n.rotateToPractice);
            }
            if (state.isLoading) {
              return _LoadingView(label: l10n.lessonLoading);
            }
            final session = state.session;
            if (session == null) {
              return _ErrorView(
                message: l10n.lessonError(state.error?.code.name ?? ''),
                retryLabel: l10n.retry,
                closeLabel: l10n.closeLesson,
                onRetry: onRetry,
                onClose: onClose,
              );
            }
            return _LessonContent(
              session: session,
              latestObservation: state.latestObservation,
              error: state.error,
              l10n: l10n,
              compact: constraints.maxWidth < 900,
              narrow: constraints.maxWidth < 720,
              viewportSlice: viewportSlice,
              renderMapper: renderMapper,
              onClose: onClose,
              onStart: onStart,
              onStop: onStop,
              onPause: onPause,
              onResume: onResume,
              onRepeat: onRepeat,
              onSpeedChanged: onSpeedChanged,
            );
          },
        ),
      ),
    );
  }
}

final class _LessonContent extends StatelessWidget {
  const _LessonContent({
    required this.session,
    required this.latestObservation,
    required this.error,
    required this.l10n,
    required this.compact,
    required this.narrow,
    required this.viewportSlice,
    required this.renderMapper,
    required this.onClose,
    required this.onStart,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onRepeat,
    required this.onSpeedChanged,
  });

  final LessonSessionState session;
  final PerformanceObservation? latestObservation;
  final LessonException? error;
  final AppLocalizations l10n;
  final bool compact;
  final bool narrow;
  final GetLessonViewportSliceUseCase viewportSlice;
  final FretboardRenderMapper renderMapper;
  final VoidCallback onClose;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRepeat;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    final windowStart = math.max(
      session.section.startTick,
      session.positionTicks.floor() - lessonTicksPerQuarter,
    );
    final windowEnd = math.max(
      windowStart,
      math.min(
        session.section.endTick,
        session.positionTicks.ceil() + lessonTicksPerQuarter * 8,
      ),
    );
    final slice = viewportSlice(
      session,
      windowStartTick: windowStart,
      windowEndTick: windowEnd,
    );
    final renderModel = renderMapper(
      slice,
      strings: _renderStrings(l10n),
    );
    final chord = session.currentTarget is LessonChordEvent
        ? session.currentTarget! as LessonChordEvent
        : null;
    final chordObservation = latestObservation is ChordPerformanceObservation
        ? latestObservation! as ChordPerformanceObservation
        : null;

    return Column(
      children: [
        _LessonHeader(
          session: session,
          l10n: l10n,
          narrow: narrow,
          onClose: onClose,
        ),
        if (error != null)
          _InlineError(message: l10n.lessonError(error!.code.name)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(narrow ? 8 : 14, 6, narrow ? 8 : 14, 6),
            child: compact
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      LearningFretboard(
                        model: renderModel,
                        reduceMotion: MediaQuery.disableAnimationsOf(context),
                        rotateMessage: l10n.rotateToPractice,
                      ),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: SizedBox(
                          width: narrow ? 148 : 190,
                          child: _TargetPanel(session: session, l10n: l10n),
                        ),
                      ),
                      if (chord != null)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: SizedBox(
                            width: narrow ? 156 : 184,
                            child: LessonChordDiagram(
                              chord: chord,
                              observation: chordObservation,
                              pitchClassNames: l10n.pitchClassNames,
                              evidenceLabel: l10n.pitchEvidence,
                              pendingLabel: l10n.pendingEvidence,
                              compact: true,
                            ),
                          ),
                        ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 210,
                        child: _TargetPanel(session: session, l10n: l10n),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LearningFretboard(
                          model: renderModel,
                          reduceMotion: MediaQuery.disableAnimationsOf(context),
                          rotateMessage: l10n.rotateToPractice,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 220,
                        child: chord == null
                            ? const SizedBox.shrink()
                            : Align(
                                alignment: Alignment.center,
                                child: LessonChordDiagram(
                                  chord: chord,
                                  observation: chordObservation,
                                  pitchClassNames: l10n.pitchClassNames,
                                  evidenceLabel: l10n.pitchEvidence,
                                  pendingLabel: l10n.pendingEvidence,
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        ),
        _LessonControls(
          session: session,
          l10n: l10n,
          narrow: narrow,
          onStart: onStart,
          onStop: onStop,
          onPause: onPause,
          onResume: onResume,
          onRepeat: onRepeat,
          onSpeedChanged: onSpeedChanged,
        ),
      ],
    );
  }
}

final class _LessonHeader extends StatelessWidget {
  const _LessonHeader({
    required this.session,
    required this.l10n,
    required this.narrow,
    required this.onClose,
  });

  final LessonSessionState session;
  final AppLocalizations l10n;
  final bool narrow;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final requiredCount = session.chart.events
        .where((event) =>
            event.required &&
            event.startTick >= session.section.startTick &&
            event.startTick < session.section.endTick)
        .length;
    final completed = session.results.length.clamp(0, requiredCount);
    final meter = _meterAt(session.chart.meterMap, session.positionTicks);
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundElevated,
        border: Border(bottom: BorderSide(color: AppTheme.outlineMuted)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.closeLesson,
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.chart.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  session.section.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _HeaderMetric(
            label: narrow ? '' : l10n.lessonProgress,
            value: narrow
                ? '$completed/$requiredCount'
                : l10n.lessonProgressValue(completed, requiredCount),
          ),
          SizedBox(width: narrow ? 8 : 18),
          _HeaderMetric(
            label: l10n.lessonMeasure,
            value: '${meter.numerator}/${meter.denominator}',
          ),
          SizedBox(width: narrow ? 8 : 18),
          _HeaderMetric(
            label: l10n.lessonSpeed,
            value: '${(session.speed * 100).round()}%',
          ),
        ],
      ),
    );
  }
}

final class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, $value',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (label.isNotEmpty)
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

final class _TargetPanel extends StatelessWidget {
  const _TargetPanel({required this.session, required this.l10n});

  final LessonSessionState session;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final target = session.currentTarget;
    final label = switch (target) {
      LessonNoteEvent note => l10n.pitchClassNames[note.midi % 12],
      LessonChordEvent chord => chord.symbol,
      null => '—',
    };
    final kind = target is LessonChordEvent ? l10n.targetChord : l10n.targetNote;
    final status = session.status == LessonSessionStatus.waitingForTarget &&
            target is LessonChordEvent
        ? '${l10n.fretboardWaitingChord} ${target.symbol}'
        : _statusLabel(session.status, l10n);
    final color = _statusColor(session.status);
    return Semantics(
      container: true,
      liveRegion: true,
      label: '$status. ${l10n.lessonTarget}, $kind $label. '
          '${l10n.lessonAttempt} ${session.attempt}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_statusIcon(session.status), color: color, size: 18),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      status,
                      maxLines: 2,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('${l10n.lessonTarget} · $kind',
                  style: Theme.of(context).textTheme.labelSmall),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text('${l10n.lessonAttempt} ${session.attempt}'),
            ],
          ),
        ),
      ),
    );
  }
}

final class _LessonControls extends StatelessWidget {
  const _LessonControls({
    required this.session,
    required this.l10n,
    required this.narrow,
    required this.onStart,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onRepeat,
    required this.onSpeedChanged,
  });

  final LessonSessionState session;
  final AppLocalizations l10n;
  final bool narrow;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRepeat;
  final ValueChanged<double> onSpeedChanged;

  bool get _active => session.status != LessonSessionStatus.ready &&
      session.status != LessonSessionStatus.idle &&
      session.status != LessonSessionStatus.completed &&
      session.status != LessonSessionStatus.failure;

  @override
  Widget build(BuildContext context) {
    final isPaused = session.status == LessonSessionStatus.paused;
    final canStart = session.status == LessonSessionStatus.ready ||
        session.status == LessonSessionStatus.idle;
    final primaryLabel = canStart
        ? l10n.startPractice
        : session.status == LessonSessionStatus.completed ||
                session.status == LessonSessionStatus.failure
            ? l10n.repeatSection
            : isPaused
                ? l10n.resumePractice
                : l10n.pausePractice;
    final primaryIcon = canStart
        ? Icons.play_arrow
        : session.status == LessonSessionStatus.completed ||
                session.status == LessonSessionStatus.failure
            ? Icons.replay
            : isPaused
                ? Icons.play_arrow
                : Icons.pause;
    final primaryAction = canStart
        ? onStart
        : session.status == LessonSessionStatus.completed ||
                session.status == LessonSessionStatus.failure
            ? onRepeat
            : isPaused
                ? onResume
                : onPause;
    final stepDown =
        math.max(lessonMinSpeed, session.speed - lessonSpeedStep);
    final stepUp = math.min(lessonMaxSpeed, session.speed + lessonSpeedStep);

    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundElevated,
        border: Border(top: BorderSide(color: AppTheme.outlineMuted)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              key: const ValueKey('lesson-primary-control'),
              onPressed: primaryAction,
              icon: Icon(primaryIcon),
              label: Text(primaryLabel, overflow: TextOverflow.ellipsis),
            ),
          ),
          if (_active) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: l10n.stopPractice,
              onPressed: onStop,
              icon: const Icon(Icons.stop),
            ),
          ],
          if (!narrow) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onRepeat,
              icon: const Icon(Icons.replay),
              label: Text(l10n.repeatSection),
            ),
          ],
          const Spacer(),
          IconButton(
            tooltip: l10n.decreaseSpeed,
            onPressed: session.speed > lessonMinSpeed
                ? () => onSpeedChanged(stepDown)
                : null,
            icon: const Icon(Icons.remove),
          ),
          Semantics(
            label: '${l10n.lessonSpeed}, ${(session.speed * 100).round()}%',
            child: Text(
              '${(session.speed * 100).round()}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: l10n.increaseSpeed,
            onPressed: session.speed < lessonMaxSpeed
                ? () => onSpeedChanged(stepUp)
                : null,
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: '${l10n.microphone}, '
                '${_active ? l10n.microphoneListening : l10n.microphoneReady}',
            child: Row(
              children: [
                Icon(
                  _active ? Icons.mic : Icons.mic_none,
                  color: _active ? AppTheme.tuneGreen : AppTheme.textSecondary,
                ),
                if (!narrow) ...[
                  const SizedBox(width: 6),
                  Text(_active
                      ? l10n.microphoneListening
                      : l10n.microphoneReady),
                ],
              ],
            ),
          ),
          if (narrow)
            PopupMenuButton<void>(
              tooltip: l10n.moreControls,
              itemBuilder: (context) => [
                PopupMenuItem<void>(
                  onTap: onRepeat,
                  child: ListTile(
                    leading: const Icon(Icons.replay),
                    title: Text(l10n.repeatSection),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

final class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        color: AppTheme.danger.withOpacity(.16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

final class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(label),
          ],
        ),
      ),
    );
  }
}

final class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.retryLabel,
    required this.closeLabel,
    required this.onRetry,
    required this.onClose,
  });

  final String message;
  final String retryLabel;
  final String closeLabel;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(onPressed: onClose, child: Text(closeLabel)),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: onRetry, child: Text(retryLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _RotateView extends StatelessWidget {
  const _RotateView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        header: true,
        label: message,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.screen_rotation, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

MeterPoint _meterAt(List<MeterPoint> meters, double positionTicks) {
  var selected = meters.first;
  for (final meter in meters) {
    if (meter.tick > positionTicks) break;
    selected = meter;
  }
  return selected;
}

String _statusLabel(LessonSessionStatus status, AppLocalizations l10n) {
  return switch (status) {
    LessonSessionStatus.idle => l10n.fretboardIdle,
    LessonSessionStatus.ready => l10n.fretboardReady,
    LessonSessionStatus.countIn => l10n.fretboardCountIn,
    LessonSessionStatus.running => l10n.fretboardRunning,
    LessonSessionStatus.waitingForTarget => l10n.fretboardWaitingNote,
    LessonSessionStatus.validating => l10n.fretboardValidating,
    LessonSessionStatus.successFeedback => l10n.fretboardSuccess,
    LessonSessionStatus.reentry => l10n.fretboardReentry,
    LessonSessionStatus.paused => l10n.fretboardPaused,
    LessonSessionStatus.completed => l10n.fretboardCompleted,
    LessonSessionStatus.failure => l10n.fretboardFailure,
  };
}

Color _statusColor(LessonSessionStatus status) {
  return switch (status) {
    LessonSessionStatus.waitingForTarget || LessonSessionStatus.validating =>
      AppTheme.tuneAmber,
    LessonSessionStatus.successFeedback || LessonSessionStatus.completed =>
      AppTheme.tuneGreen,
    LessonSessionStatus.failure => AppTheme.danger,
    _ => AppTheme.tuneBlue,
  };
}

IconData _statusIcon(LessonSessionStatus status) {
  return switch (status) {
    LessonSessionStatus.waitingForTarget => Icons.hearing,
    LessonSessionStatus.validating => Icons.graphic_eq,
    LessonSessionStatus.successFeedback || LessonSessionStatus.completed =>
      Icons.check_circle,
    LessonSessionStatus.failure => Icons.error,
    LessonSessionStatus.paused => Icons.pause_circle,
    _ => Icons.music_note,
  };
}

FretboardRenderStrings _renderStrings(AppLocalizations l10n) {
  return FretboardRenderStrings(
    idle: l10n.fretboardIdle,
    ready: l10n.fretboardReady,
    countIn: l10n.fretboardCountIn,
    running: l10n.fretboardRunning,
    waitingForNote: l10n.fretboardWaitingNote,
    waitingForChord: l10n.fretboardWaitingChord,
    validating: l10n.fretboardValidating,
    success: l10n.fretboardSuccess,
    reentry: l10n.fretboardReentry,
    paused: l10n.fretboardPaused,
    completed: l10n.fretboardCompleted,
    failure: l10n.fretboardFailure,
    sixStrings: l10n.fretboardSixStrings,
    chord: l10n.fretboardChord,
    string: l10n.fretboardString,
    fret: l10n.fretboardFret,
    note: l10n.fretboardNote,
    currentTarget: l10n.fretboardCurrentTarget,
    pitchClassNames: l10n.pitchClassNames,
  );
}
