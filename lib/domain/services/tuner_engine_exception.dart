class TunerEngineException implements Exception {
  const TunerEngineException(this.code);

  final String code;

  @override
  String toString() => 'TunerEngineException($code)';
}
