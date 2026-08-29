import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'audio_capture_profile.dart';
import 'audio_frame_source.dart';
import 'audio_pcm_frame.dart';
import 'web_audio_session.dart';

/// Captura PCM Web sobre la misma sesión que usa la reproducción.
class WebAudioFrameSource implements AudioFrameSource {
  WebAudioFrameSource({
    WebAudioSession? session,
    AudioCaptureProfile? profile,
  })  : _session = session ?? WebAudioSession.instance,
        _profile = profile ?? kAudioCaptureProfiles[AudioCapturePlatform.web]!;

  final WebAudioSession _session;
  final AudioCaptureProfile _profile;
  final StreamController<AudioPcmFrame> _controller =
      StreamController<AudioPcmFrame>.broadcast();

  web.MediaStream? _mediaStream;
  web.MediaStreamAudioSourceNode? _sourceNode;
  web.ScriptProcessorNode? _processorNode;
  bool _started = false;

  @override
  Stream<AudioPcmFrame> frames() => _controller.stream;

  @override
  Future<void> start() async {
    if (_started) {
      return;
    }
    _session.installActivationListener();
    await _session.ensureRunning();

    final constraints = web.MediaStreamConstraints(
      audio: <String, Object>{
        'autoGainControl': false,
        'echoCancellation': false,
        'noiseSuppression': false,
        'channelCount': _profile.channels,
      }.jsify()!,
    );
    final mediaStream = await web.window.navigator.mediaDevices
        .getUserMedia(constraints)
        .toDart;
    try {
      final context = _session.context;
      final source = context.createMediaStreamSource(mediaStream);
      final processor = context.createScriptProcessor(
        _profile.bufferSizeFrames,
        _profile.channels,
        1,
      );
      processor.onaudioprocess = ((web.Event event) {
        final audioEvent = event as web.AudioProcessingEvent;
        final samples = Float32List.fromList(
          audioEvent.inputBuffer.getChannelData(0).toDart,
        );
        if (!_controller.isClosed) {
          _controller.add(
            AudioPcmFrame(
              pcmFloat32: samples,
              sampleRateHz: context.sampleRate.round(),
              timestampMs: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
      }).toJS;

      source.connect(processor);
      // El buffer de salida queda en silencio por defecto. Conectarlo
      // directamente evita que WebKit optimice una rama con gain exactamente
      // cero y deje de invocar `onaudioprocess`.
      processor.connect(context.destination);

      _mediaStream = mediaStream;
      _sourceNode = source;
      _processorNode = processor;
      _started = true;
    } catch (_) {
      _stopTracks(mediaStream);
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    _started = false;
    final processor = _processorNode;
    _processorNode = null;
    if (processor != null) {
      processor.onaudioprocess = null;
      processor.disconnect();
    }
    _sourceNode?.disconnect();
    _sourceNode = null;

    final stream = _mediaStream;
    _mediaStream = null;
    if (stream != null) {
      _stopTracks(stream);
    }
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  void _stopTracks(web.MediaStream stream) {
    for (final track in stream.getTracks().toDart) {
      track.stop();
    }
  }
}
