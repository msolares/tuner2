import 'audioplayers_metronome_audio_sink_stub.dart'
    if (dart.library.js_interop) 'audioplayers_metronome_audio_sink_web.dart'
    if (dart.library.io) 'audioplayers_metronome_audio_sink_io.dart'
    as platform;
import 'metronome_audio_sink.dart';

MetronomeAudioSink createMetronomeAudioSink() {
  return platform.AudioplayersMetronomeAudioSink();
}
