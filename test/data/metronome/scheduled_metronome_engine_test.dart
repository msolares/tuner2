import 'package:afinador/data/metronome/metronome_audio_sink.dart';
import 'package:afinador/data/metronome/scheduled_metronome_engine.dart';
import 'package:afinador/domain/entities/metronome_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:async';
import 'dart:io';

void main() {
  test('emits ordered ticks and distinguishes strong clicks', () async {
    final sink = _FakeAudioSink();
    final engine = ScheduledMetronomeEngine(audioSink: sink);
    final ticks = <int>[];
    final subscription = engine.ticks().listen(
          (tick) => ticks.add(tick.beatIndex),
        );
    addTearDown(subscription.cancel);
    addTearDown(engine.stop);

    await engine.start(MetronomeSettings.defaults.copyWith(bpm: 300));
    await Future<void>.delayed(const Duration(milliseconds: 430));
    await engine.stop();

    expect(ticks.take(3), [0, 1, 2]);
    expect(sink.strongClicks, 1);
    expect(sink.normalClicks, greaterThanOrEqualTo(2));
    expect(sink.disposeCount, greaterThanOrEqualTo(1));
  });

  test('keeps sixteenth-note playback stable at the maximum tempo', () async {
    final sink = _FakeAudioSink(playDelay: const Duration(milliseconds: 5));
    final engine = ScheduledMetronomeEngine(audioSink: sink);
    final subscription = engine.ticks().listen((_) {});
    addTearDown(subscription.cancel);
    addTearDown(engine.stop);

    await engine.start(_fastSettings());
    await Future<void>.delayed(const Duration(seconds: 2));
    await engine.stop();

    expect(sink.totalClicks, inInclusiveRange(35, 43));
    expect(sink.maxConcurrentPlays, lessThanOrEqualTo(2));
  });

  test('bounds stalled audio calls and reports a recoverable stream error',
      () async {
    final sink = _StalledAudioSink();
    final engine = ScheduledMetronomeEngine(
      audioSink: sink,
      maxPendingAudioOperations: 3,
    );
    final error = Completer<Object>();
    final subscription = engine.ticks().listen(
      (_) {},
      onError: (Object value) {
        if (!error.isCompleted) {
          error.complete(value);
        }
      },
    );
    addTearDown(subscription.cancel);
    addTearDown(engine.stop);

    await engine.start(_fastSettings());
    expect(
      await error.future.timeout(const Duration(seconds: 1)),
      isA<StateError>(),
    );
    expect(sink.playCount, 3);

    sink.releaseAll();
    await engine.stop();
  });

  test('does not replay a burst of expired clicks after an isolate stall',
      () async {
    final sink = _FakeAudioSink();
    final engine = ScheduledMetronomeEngine(audioSink: sink);
    final subscription = engine.ticks().listen((_) {});
    addTearDown(subscription.cancel);
    addTearDown(engine.stop);

    await engine.start(_fastSettings());
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final beforeStall = sink.totalClicks;

    sleep(const Duration(milliseconds: 400));
    await Future<void>.delayed(const Duration(milliseconds: 25));
    final recoveredClicks = sink.totalClicks - beforeStall;

    await engine.stop();
    expect(recoveredClicks, lessThanOrEqualTo(2));
  });
}

MetronomeSettings _fastSettings() {
  return MetronomeSettings.defaults.copyWith(
    bpm: 300,
    beats: const [
      BeatConfig(
        accent: BeatAccent.strong,
        subdivision: BeatSubdivision.quadruplet,
      ),
      BeatConfig.normal(subdivision: BeatSubdivision.quadruplet),
      BeatConfig.normal(subdivision: BeatSubdivision.quadruplet),
      BeatConfig.normal(subdivision: BeatSubdivision.quadruplet),
    ],
  );
}

class _FakeAudioSink implements MetronomeAudioSink {
  _FakeAudioSink({this.playDelay = Duration.zero});

  final Duration playDelay;
  int strongClicks = 0;
  int normalClicks = 0;
  int disposeCount = 0;
  int concurrentPlays = 0;
  int maxConcurrentPlays = 0;

  int get totalClicks => strongClicks + normalClicks;

  @override
  Future<void> prepare() async {}

  @override
  Future<void> play({required bool strong}) async {
    concurrentPlays++;
    if (concurrentPlays > maxConcurrentPlays) {
      maxConcurrentPlays = concurrentPlays;
    }
    try {
      if (playDelay > Duration.zero) {
        await Future<void>.delayed(playDelay);
      }
      if (strong) {
        strongClicks++;
      } else {
        normalClicks++;
      }
    } finally {
      concurrentPlays--;
    }
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}

class _StalledAudioSink implements MetronomeAudioSink {
  final List<Completer<void>> _calls = <Completer<void>>[];

  int get playCount => _calls.length;

  @override
  Future<void> prepare() async {}

  @override
  Future<void> play({required bool strong}) {
    final call = Completer<void>();
    _calls.add(call);
    return call.future;
  }

  void releaseAll() {
    for (final call in _calls) {
      if (!call.isCompleted) {
        call.complete();
      }
    }
  }

  @override
  Future<void> dispose() async {
    releaseAll();
  }
}
