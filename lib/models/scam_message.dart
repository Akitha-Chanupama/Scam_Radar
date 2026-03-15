class ScamMessage {
  final String? id;
  final String userId;
  final String messageText;
  final int scamScore;
  final List<String> reasons;
  final bool isReported;
  final DateTime createdAt;

  const ScamMessage({
    this.id,
    required this.userId,
    required this.messageText,
    required this.scamScore,
    this.reasons = const [],
    this.isReported = false,
    required this.createdAt,
  });

  factory ScamMessage.fromJson(Map<String, dynamic> json) => ScamMessage(
    id: json['id'] as String?,
    userId: json['user_id'] as String,
    messageText: json['message_text'] as String,
    scamScore: json['scam_score'] as int? ?? 0,
    reasons:
        (json['reasons'] as List<dynamic>?)?.map((e) => e as String).toList() ??
        [],
    isReported: json['is_reported'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'message_text': messageText,
    'scam_score': scamScore,
    'reasons': reasons,
    'is_reported': isReported,
    'created_at': createdAt.toIso8601String(),
  };
}
