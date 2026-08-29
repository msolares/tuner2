import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Sesión Web Audio única para evitar los límites de contextos de Safari iOS.
///
/// El listener se ejecuta en fase de captura, antes de que Flutter encole el
/// evento BLoC asociado al botón. Así `resume()` conserva la activación de
/// usuario exigida por Safari.
class WebAudioSession {
  WebAudioSession._();

  static final WebAudioSession instance = WebAudioSession._();

  final web.AudioContext context = web.AudioContext();
  bool _activationListenerInstalled = false;
  JSFunction? _activationHandler;

  void installActivationListener() {
    if (_activationListenerInstalled) {
      return;
    }
    _activationListenerInstalled = true;
    _activationHandler = ((web.Event _) {
      unawaited(ensureRunning().catchError((Object _) {
        // Otro gesto volverá a intentar reanudar el contexto.
      }));
    }).toJS;
    final options = web.AddEventListenerOptions(capture: true, passive: true);
    web.window.addEventListener('pointerdown', _activationHandler, options);
    web.window.addEventListener('touchend', _activationHandler, options);
  }

  Future<void> ensureRunning() async {
    if (context.state == 'running') {
      return;
    }
    await context.resume().toDart;
  }
}
