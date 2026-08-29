import '../entities/time_signature.dart';

abstract class TimeSignatureCatalog {
  List<TimeSignature> get presets;
}

class DefaultTimeSignatureCatalog implements TimeSignatureCatalog {
  const DefaultTimeSignatureCatalog();

  @override
  List<TimeSignature> get presets => List.unmodifiable([
        TimeSignature(numerator: 2, denominator: 4),
        TimeSignature(numerator: 3, denominator: 4),
        TimeSignature(numerator: 4, denominator: 4),
        TimeSignature(numerator: 5, denominator: 4),
        TimeSignature(numerator: 7, denominator: 4),
        TimeSignature(numerator: 5, denominator: 8),
        TimeSignature(numerator: 6, denominator: 8),
        TimeSignature(numerator: 7, denominator: 8),
        TimeSignature(numerator: 9, denominator: 8),
        TimeSignature(numerator: 12, denominator: 8),
        TimeSignature(numerator: 2, denominator: 2),
        TimeSignature(numerator: 3, denominator: 8),
        TimeSignature(numerator: 4, denominator: 8),
        TimeSignature(numerator: 6, denominator: 4),
      ]);
}
