/// Afinacion de guitarra representada de cuerda grave a aguda.
class GuitarTuning {
  static const List<String> standardStringsLowToHigh = [
    'E2',
    'A2',
    'D3',
    'G3',
    'B3',
    'E4',
  ];

  static const GuitarTuning standard = GuitarTuning(
    id: 'standard_e',
    displayName: 'Standard E',
    stringsLowToHigh: standardStringsLowToHigh,
  );

  const GuitarTuning({
    required this.id,
    required this.displayName,
    required this.stringsLowToHigh,
    this.description,
  });

  /// Identificador estable para persistencia o mapeos de UI.
  final String id;

  /// Etiqueta legible para mostrar al usuario.
  final String displayName;

  /// Notas de afinacion de cuerda grave a aguda.
  final List<String> stringsLowToHigh;

  /// Nota opcional para contexto (studio/live/capo, etc).
  final String? description;

  bool get isSixString => stringsLowToHigh.length == 6;

  GuitarTuning copyWith({
    String? id,
    String? displayName,
    List<String>? stringsLowToHigh,
    String? description,
  }) {
    return GuitarTuning(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      stringsLowToHigh: stringsLowToHigh ?? this.stringsLowToHigh,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'GuitarTuning(id: $id, displayName: $displayName, stringsLowToHigh: $stringsLowToHigh, description: $description)';
  }
}

