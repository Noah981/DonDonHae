class DiseaseEvent {
  final String id;
  final String disease;
  final String country;
  final String province;
  final String district;
  final String place;
  final DateTime? occurredAt;
  final DateTime? announcedAt;
  final double? latitude;
  final double? longitude;
  final String locationPrecision;
  final String sourceName;
  final String sourceUrl;
  final String summary;

  const DiseaseEvent({
    required this.id,
    required this.disease,
    required this.country,
    required this.province,
    required this.district,
    required this.place,
    required this.occurredAt,
    required this.announcedAt,
    required this.latitude,
    required this.longitude,
    required this.locationPrecision,
    required this.sourceName,
    required this.sourceUrl,
    required this.summary,
  });

  bool get isDomestic => country == '대한민국' || country == 'KR';

  factory DiseaseEvent.fromJson(Map<String, dynamic> json) => DiseaseEvent(
        id: '${json['id'] ?? ''}',
        disease: '${json['disease'] ?? ''}',
        country: '${json['country'] ?? ''}',
        province: '${json['province'] ?? ''}',
        district: '${json['district'] ?? ''}',
        place: '${json['place'] ?? ''}',
        occurredAt: DateTime.tryParse('${json['occurredAt'] ?? ''}'),
        announcedAt: DateTime.tryParse('${json['announcedAt'] ?? ''}'),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        locationPrecision: '${json['locationPrecision'] ?? ''}',
        sourceName: '${json['sourceName'] ?? ''}',
        sourceUrl: '${json['sourceUrl'] ?? ''}',
        summary: '${json['summary'] ?? ''}',
      );
}

enum DiseaseLoadState { loading, fresh, stale, unavailable }

class DiseaseSnapshot {
  final DiseaseLoadState state;
  final DateTime? updatedAt;
  final List<DiseaseEvent> events;
  final String notice;

  const DiseaseSnapshot({
    required this.state,
    required this.updatedAt,
    required this.events,
    required this.notice,
  });
}
