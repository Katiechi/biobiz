class RecordingModel {
  final String id;
  final String userId;
  final String audioUrl;
  final int? durationSeconds;
  final String status;
  final DateTime createdAt;
  final RecordingSummary? summary;

  const RecordingModel({
    required this.id,
    required this.userId,
    required this.audioUrl,
    this.durationSeconds,
    this.status = 'recording',
    required this.createdAt,
    this.summary,
  });

  String get formattedDuration {
    if (durationSeconds == null) return '0:00';
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  factory RecordingModel.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? summaryJson}) {
    return RecordingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      audioUrl: json['audio_url'] as String,
      durationSeconds: json['duration_seconds'] as int?,
      status: json['status'] as String? ?? 'recording',
      createdAt: DateTime.parse(json['created_at'] as String),
      summary: summaryJson != null ? RecordingSummary.fromJson(summaryJson) : null,
    );
  }
}

class RecordingSummary {
  final String id;
  final String recordingId;
  final String? transcript;
  final String? summary;
  final List<String> keyInsights;
  final List<String> actionItems;
  final DateTime createdAt;

  const RecordingSummary({
    required this.id,
    required this.recordingId,
    this.transcript,
    this.summary,
    this.keyInsights = const [],
    this.actionItems = const [],
    required this.createdAt,
  });

  factory RecordingSummary.fromJson(Map<String, dynamic> json) => RecordingSummary(
    id: json['id'] as String,
    recordingId: json['recording_id'] as String,
    transcript: json['transcript'] as String?,
    summary: json['summary'] as String?,
    keyInsights: (json['key_insights'] as List?)?.cast<String>() ?? [],
    actionItems: (json['action_items'] as List?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
