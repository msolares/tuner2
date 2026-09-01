import 'package:afinador/data/learning/musicxml/musicxml_document_decoder.dart';
import 'package:afinador/data/learning/musicxml/musicxml_timeline_normalizer.dart';
import 'package:afinador/domain/learning/learning.dart';

final class MusicXmlLessonChartDecoder implements LessonChartDecoder {
  MusicXmlLessonChartDecoder({
    MusicXmlDocumentDecoder? documentDecoder,
    MusicXmlTimelineNormalizer? timelineNormalizer,
  })  : _documentDecoder = documentDecoder ?? MusicXmlDocumentDecoder(),
        _timelineNormalizer =
            timelineNormalizer ?? MusicXmlTimelineNormalizer();

  final MusicXmlDocumentDecoder _documentDecoder;
  final MusicXmlTimelineNormalizer _timelineNormalizer;

  @override
  LessonChart decode(
    LessonDocument document,
    LessonImportOptions options,
  ) {
    final score = _documentDecoder.decode(document, options);
    return _timelineNormalizer.normalize(score, document, options);
  }
}
