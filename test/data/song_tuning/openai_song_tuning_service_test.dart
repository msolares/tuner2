import 'dart:convert';

import 'package:afinador/data/song_tuning/openai_song_tuning_config.dart';
import 'package:afinador/data/song_tuning/openai_song_tuning_service.dart';
import 'package:afinador/domain/entities/song_tuning_query.dart';
import 'package:afinador/domain/services/song_tuning_lookup_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OpenAiSongTuningService', () {
    test('envia payload compacto y mapea respuesta exitosa', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['model'], 'gpt-4o-mini');
        expect(payload['temperature'], 0);
        expect(payload['max_completion_tokens'], 120);
        expect(payload['response_format'], <String, dynamic>{'type': 'json_object'});
        final messages = payload['messages'] as List<dynamic>;
        expect(messages.length, 2);
        expect((messages[1] as Map<String, dynamic>)['content'], contains('song=Hotel California'));
        expect((messages[1] as Map<String, dynamic>)['content'], contains('artist=Eagles'));

        final resultJson = jsonEncode(<String, dynamic>{
          'status': 'ok',
          'primary': <String, dynamic>{
            'id': 'standard_e',
            'display_name': 'Standard E',
            'strings': ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
          },
          'alternatives': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'half_step_down',
              'display_name': 'Eb Standard',
              'strings': ['Eb2', 'Ab2', 'Db3', 'Gb3', 'Bb3', 'Eb4'],
            },
          ],
        });
        final response = jsonEncode(<String, dynamic>{
          'choices': <Map<String, dynamic>>[
            <String, dynamic>{
              'message': <String, dynamic>{
                'content': resultJson,
              },
            },
          ],
        });
        return http.Response(response, 200);
      });

      final service = _buildService(client);
      final result = await service.resolve(
        const SongTuningQuery(
          songName: 'Hotel California',
          artistName: 'Eagles',
        ),
      );

      expect(result.primaryTuning.id, 'standard_e');
      expect(result.alternativeTunings.single.id, 'half_step_down');
    });

    test('mapea status not_found a error de dominio', () async {
      final client = MockClient((_) async {
        final body = jsonEncode(<String, dynamic>{
          'choices': <Map<String, dynamic>>[
            <String, dynamic>{
              'message': <String, dynamic>{
                'content': jsonEncode(<String, dynamic>{'status': 'not_found'}),
              },
            },
          ],
        });
        return http.Response(body, 200);
      });

      final service = _buildService(client);

      await expectLater(
        () => service.resolve(const SongTuningQuery(songName: 'Unknown Song')),
        throwsA(
          isA<SongTuningLookupException>()
              .having((e) => e.code, 'code', SongTuningErrorCode.notFound)
              .having((e) => e.recoverable, 'recoverable', isTrue),
        ),
      );
    });

    test('mapea 429 a rate_limited', () async {
      final client = MockClient((_) async => http.Response('{"error":"rate_limit"}', 429));
      final service = _buildService(client);

      await expectLater(
        () => service.resolve(const SongTuningQuery(songName: 'Everlong')),
        throwsA(
          isA<SongTuningLookupException>().having(
            (e) => e.code,
            'code',
            SongTuningErrorCode.rateLimited,
          ),
        ),
      );
    });

    test('falla con unauthorized cuando falta api key', () async {
      final client = MockClient((_) async => http.Response('should-not-call', 200));
      final service = OpenAiSongTuningService(
        config: OpenAiSongTuningConfig(apiKey: '   '),
        httpClient: client,
      );

      await expectLater(
        () => service.resolve(const SongTuningQuery(songName: 'Everlong')),
        throwsA(
          isA<SongTuningLookupException>().having(
            (e) => e.code,
            'code',
            SongTuningErrorCode.unauthorized,
          ),
        ),
      );
    });

    test('falla con invalid_response si schema no cumple', () async {
      final client = MockClient((_) async {
        final body = jsonEncode(<String, dynamic>{
          'choices': <Map<String, dynamic>>[
            <String, dynamic>{
              'message': <String, dynamic>{
                'content': jsonEncode(<String, dynamic>{
                  'status': 'ok',
                  'primary': <String, dynamic>{
                    'id': 'drop_d',
                    'display_name': 'Drop D',
                    'strings': ['D2'],
                  },
                }),
              },
            },
          ],
        });
        return http.Response(body, 200);
      });
      final service = _buildService(client);

      await expectLater(
        () => service.resolve(const SongTuningQuery(songName: 'Everlong')),
        throwsA(
          isA<SongTuningLookupException>().having(
            (e) => e.code,
            'code',
            SongTuningErrorCode.invalidResponse,
          ),
        ),
      );
    });
  });
}

OpenAiSongTuningService _buildService(http.Client client) {
  return OpenAiSongTuningService(
    config: OpenAiSongTuningConfig(apiKey: 'test-api-key'),
    httpClient: client,
  );
}
