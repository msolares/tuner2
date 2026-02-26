import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/entities/guitar_tuning.dart';
import '../../domain/entities/song_tuning_query.dart';
import '../../domain/entities/song_tuning_result.dart';
import '../../domain/services/song_tuning_lookup_exception.dart';
import '../../domain/services/song_tuning_service.dart';
import 'openai_song_tuning_config.dart';

class OpenAiSongTuningService implements SongTuningService {
  OpenAiSongTuningService({
    required OpenAiSongTuningConfig config,
    http.Client? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client();

  static const String _systemPrompt = '''
Return JSON only.
Task: infer likely guitar tuning for a song.
Schema:
{"status":"ok|not_found|ambiguous","primary":{"id":"string","display_name":"string","strings":["note","note","note","note","note","note"],"description":"string?"},"alternatives":[{"id":"string","display_name":"string","strings":["note","note","note","note","note","note"],"description":"string?"}]}
Rules: prefer common studio tuning, include alternatives only if relevant, no extra keys, no prose.
''';

  final OpenAiSongTuningConfig _config;
  final http.Client _httpClient;

  @override
  Future<SongTuningResult> resolve(SongTuningQuery query) async {
    if (!query.isValid) {
      throw const SongTuningLookupException(
        SongTuningErrorCode.invalidQuery,
        message: 'song_name_required',
      );
    }
    if (!_config.hasApiKey) {
      throw const SongTuningLookupException(
        SongTuningErrorCode.unauthorized,
        message: 'openai_api_key_missing',
      );
    }

    http.Response response;
    try {
      response = await _httpClient
          .post(
            _config.endpoint,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${_config.apiKey}',
            },
            body: jsonEncode(_buildRequestPayload(query)),
          )
          .timeout(_config.timeout);
    } on TimeoutException {
      throw const SongTuningLookupException(
        SongTuningErrorCode.timeout,
        message: 'openai_timeout',
      );
    } on SocketException {
      throw const SongTuningLookupException(
        SongTuningErrorCode.providerUnavailable,
        message: 'network_unavailable',
      );
    } on http.ClientException {
      throw const SongTuningLookupException(
        SongTuningErrorCode.providerUnavailable,
        message: 'http_client_error',
      );
    }

    _throwIfErrorStatus(response.statusCode);
    final responseMap = _decodeJsonMap(response.body);
    return _mapResponseToDomain(responseMap, query);
  }

  Map<String, Object?> _buildRequestPayload(SongTuningQuery query) {
    final artist = query.normalizedArtistName;
    final userPrompt = artist == null
        ? 'song=${query.normalizedSongName}'
        : 'song=${query.normalizedSongName};artist=$artist';
    return <String, Object?>{
      'model': _config.model,
      'temperature': _config.temperature,
      'max_completion_tokens': _config.maxOutputTokens,
      'response_format': <String, String>{'type': 'json_object'},
      'messages': <Map<String, String>>[
        const <String, String>{'role': 'system', 'content': _systemPrompt},
        <String, String>{'role': 'user', 'content': userPrompt},
      ],
    };
  }

  SongTuningResult _mapResponseToDomain(Map<String, dynamic> response, SongTuningQuery query) {
    final content = _extractMessageContent(response);
    final output = _decodeJsonMap(content);
    final status = _requiredString(output, 'status');
    if (status == 'not_found') {
      throw const SongTuningLookupException(
        SongTuningErrorCode.notFound,
        message: 'song_not_found',
      );
    }
    if (status == 'ambiguous') {
      throw const SongTuningLookupException(
        SongTuningErrorCode.ambiguousSong,
        message: 'song_ambiguous',
      );
    }
    if (status != 'ok') {
      throw const SongTuningLookupException(
        SongTuningErrorCode.invalidResponse,
        message: 'invalid_status',
      );
    }

    final primary = _parseTuning(_requiredMap(output, 'primary'));
    final alternativesRaw = output['alternatives'];
    final alternatives = switch (alternativesRaw) {
      null => const <GuitarTuning>[],
      List<Object?>() => alternativesRaw
          .whereType<Map<String, dynamic>>()
          .map(_parseTuning)
          .toList(growable: false),
      _ => throw const SongTuningLookupException(
          SongTuningErrorCode.invalidResponse,
          message: 'alternatives_must_be_list',
        ),
    };
    return SongTuningResult(
      query: query,
      primaryTuning: primary,
      alternativeTunings: alternatives,
    );
  }

  GuitarTuning _parseTuning(Map<String, dynamic> raw) {
    final id = _requiredString(raw, 'id');
    final displayName = _requiredString(raw, 'display_name');
    final stringsRaw = raw['strings'];
    if (stringsRaw is! List || stringsRaw.length != 6 || stringsRaw.any((item) => item is! String)) {
      throw const SongTuningLookupException(
        SongTuningErrorCode.invalidResponse,
        message: 'invalid_tuning_strings',
      );
    }
    final descriptionRaw = raw['description'];
    final description = descriptionRaw is String && descriptionRaw.trim().isNotEmpty ? descriptionRaw : null;
    return GuitarTuning(
      id: id,
      displayName: displayName,
      stringsLowToHigh: List<String>.unmodifiable(stringsRaw.cast<String>()),
      description: description,
    );
  }

  String _extractMessageContent(Map<String, dynamic> response) {
    final choicesRaw = response['choices'];
    if (choicesRaw is! List || choicesRaw.isEmpty || choicesRaw.first is! Map<String, dynamic>) {
      throw const SongTuningLookupException(
        SongTuningErrorCode.invalidResponse,
        message: 'choices_missing',
      );
    }
    final firstChoice = choicesRaw.first as Map<String, dynamic>;
    final messageRaw = firstChoice['message'];
    if (messageRaw is! Map<String, dynamic>) {
      throw const SongTuningLookupException(
        SongTuningErrorCode.invalidResponse,
        message: 'message_missing',
      );
    }
    final contentRaw = messageRaw['content'];
    if (contentRaw is String && contentRaw.trim().isNotEmpty) {
      return contentRaw;
    }
    throw const SongTuningLookupException(
      SongTuningErrorCode.invalidResponse,
      message: 'content_missing',
    );
  }

  Map<String, dynamic> _decodeJsonMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const SongTuningLookupException(
        SongTuningErrorCode.invalidResponse,
        message: 'json_is_not_object',
      );
    } on FormatException {
      throw const SongTuningLookupException(
        SongTuningErrorCode.invalidResponse,
        message: 'invalid_json',
      );
    }
  }

  String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw SongTuningLookupException(
      SongTuningErrorCode.invalidResponse,
      message: '$key is missing',
    );
  }

  Map<String, dynamic> _requiredMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw SongTuningLookupException(
      SongTuningErrorCode.invalidResponse,
      message: '$key is missing',
    );
  }

  void _throwIfErrorStatus(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    if (statusCode == 401 || statusCode == 403) {
      throw const SongTuningLookupException(
        SongTuningErrorCode.unauthorized,
        message: 'unauthorized',
      );
    }
    if (statusCode == 408 || statusCode == 504) {
      throw const SongTuningLookupException(
        SongTuningErrorCode.timeout,
        message: 'request_timeout',
      );
    }
    if (statusCode == 429) {
      throw const SongTuningLookupException(
        SongTuningErrorCode.rateLimited,
        message: 'rate_limited',
      );
    }
    if (statusCode >= 500 && statusCode < 600) {
      throw const SongTuningLookupException(
        SongTuningErrorCode.providerUnavailable,
        message: 'provider_unavailable',
      );
    }
    throw SongTuningLookupException(
      SongTuningErrorCode.unknown,
      message: 'unexpected_status_$statusCode',
    );
  }
}

