import 'package:afinador/data/audio/web_audio_capture_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa la sesión compartida en Safari iPhone', () {
    expect(
      chooseWebAudioCaptureBackend(
        userAgent:
            'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Version/18.0 Mobile/15E148 Safari/604.1',
        platform: 'iPhone',
        maxTouchPoints: 5,
      ),
      WebAudioCaptureBackend.sharedWebAudio,
    );
  });

  test('detecta iPad que solicita sitio de escritorio', () {
    expect(
      chooseWebAudioCaptureBackend(
        userAgent:
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15) AppleWebKit/605.1.15 Version/18.0 Safari/605.1.15',
        platform: 'MacIntel',
        maxTouchPoints: 5,
      ),
      WebAudioCaptureBackend.sharedWebAudio,
    );
  });

  test('conserva record_web en Chrome Android', () {
    expect(
      chooseWebAudioCaptureBackend(
        userAgent:
            'Mozilla/5.0 (Linux; Android 15) AppleWebKit/537.36 Chrome/138.0 Mobile Safari/537.36',
        platform: 'Linux armv8l',
        maxTouchPoints: 5,
      ),
      WebAudioCaptureBackend.recordPlugin,
    );
  });

  test('conserva record_web en Chrome de escritorio', () {
    expect(
      chooseWebAudioCaptureBackend(
        userAgent:
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/138.0 Safari/537.36',
        platform: 'Win32',
        maxTouchPoints: 0,
      ),
      WebAudioCaptureBackend.recordPlugin,
    );
  });
}
