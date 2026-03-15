class ScamNumber {
  final String? id;
  final String phoneNumber;
  final String scamType;
  final String? reportedBy;
  final int reportsCount;
  final String? region;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const ScamNumber({
    this.id,
    required this.phoneNumber,
    required this.scamType,
    this.reportedBy,
    this.reportsCount = 1,
    this.region,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory ScamNumber.fromJson(Map<String, dynamic> json) => ScamNumber(
    id: json['id'] as String?,
    phoneNumber: json['phone_number'] as String,
    scamType: json['scam_type'] as String? ?? 'other',
    reportedBy: json['reported_by'] as String?,
    reportsCount: json['reports_count'] as int? ?? 1,
    region: json['region'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'phone_number': phoneNumber,
    'scam_type': scamType,
    'reported_by': reportedBy,
    'reports_count': reportsCount,
    'region': region,
    'latitude': latitude,
    'longitude': longitude,
    'created_at': createdAt.toIso8601String(),
  };
}
