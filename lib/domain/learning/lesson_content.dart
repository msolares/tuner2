import 'package:equatable/equatable.dart';

import 'lesson_chart.dart';

void _requireText(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'No puede estar vacio.');
  }
}

enum LessonKind { exercise, song }

final class LessonSummary extends Equatable {
  factory LessonSummary({
    required LessonId id,
    required String title,
    required String subtitle,
    required int sequenceIndex,
    required int estimatedMinutes,
    required LessonKind kind,
  }) {
    _requireText(title, 'title');
    _requireText(subtitle, 'subtitle');
    if (sequenceIndex < 0) {
      throw RangeError.value(sequenceIndex, 'sequenceIndex');
    }
    if (estimatedMinutes <= 0) {
      throw RangeError.value(estimatedMinutes, 'estimatedMinutes');
    }
    return LessonSummary._(
      id,
      title,
      subtitle,
      sequenceIndex,
      estimatedMinutes,
      kind,
    );
  }

  const LessonSummary._(
    this.id,
    this.title,
    this.subtitle,
    this.sequenceIndex,
    this.estimatedMinutes,
    this.kind,
  );

  final LessonId id;
  final String title;
  final String subtitle;
  final int sequenceIndex;
  final int estimatedMinutes;
  final LessonKind kind;

  LessonSummary copyWith({
    LessonId? id,
    String? title,
    String? subtitle,
    int? sequenceIndex,
    int? estimatedMinutes,
    LessonKind? kind,
  }) {
    return LessonSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      sequenceIndex: sequenceIndex ?? this.sequenceIndex,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      kind: kind ?? this.kind,
    );
  }

  @override
  List<Object> get props => [
        id,
        title,
        subtitle,
        sequenceIndex,
        estimatedMinutes,
        kind,
      ];
}

final class LessonDocument extends Equatable {
  factory LessonDocument({
    required LessonId id,
    required String sourceName,
    required List<int> bytes,
  }) {
    _requireText(sourceName, 'sourceName');
    if (bytes.isEmpty || bytes.any((value) => value < 0 || value > 255)) {
      throw ArgumentError.value(bytes, 'bytes', 'Debe contener bytes validos.');
    }
    return LessonDocument._(id, sourceName, List.unmodifiable(bytes));
  }

  const LessonDocument._(this.id, this.sourceName, this.bytes);

  final LessonId id;
  final String sourceName;
  final List<int> bytes;

  LessonDocument copyWith({
    LessonId? id,
    String? sourceName,
    List<int>? bytes,
  }) {
    return LessonDocument(
      id: id ?? this.id,
      sourceName: sourceName ?? this.sourceName,
      bytes: bytes ?? this.bytes,
    );
  }

  @override
  List<Object> get props => [id, sourceName, bytes];
}

final class LessonImportOptions extends Equatable {
  factory LessonImportOptions({String? partId, String? sectionTitle}) {
    if (partId != null) {
      _requireText(partId, 'partId');
    }
    if (sectionTitle != null) {
      _requireText(sectionTitle, 'sectionTitle');
    }
    return LessonImportOptions._(partId, sectionTitle);
  }

  const LessonImportOptions._(this.partId, this.sectionTitle);

  static const Object _notProvided = Object();

  final String? partId;
  final String? sectionTitle;

  LessonImportOptions copyWith({
    Object? partId = _notProvided,
    Object? sectionTitle = _notProvided,
  }) {
    return LessonImportOptions(
      partId: identical(partId, _notProvided) ? this.partId : partId as String?,
      sectionTitle: identical(sectionTitle, _notProvided)
          ? this.sectionTitle
          : sectionTitle as String?,
    );
  }

  @override
  List<Object?> get props => [partId, sectionTitle];
}
