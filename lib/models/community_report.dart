import 'scam_message.dart';
import 'scam_number.dart';

class CommunityReport {
  final String? id;
  final String reporterId;
  final String reportType;
  final String? scamMessageId;
  final String? scamNumberId;
  final String description;
  final DateTime createdAt;

  // Joined data (nullable, populated in queries)
  final String? reporterName;
  final ScamMessage? scamMessage;
  final ScamNumber? scamNumber;

  const CommunityReport({
    this.id,
    required this.reporterId,
    required this.reportType,
    this.scamMessageId,
    this.scamNumberId,
    this.description = '',
    required this.createdAt,
    this.reporterName,
    this.scamMessage,
    this.scamNumber,
  });

  factory CommunityReport.fromJson(Map<String, dynamic> json) {
    return CommunityReport(
      id: json['id'] as String?,
      reporterId: json['reporter_id'] as String,
      reportType: json['report_type'] as String,
      scamMessageId: json['scam_message_id'] as String?,
      scamNumberId: json['scam_number_id'] as String?,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      reporterName: json['profiles'] != null
          ? (json['profiles'] as Map<String, dynamic>)['name'] as String?
          : null,
      scamMessage: json['scam_messages'] != null
          ? ScamMessage.fromJson(json['scam_messages'] as Map<String, dynamic>)
          : null,
      scamNumber: json['scam_numbers'] != null
          ? ScamNumber.fromJson(json['scam_numbers'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'reporter_id': reporterId,
        'report_type': reportType,
        'scam_message_id': scamMessageId,
        'scam_number_id': scamNumberId,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };
}
