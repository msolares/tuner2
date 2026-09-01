import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(
          resolveAppLocale(
            Localizations.maybeLocaleOf(context),
            supportedLocales,
          ),
        );
  }

  bool get isSpanish => locale.languageCode.toLowerCase() == 'es';

  String get appTitle => isSpanish ? 'Afinador' : 'Guitar Tuner';
  String get tuner => isSpanish ? 'AFINADOR' : 'TUNER';
  String get metronome => isSpanish ? 'METRÓNOMO' : 'METRONOME';
  String get classes => isSpanish ? 'CLASES' : 'LESSONS';

  String get ready => isSpanish ? 'LISTO' : 'READY';
  String get playing => isSpanish ? 'REPRODUCIENDO' : 'PLAY';
  String get listening => isSpanish ? 'ESCUCHANDO' : 'LISTENING';
  String get inTune => isSpanish ? 'AFINADO' : 'IN TUNE';
  String get adjust => isSpanish ? 'AJUSTAR' : 'ADJUST';
  String get error => 'ERROR';

  String get readyHelper => isSpanish
      ? 'Activa la escucha para empezar a detectar tono en tiempo real.'
      : 'Start listening to detect pitch in real time.';
  String get listeningHelper => isSpanish
      ? 'Micrófono activo. Esperando una nota clara para fijar la lectura.'
      : 'Microphone active. Waiting for a clear note to lock the reading.';
  String get inTuneHelper => isSpanish
      ? 'Tono estable. Mantén el centro para conservar la afinación.'
      : 'Stable pitch. Hold the center to stay in tune.';
  String get adjustHelper => isSpanish
      ? 'Hay señal útil. Ajusta fino hasta centrar el medidor.'
      : 'Signal detected. Fine-tune until the meter is centered.';
  String get errorHelper => isSpanish
      ? 'Hay un bloqueo recuperable. Revisa los permisos o reinicia la escucha.'
      : 'A recoverable issue occurred. Check permissions or restart listening.';

  String confidence(String value) => '$value% CONF';
  String changeTuning(String active) => isSpanish
      ? 'Cambiar afinación. Actual: $active'
      : 'Change tuning. Current: $active';

  String presetName(String presetId, {String? fallback}) {
    return switch (presetId) {
      'chromatic' => isSpanish ? 'Cromático' : 'Chromatic',
      'guitar_standard' => isSpanish ? 'Guitarra (EADGBE)' : 'Guitar (EADGBE)',
      'ukulele_standard' => 'Ukulele (GCEA)',
      'bass_standard' => isSpanish ? 'Bajo (EADG)' : 'Bass (EADG)',
      'violin_standard' => isSpanish ? 'Violín (GDAE)' : 'Violin (GDAE)',
      _ => fallback ?? (isSpanish ? 'Cromático' : 'Chromatic'),
    };
  }

  String get stringMap => isSpanish ? 'MAPA DE CUERDAS' : 'STRING MAP';
  String get liveTuner => isSpanish ? 'AFINADOR EN VIVO' : 'LIVE TUNER';
  String get cents => 'CENTS';
  String get target => isSpanish ? 'OBJETIVO' : 'TARGET';
  String get tunerSetup => isSpanish ? 'AJUSTES DEL AFINADOR' : 'TUNER SETUP';
  String get calibration => isSpanish ? 'Calibración' : 'Calibration';
  String get noiseGate => isSpanish ? 'Puerta de ruido' : 'Noise gate';
  String get smoothing => isSpanish ? 'Suavizado' : 'Smoothing';
  String get resetA4 => isSpanish ? 'RESTABLECER A4' : 'RESET A4';

  String get songTuning => isSpanish ? 'AFINACIÓN POR CANCIÓN' : 'SONG TUNING';
  String get songTuningSubtitle => isSpanish
      ? 'Busca afinaciones alternativas sin salir del afinador.'
      : 'Find alternative tunings without leaving the tuner.';
  String get songName => isSpanish ? 'Nombre de la canción' : 'Song name';
  String get songHint => isSpanish ? 'Ej.: Everlong' : 'E.g. Everlong';
  String get queryTuning => isSpanish ? 'CONSULTAR AFINACIÓN' : 'FIND TUNING';
  String get recommendedTuning =>
      isSpanish ? 'Afinación recomendada' : 'Recommended tuning';
  String get alternatives => isSpanish ? 'Alternativas' : 'Alternatives';

  String get customTimeSignature =>
      isSpanish ? 'COMPÁS PERSONALIZADO' : 'CUSTOM TIME SIGNATURE';
  String get beats => isSpanish ? 'Tiempos' : 'Beats';
  String get noteValue => isSpanish ? 'Figura' : 'Note value';
  String get cancel => isSpanish ? 'CANCELAR' : 'CANCEL';
  String get apply => isSpanish ? 'APLICAR' : 'APPLY';
  String get playingPattern =>
      isSpanish ? 'Reproduciendo patrón' : 'Playing pattern';
  String get readyToPractice =>
      isSpanish ? 'Listo para practicar' : 'Ready to practice';
  String get tempo => 'TEMPO';
  String get decreaseTempo => isSpanish ? 'Reducir tempo' : 'Decrease tempo';
  String get increaseTempo => isSpanish ? 'Aumentar tempo' : 'Increase tempo';
  String bpmSemantics(int bpm) =>
      isSpanish ? '$bpm pulsaciones por minuto' : '$bpm beats per minute';
  String get tapTempo => 'TAP TEMPO';
  String get timeSignature => isSpanish ? 'COMPÁS' : 'TIME SIGNATURE';
  String get timeSignatureField => isSpanish ? 'Compás' : 'Time signature';
  String get customize => isSpanish ? 'PERSONALIZAR' : 'CUSTOMIZE';
  String get measurePattern =>
      isSpanish ? 'PATRÓN DEL COMPÁS' : 'MEASURE PATTERN';
  String beat(int value) => isSpanish ? 'TIEMPO $value' : 'BEAT $value';
  String get strongBeat => isSpanish ? 'TÓNICA' : 'ACCENT';
  String get silence => isSpanish ? 'SILENCIO' : 'MUTE';
  String get figureSubdivision =>
      isSpanish ? 'FIGURA / SUBDIVISIÓN' : 'NOTE / SUBDIVISION';

  String beatSemantics(
    int value,
    String accent,
    String figure,
  ) {
    return isSpanish
        ? 'Tiempo $value, $accent, $figure'
        : 'Beat $value, $accent, $figure';
  }

  String accentLabel(String accentName) {
    return switch (accentName) {
      'strong' => isSpanish ? 'tónica' : 'accented',
      'muted' => isSpanish ? 'silencio' : 'muted',
      _ => 'normal',
    };
  }

  String noteName(int denominator, {required bool plural}) {
    if (isSpanish) {
      return switch ((denominator, plural)) {
        (2, false) => 'Blanca',
        (2, true) => 'Blancas',
        (4, false) => 'Negra',
        (4, true) => 'Negras',
        (8, false) => 'Corchea',
        (8, true) => 'Corcheas',
        (16, false) => 'Semicorchea',
        (16, true) => 'Semicorcheas',
        (32, false) => 'Fusa',
        (32, true) => 'Fusas',
        (64, false) => 'Semifusa',
        (64, true) => 'Semifusas',
        _ => plural ? 'Subdivisiones' : 'Pulso',
      };
    }
    return switch ((denominator, plural)) {
      (2, false) => 'Half note',
      (2, true) => 'Half notes',
      (4, false) => 'Quarter note',
      (4, true) => 'Quarter notes',
      (8, false) => 'Eighth note',
      (8, true) => 'Eighth notes',
      (16, false) => 'Sixteenth note',
      (16, true) => 'Sixteenth notes',
      (32, false) => 'Thirty-second note',
      (32, true) => 'Thirty-second notes',
      (64, false) => 'Sixty-fourth note',
      (64, true) => 'Sixty-fourth notes',
      _ => plural ? 'Subdivisions' : 'Beat',
    };
  }

  String triplet(String noteName) =>
      isSpanish ? 'Tresillo de $noteName' : '$noteName triplet';

  String get lessonLoading =>
      isSpanish ? 'Preparando la lección' : 'Preparing lesson';
  String get startPractice =>
      isSpanish ? 'EMPEZAR PRÁCTICA' : 'START PRACTICE';
  String get stopPractice => isSpanish ? 'DETENER' : 'STOP';
  String get pausePractice => isSpanish ? 'PAUSAR' : 'PAUSE';
  String get resumePractice => isSpanish ? 'CONTINUAR' : 'RESUME';
  String get repeatSection =>
      isSpanish ? 'REPETIR SECCIÓN' : 'REPEAT SECTION';
  String get lessonSpeed => isSpanish ? 'VELOCIDAD' : 'SPEED';
  String get decreaseSpeed =>
      isSpanish ? 'Reducir velocidad' : 'Decrease speed';
  String get increaseSpeed =>
      isSpanish ? 'Aumentar velocidad' : 'Increase speed';
  String get microphone => isSpanish ? 'MICRÓFONO' : 'MICROPHONE';
  String get microphoneReady => isSpanish ? 'Preparado' : 'Ready';
  String get microphoneListening => isSpanish ? 'Escuchando' : 'Listening';
  String get lessonProgress => isSpanish ? 'PROGRESO' : 'PROGRESS';
  String get lessonMeasure => isSpanish ? 'COMPÁS' : 'MEASURE';
  String get lessonAttempt => isSpanish ? 'INTENTO' : 'ATTEMPT';
  String get lessonTarget => isSpanish ? 'OBJETIVO' : 'TARGET';
  String get targetNote => isSpanish ? 'NOTA' : 'NOTE';
  String get targetChord => isSpanish ? 'ACORDE' : 'CHORD';
  String get pitchEvidence =>
      isSpanish ? 'TONOS DETECTADOS' : 'DETECTED TONES';
  String get pendingEvidence => isSpanish ? 'Pendiente' : 'Pending';
  String get rotateToPractice => isSpanish
      ? 'Gira el dispositivo para comenzar la práctica'
      : 'Rotate your device to start practicing';
  String get closeLesson => isSpanish ? 'Cerrar lección' : 'Close lesson';
  String get moreControls => isSpanish ? 'Más controles' : 'More controls';
  String get retry => isSpanish ? 'REINTENTAR' : 'TRY AGAIN';

  String lessonProgressValue(int completed, int total) =>
      isSpanish ? '$completed de $total objetivos' : '$completed of $total goals';

  String lessonError(String code) {
    return switch (code) {
      'lessonNotFound' => isSpanish
          ? 'No se encontró la lección.'
          : 'The lesson could not be found.',
      'audioPermissionDenied' => isSpanish
          ? 'Activa el permiso del micrófono para continuar.'
          : 'Enable microphone permission to continue.',
      'performanceAnalyzerUnavailable' => isSpanish
          ? 'El reconocimiento de sonido no está disponible.'
          : 'Sound recognition is unavailable.',
      'lessonClockFailure' => isSpanish
          ? 'El reloj de la lección se ha detenido.'
          : 'The lesson clock has stopped.',
      _ => isSpanish
          ? 'No se pudo continuar con la lección.'
          : 'The lesson could not continue.',
    };
  }

  String get fretboardIdle =>
      isSpanish ? 'Selecciona una lección' : 'Select a lesson';
  String get fretboardReady =>
      isSpanish ? 'Listo para practicar' : 'Ready to practice';
  String get fretboardCountIn =>
      isSpanish ? 'Cuenta de entrada' : 'Count in';
  String get fretboardRunning =>
      isSpanish ? 'Sigue el mástil' : 'Follow the fretboard';
  String get fretboardWaitingNote =>
      isSpanish ? 'Esperando nota' : 'Waiting for note';
  String get fretboardWaitingChord =>
      isSpanish ? 'Esperando acorde' : 'Waiting for chord';
  String get fretboardValidating =>
      isSpanish ? 'Validando sonido' : 'Checking sound';
  String get fretboardSuccess =>
      isSpanish ? 'Objetivo correcto' : 'Target complete';
  String get fretboardReentry =>
      isSpanish ? 'Reentrada: 1' : 'Re-entry: 1';
  String get fretboardPaused => isSpanish ? 'Pausa' : 'Paused';
  String get fretboardCompleted =>
      isSpanish ? 'Lección completada' : 'Lesson completed';
  String get fretboardFailure => isSpanish
      ? 'No se pudo continuar. Inténtalo de nuevo'
      : 'Unable to continue. Try again';
  String get fretboardSixStrings => isSpanish
      ? 'Seis cuerdas, de 6 a 1'
      : 'Six strings, from 6 to 1';
  String get fretboardChord => isSpanish ? 'Acorde' : 'Chord';
  String get fretboardString => isSpanish ? 'Cuerda' : 'String';
  String get fretboardFret => isSpanish ? 'traste' : 'fret';
  String get fretboardNote => isSpanish ? 'nota' : 'note';
  String get fretboardCurrentTarget =>
      isSpanish ? 'objetivo actual' : 'current target';

  List<String> get pitchClassNames => isSpanish
      ? const <String>[
          'Do', 'Do sostenido', 'Re', 'Re sostenido', 'Mi', 'Fa',
          'Fa sostenido', 'Sol', 'Sol sostenido', 'La', 'La sostenido', 'Si',
        ]
      : const <String>[
          'C', 'C sharp', 'D', 'D sharp', 'E', 'F',
          'F sharp', 'G', 'G sharp', 'A', 'A sharp', 'B',
        ];

  String localizeError(String message) {
    final translations = isSpanish ? _spanishErrors : _englishErrors;
    return translations[message] ?? message;
  }
}

Locale resolveAppLocale(
  Locale? deviceLocale,
  Iterable<Locale> supportedLocales,
) {
  final languageCode = deviceLocale?.languageCode.toLowerCase();
  if (languageCode == 'es') {
    return supportedLocales.firstWhere(
      (locale) => locale.languageCode == 'es',
      orElse: () => const Locale('es'),
    );
  }
  return supportedLocales.firstWhere(
    (locale) => locale.languageCode == 'en',
    orElse: () => const Locale('en'),
  );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'es';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const _spanishErrors = <String, String>{
  'Permiso de microfono denegado.': 'Permiso de micrófono denegado.',
  'No se encontro dispositivo de entrada de audio.':
      'No se encontró un dispositivo de entrada de audio.',
  'No se pudo iniciar el motor de afinacion.':
      'No se pudo iniciar el motor de afinación.',
  'Se interrumpio el stream de audio/deteccion.':
      'Se interrumpió el flujo de audio o detección.',
  'Sesion invalida del motor nativo.': 'Sesión inválida del motor nativo.',
  'Frame de audio invalido.': 'Fotograma de audio inválido.',
  'Sample rate no soportado por el motor.':
      'Frecuencia de muestreo no soportada por el motor.',
  'Falla interna del motor nativo.': 'Fallo interno del motor nativo.',
  'Preset no soportado.': 'Preset no soportado.',
  'No se pudo recuperar configuracion guardada.':
      'No se pudo recuperar la configuración guardada.',
  'No se pudo guardar la configuracion.':
      'No se pudo guardar la configuración.',
  'Ocurrio un error inesperado.': 'Ocurrió un error inesperado.',
  'No se pudo recuperar la configuración guardada.':
      'No se pudo recuperar la configuración guardada.',
  'No se pudo iniciar la salida de audio.':
      'No se pudo iniciar la salida de audio.',
  'Mueve la tónica antes de silenciar este tiempo.':
      'Mueve la tónica antes de silenciar este tiempo.',
  'No se pudo aplicar la configuración.':
      'No se pudo aplicar la configuración.',
  'Ingresa una cancion para consultar la afinacion.':
      'Introduce una canción para consultar la afinación.',
  'No se pudo obtener la afinacion en este momento.':
      'No se pudo obtener la afinación en este momento.',
  'Ingresa una cancion valida para consultar.':
      'Introduce una canción válida para consultar.',
  'No encontramos una afinacion para esa cancion.':
      'No encontramos una afinación para esa canción.',
  'Hay varias coincidencias. Prueba con un titulo mas especifico.':
      'Hay varias coincidencias. Prueba con un título más específico.',
  'La consulta tardo demasiado. Reintenta.':
      'La consulta tardó demasiado. Inténtalo de nuevo.',
  'Demasiadas consultas seguidas. Espera unos segundos.':
      'Demasiadas consultas seguidas. Espera unos segundos.',
  'Servicio temporalmente no disponible. Reintenta.':
      'Servicio temporalmente no disponible. Inténtalo de nuevo.',
  'Respuesta no valida del servicio de afinacion.':
      'Respuesta no válida del servicio de afinación.',
  'OpenAI rechazo la API key o los permisos del proyecto (401/403).':
      'OpenAI rechazó la clave API o los permisos del proyecto (401/403).',
  'No hay API key configurada. Ejecuta con --dart-define=OPENAI_API_KEY=tu_api_key':
      'No hay una clave API configurada. Ejecuta con --dart-define=OPENAI_API_KEY=tu_api_key',
};

const _englishErrors = <String, String>{
  'Permiso de microfono denegado.': 'Microphone permission denied.',
  'No se encontro dispositivo de entrada de audio.':
      'No audio input device was found.',
  'No se pudo iniciar el motor de afinacion.':
      'The tuning engine could not be started.',
  'Se interrumpio el stream de audio/deteccion.':
      'The audio or detection stream was interrupted.',
  'Sesion invalida del motor nativo.': 'Invalid native engine session.',
  'Frame de audio invalido.': 'Invalid audio frame.',
  'Sample rate no soportado por el motor.':
      'The sample rate is not supported by the engine.',
  'Falla interna del motor nativo.': 'Internal native engine failure.',
  'Preset no soportado.': 'Unsupported preset.',
  'No se pudo recuperar configuracion guardada.':
      'Saved settings could not be restored.',
  'No se pudo guardar la configuracion.': 'Settings could not be saved.',
  'Ocurrio un error inesperado.': 'An unexpected error occurred.',
  'No se pudo recuperar la configuración guardada.':
      'Saved settings could not be restored.',
  'No se pudo iniciar la salida de audio.':
      'Audio output could not be started.',
  'Mueve la tónica antes de silenciar este tiempo.':
      'Move the accent before muting this beat.',
  'No se pudo aplicar la configuración.': 'The settings could not be applied.',
  'Ingresa una cancion para consultar la afinacion.':
      'Enter a song to look up its tuning.',
  'No se pudo obtener la afinacion en este momento.':
      'The tuning could not be retrieved right now.',
  'Ingresa una cancion valida para consultar.': 'Enter a valid song to search.',
  'No encontramos una afinacion para esa cancion.':
      'No tuning was found for that song.',
  'Hay varias coincidencias. Prueba con un titulo mas especifico.':
      'Several matches were found. Try a more specific title.',
  'La consulta tardo demasiado. Reintenta.':
      'The request took too long. Try again.',
  'Demasiadas consultas seguidas. Espera unos segundos.':
      'Too many requests. Wait a few seconds.',
  'Servicio temporalmente no disponible. Reintenta.':
      'The service is temporarily unavailable. Try again.',
  'Respuesta no valida del servicio de afinacion.':
      'The tuning service returned an invalid response.',
  'OpenAI rechazo la API key o los permisos del proyecto (401/403).':
      'OpenAI rejected the API key or project permissions (401/403).',
  'No hay API key configurada. Ejecuta con --dart-define=OPENAI_API_KEY=tu_api_key':
      'No API key is configured. Run with --dart-define=OPENAI_API_KEY=your_api_key',
};
