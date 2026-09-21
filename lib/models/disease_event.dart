enum DiseaseVerificationLevel {
  official,
  officialRegionOnly,
  unverified,
}

class DiseaseEvent {
  final String id;
  final String diseaseType;
  final String countryCode;
  final String province;
  final String cityCounty;
  final String districtCode;
  final double? latitude;
  final double? longitude;
  final DateTime? occurrenceDate;
  final DateTime? announcementDate;
  final String livestockType;
  final String status;
  final String source;
  final String sourceUrl;
  final DiseaseVerificationLevel verificationLevel;
  final String summary;

  const DiseaseEvent({
    required this.id,
    required this.diseaseType,
    required this.countryCode,
    required this.province,
    required this.cityCounty,
    required this.districtCode,
    required this.latitude,
    required this.longitude,
    required this.occurrenceDate,
    required this.announcementDate,
    required this.livestockType,
    required this.status,
    required this.source,
    required this.sourceUrl,
    required this.verificationLevel,
    required this.summary,
  });

  String get disease => diseaseType;
  String get district => cityCounty;
  String get sourceName => source;
  DateTime? get occurredAt => occurrenceDate;
  DateTime? get announcedAt => announcementDate;
  bool get isDomestic => countryCode.toUpperCase() == 'KR';
  bool get hasPreciseCoordinate => latitude != null && longitude != null;
  bool get canRenderMarker =>
      verificationLevel == DiseaseVerificationLevel.official ||
      verificationLevel == DiseaseVerificationLevel.officialRegionOnly;

  factory DiseaseEvent.fromJson(Map<String, dynamic> json) {
    final rawVerification = '${json['verificationLevel'] ?? ''}'.toLowerCase();
    final verification = switch (rawVerification) {
      'official' => DiseaseVerificationLevel.official,
      'official_region_only' || 'officialregiononly' =>
        DiseaseVerificationLevel.officialRegionOnly,
      _ => DiseaseVerificationLevel.unverified,
    };

    final country = '${json['countryCode'] ?? json['country'] ?? ''}'.trim();
    return DiseaseEvent(
      id: '${json['id'] ?? ''}',
      diseaseType: '${json['diseaseType'] ?? json['disease'] ?? ''}',
      countryCode: country == '대한민국' ? 'KR' : country.toUpperCase(),
      province: '${json['province'] ?? ''}',
      cityCounty: '${json['cityCounty'] ?? json['district'] ?? ''}',
      districtCode: '${json['districtCode'] ?? ''}',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      occurrenceDate: DateTime.tryParse(
        '${json['occurrenceDate'] ?? json['occurredAt'] ?? ''}',
      ),
      announcementDate: DateTime.tryParse(
        '${json['announcementDate'] ?? json['announcedAt'] ?? ''}',
      ),
      livestockType: '${json['livestockType'] ?? ''}',
      status: '${json['status'] ?? ''}',
      source: '${json['source'] ?? json['sourceName'] ?? ''}',
      sourceUrl: '${json['sourceUrl'] ?? ''}',
      verificationLevel: verification,
      summary: '${json['summary'] ?? ''}',
    );
  }
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
