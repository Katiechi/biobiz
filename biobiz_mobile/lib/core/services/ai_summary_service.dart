import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// AI-powered recording summary using:
/// - Groq Whisper API for fast, accurate transcription
/// - OpenRouter (Gemini) for summarization and extraction
class AiSummaryService {
  // Groq API for Whisper transcription
  static const _groqApiKey =
      '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';
  static const _groqTranscriptionUrl =
      'https://api.groq.com/openai/v1/audio/transcriptions';

  // Groq API for AI summarization (using Llama model)
  static const _groqChatUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  final _dio = Dio();

  /// Summarize a recording: transcribe with Groq Whisper, then summarize with AI.
  Future<Map<String, dynamic>> summarizeRecording(String audioUrl) async {
    // Step 1: Download the audio file
    debugPrint('AI: Downloading audio from $audioUrl');
    final audioResponse = await _dio.get(
      audioUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    final Uint8List audioBytes =
        Uint8List.fromList(audioResponse.data as List<int>);
    debugPrint('AI: Audio downloaded, ${audioBytes.length} bytes');

    // Step 2: Transcribe with Groq Whisper
    debugPrint('AI: Transcribing with Groq Whisper...');
    final transcript = await _transcribeWithWhisper(audioBytes);
    debugPrint(
        'AI: Transcript: ${transcript.substring(0, transcript.length.clamp(0, 200))}');

    if (transcript.trim().isEmpty) {
      throw Exception(
          'Could not transcribe audio. Try a longer or clearer recording.');
    }

    // Step 3: Summarize transcript with OpenRouter
    debugPrint('AI: Summarizing with AI...');
    final summary = await _summarizeTranscript(transcript);

    return {
      'transcript': transcript,
      'summary': summary['summary'] ?? '',
      'people_mentioned': summary['people_mentioned'] ?? [],
      'key_insights': summary['key_insights'] ?? [],
      'action_items': summary['action_items'] ?? [],
    };
  }

  /// Transcribe audio using Groq's Whisper API (whisper-large-v3-turbo)
  Future<String> _transcribeWithWhisper(Uint8List audioBytes) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        audioBytes,
        filename: 'recording.m4a',
      ),
      'model': 'whisper-large-v3-turbo',
      'response_format': 'verbose_json',
      'language': 'en',
    });

    final response = await _dio.post(
      _groqTranscriptionUrl,
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
        },
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 2),
        validateStatus: (status) => true,
      ),
    );

    debugPrint('AI: Groq Whisper response: ${response.statusCode}');

    if (response.statusCode != 200) {
      debugPrint('AI: Groq error: ${response.data}');
      // Fallback: try whisper-large-v3 if turbo fails
      return _transcribeWithWhisperFallback(audioBytes);
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['text'] as String? ?? '';
    } else if (data is String) {
      try {
        final parsed = jsonDecode(data) as Map<String, dynamic>;
        return parsed['text'] as String? ?? '';
      } catch (_) {
        return data;
      }
    }
    return '';
  }

  /// Fallback to whisper-large-v3 if turbo is unavailable
  Future<String> _transcribeWithWhisperFallback(Uint8List audioBytes) async {
    debugPrint('AI: Trying whisper-large-v3 fallback...');
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        audioBytes,
        filename: 'recording.m4a',
      ),
      'model': 'whisper-large-v3',
      'response_format': 'verbose_json',
      'language': 'en',
    });

    final response = await _dio.post(
      _groqTranscriptionUrl,
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
        },
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 2),
        validateStatus: (status) => true,
      ),
    );

    if (response.statusCode != 200) {
      debugPrint('AI: Groq fallback error: ${response.data}');
      throw Exception(
          'Transcription failed (${response.statusCode}). Try again later.');
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['text'] as String? ?? '';
    } else if (data is String) {
      try {
        final parsed = jsonDecode(data) as Map<String, dynamic>;
        return parsed['text'] as String? ?? '';
      } catch (_) {
        return data;
      }
    }
    return '';
  }

  /// Summarize a transcript using Groq
  Future<Map<String, dynamic>> _summarizeTranscript(String transcript) async {
    final response = await _dio.post(
      _groqChatUrl,
      options: Options(
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        receiveTimeout: const Duration(minutes: 2),
        sendTimeout: const Duration(minutes: 1),
        validateStatus: (status) => true,
      ),
      data: {
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'user',
            'content':
                '''You are a professional meeting notes assistant. Analyze this transcript and extract structured information.

TRANSCRIPT:
$transcript

Respond with JSON:
{
  "summary": "2-4 sentence summary of the discussion",
  "people_mentioned": ["names of people mentioned"],
  "key_insights": ["important points or takeaways"],
  "action_items": ["tasks or follow-ups mentioned"]
}

RULES:
- The summary should capture the main topic and key points.
- Only include people_mentioned if actual names are spoken.
- key_insights should be concrete takeaways, not vague observations.
- action_items should be specific tasks mentioned. If none, return empty array.
- If the transcript is very short or unclear, still do your best.''',
          },
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.1,
        'max_tokens': 4096,
      },
    );

    debugPrint('AI: OpenRouter summary response: ${response.statusCode}');

    if (response.statusCode != 200) {
      debugPrint('AI: Summary error: ${response.data}');
      // Return just the transcript without summary if summarization fails
      return {
        'summary': 'Summary generation failed. See transcript above.',
        'people_mentioned': <String>[],
        'key_insights': <String>[],
        'action_items': <String>[],
      };
    }

    final data = response.data as Map<String, dynamic>;

    if (data.containsKey('error')) {
      final error = data['error'];
      final msg = error is Map ? error['message'] : error.toString();
      debugPrint('AI: Summary API error: $msg');
      return {
        'summary': 'Summary generation failed: $msg',
        'people_mentioned': <String>[],
        'key_insights': <String>[],
        'action_items': <String>[],
      };
    }

    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      return {
        'summary': 'No summary generated.',
        'people_mentioned': <String>[],
        'key_insights': <String>[],
        'action_items': <String>[],
      };
    }

    var text = choices[0]['message']['content'] as String;

    // Clean up markdown fences if present
    text = text.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```json?\s*\n?'), '');
      text = text.replaceFirst(RegExp(r'\n?```\s*$'), '');
      text = text.trim();
    }

    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('AI: JSON parse error: $e');
      return {
        'summary': text,
        'people_mentioned': <String>[],
        'key_insights': <String>[],
        'action_items': <String>[],
      };
    }
  }
}
