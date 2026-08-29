import 'package:flutter/widgets.dart';

bool shouldStopAudioForLifecycle(AppLifecycleState state) {
  return switch (state) {
    AppLifecycleState.paused ||
    AppLifecycleState.hidden ||
    AppLifecycleState.detached =>
      true,
    AppLifecycleState.resumed || AppLifecycleState.inactive => false,
  };
}
