import 'package:equatable/equatable.dart';

/// Compás musical expresado como numerador y denominador.
class TimeSignature extends Equatable {
  factory TimeSignature({required int numerator, required int denominator}) {
    if (numerator < minNumerator || numerator > maxNumerator) {
      throw RangeError.range(
        numerator,
        minNumerator,
        maxNumerator,
        'numerator',
      );
    }
    if (!supportedDenominators.contains(denominator)) {
      throw ArgumentError.value(
        denominator,
        'denominator',
        'Debe ser 2, 4, 8 o 16.',
      );
    }
    return TimeSignature._(numerator, denominator);
  }

  const TimeSignature._(this.numerator, this.denominator);

  static const int minNumerator = 1;
  static const int maxNumerator = 16;
  static const Set<int> supportedDenominators = {2, 4, 8, 16};

  final int numerator;
  final int denominator;

  Map<String, Object> toJson() => {
        'numerator': numerator,
        'denominator': denominator,
      };

  factory TimeSignature.fromJson(Map<String, dynamic> json) {
    return TimeSignature(
      numerator: json['numerator'] as int,
      denominator: json['denominator'] as int,
    );
  }

  @override
  List<Object> get props => [numerator, denominator];

  @override
  String toString() => '$numerator/$denominator';
}
