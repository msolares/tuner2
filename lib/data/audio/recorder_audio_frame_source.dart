import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'audio_capture_profile.dart';
import 'audio_frame_source.dart';
import 'audio_pcm_frame.dart';

class RecorderAudioFrameSource implements AudioFrameSource {
  RecorderAudioFrameSource({
    AudioRecorder? recorder,
    AudioCaptureProfile? profile,
  })  : _recorder = recorder ?? AudioRecorder(),
        _profile = profile ?? currentAudioCaptureProfile();

  final AudioRecorder _recorder;
  final AudioCaptureProfile _profile;
  final StreamController<AudioPcmFrame> _controller = StreamController<AudioPcmFrame>.broadcast();
  StreamSubscription<Uint8List>? _subscription;
  bool _started = false;

  @override
  Stream<AudioPcmFrame> frames() => _controller.stream;

  @override
  Future<void> start() async {
    if (_started) {
      return;
    }
    final stream = await _startWithFallback();
    _subscription = stream.listen(
      (bytes) {
        final pcm = _pcm16ToFloat32(bytes);
        _controller.add(
          AudioPcmFrame(
            pcmFloat32: pcm,
            sampleRateHz: _activeSampleRateHz,
            timestampMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        _controller.addError(error, stackTrace);
      },
      cancelOnError: false,
    );
    _started = true;
  }

  int _activeSampleRateHz = 0;

  Future<Stream<Uint8List>> _startWithFallback() async {
    final preferredRate = _profile.sampleRateHz;
    try {
      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: preferredRate,
          numChannels: _profile.channels,
        ),
      );
      _activeSampleRateHz = preferredRate;
      return stream;
    } catch (_) {
      if (currentAudioCapturePlatform() != AudioCapturePlatform.android || preferredRate == 44100) {
        rethrow;
      }
      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: _profile.channels,
        ),
      );
      _activeSampleRateHz = 44100;
      return stream;
    }
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (_started) {
      await _recorder.stop();
    }
    _started = false;
    _activeSampleRateHz = 0;
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
    await _controller.close();
  }

  Float32List _pcm16ToFloat32(Uint8List bytes) {
    final sampleCount = bytes.lengthInBytes ~/ 2;
    final floatData = Float32List(sampleCount);
    final data = ByteData.sublistView(bytes);
    for (var i = 0; i < sampleCount; i++) {
      final value = data.getInt16(i * 2, Endian.little);
      floatData[i] = (value / 32768.0).clamp(-1.0, 1.0);
    }
    return floatData;
  }
}
