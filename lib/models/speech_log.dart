class SpeechLog {
  final String id;
  final String khutbahId;
  final String khutbahTitle;
  final DateTime deliveryDate;
  final String location;
  final String eventType;
  final int? audienceSize;
  final String? audienceDemographics;
  final String positiveFeedback;
  final String negativeFeedback;
  final String generalNotes;
  final DateTime createdAt;
  final DateTime modifiedAt;

  SpeechLog({
    required this.id,
    required this.khutbahId,
    required this.khutbahTitle,
    required this.deliveryDate,
    required this.location,
    required this.eventType,
    this.audienceSize,
    this.audienceDemographics,
    required this.positiveFeedback,
    required this.negativeFeedback,
    required this.generalNotes,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory SpeechLog.fromJson(Map<String, dynamic> json) {
    return SpeechLog(
      id: json['id'] as String,
      khutbahId: json['khutbah_id'] as String,
      khutbahTitle: json['khutbah_title'] as String,
      deliveryDate: DateTime.parse(json['delivery_date'] as String),
      location: json['location'] as String,
      eventType: json['event_type'] as String,
      audienceSize: json['audience_size'] as int?,
      audienceDemographics: json['audience_demographics'] as String?,
      positiveFeedback: json['positive_feedback'] as String? ?? '',
      negativeFeedback: json['negative_feedback'] as String? ?? '',
      generalNotes: json['general_notes'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      modifiedAt: DateTime.parse(json['modified_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'khutbah_id': khutbahId,
      'khutbah_title': khutbahTitle,
      'delivery_date': deliveryDate.toIso8601String(),
      'location': location,
      'event_type': eventType,
      'audience_size': audienceSize,
      'audience_demographics': audienceDemographics,
      'positive_feedback': positiveFeedback,
      'negative_feedback': negativeFeedback,
      'general_notes': generalNotes,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  SpeechLog copyWith({
    String? id,
    String? khutbahId,
    String? khutbahTitle,
    DateTime? deliveryDate,
    String? location,
    String? eventType,
    int? audienceSize,
    String? audienceDemographics,
    String? positiveFeedback,
    String? negativeFeedback,
    String? generalNotes,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return SpeechLog(
      id: id ?? this.id,
      khutbahId: khutbahId ?? this.khutbahId,
      khutbahTitle: khutbahTitle ?? this.khutbahTitle,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      location: location ?? this.location,
      eventType: eventType ?? this.eventType,
      audienceSize: audienceSize ?? this.audienceSize,
      audienceDemographics: audienceDemographics ?? this.audienceDemographics,
      positiveFeedback: positiveFeedback ?? this.positiveFeedback,
      negativeFeedback: negativeFeedback ?? this.negativeFeedback,
      generalNotes: generalNotes ?? this.generalNotes,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}
