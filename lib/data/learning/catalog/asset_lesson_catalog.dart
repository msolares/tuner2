import 'package:afinador/domain/learning/learning.dart';
import 'package:flutter/services.dart';

final class AssetLessonCatalog implements LessonCatalog {
  AssetLessonCatalog(this._bundle);

  static const String pentatonicLessonId =
      'pentatonic-a-minor-position-1';

  static const Map<String, _AssetLessonEntry> _entries = {
    pentatonicLessonId: _AssetLessonEntry(
      assetPath:
          'docs/partituras/pentatonica-menor-la-posicion-1.musicxml',
      sourceName: 'pentatonica-menor-la-posicion-1.musicxml',
      title: 'Pentatonica menor de La',
      subtitle: 'Primera posicion · nota a nota',
      sequenceIndex: 0,
      estimatedMinutes: 3,
      kind: LessonKind.exercise,
    ),
  };

  final AssetBundle _bundle;

  @override
  Future<List<LessonSummary>> list() async => List.unmodifiable(
        _entries.entries.map(
          (entry) => entry.value.toSummary(LessonId(entry.key)),
        ),
      );

  @override
  Future<LessonDocument> getById(LessonId id) async {
    final entry = _entries[id.value];
    if (entry == null) {
      throw const LessonException(LessonErrorCode.lessonNotFound);
    }
    try {
      final data = await _bundle.load(entry.assetPath);
      return LessonDocument(
        id: id,
        sourceName: entry.sourceName,
        bytes: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (_) {
      throw const LessonException(
        LessonErrorCode.lessonCatalogUnavailable,
        context: 'No se pudo cargar la leccion local.',
      );
    }
  }
}

final class _AssetLessonEntry {
  const _AssetLessonEntry({
    required this.assetPath,
    required this.sourceName,
    required this.title,
    required this.subtitle,
    required this.sequenceIndex,
    required this.estimatedMinutes,
    required this.kind,
  });

  final String assetPath;
  final String sourceName;
  final String title;
  final String subtitle;
  final int sequenceIndex;
  final int estimatedMinutes;
  final LessonKind kind;

  LessonSummary toSummary(LessonId id) => LessonSummary(
        id: id,
        title: title,
        subtitle: subtitle,
        sequenceIndex: sequenceIndex,
        estimatedMinutes: estimatedMinutes,
        kind: kind,
      );
}
