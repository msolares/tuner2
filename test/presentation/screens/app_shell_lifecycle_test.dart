import 'package:afinador/presentation/screens/app_audio_lifecycle.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inactive transitorio conserva el audio activo', () {
    expect(
      shouldStopAudioForLifecycle(AppLifecycleState.inactive),
      isFalse,
    );
    expect(
      shouldStopAudioForLifecycle(AppLifecycleState.resumed),
      isFalse,
    );
  });

  test('detiene el audio cuando la app deja el primer plano', () {
    expect(shouldStopAudioForLifecycle(AppLifecycleState.paused), isTrue);
    expect(shouldStopAudioForLifecycle(AppLifecycleState.hidden), isTrue);
    expect(shouldStopAudioForLifecycle(AppLifecycleState.detached), isTrue);
  });
}
