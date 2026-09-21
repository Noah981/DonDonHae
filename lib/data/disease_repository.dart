import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/disease_event.dart';

class DiseaseRepository {
  const DiseaseRepository();

  Future<DiseaseSnapshot> load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/disease-alerts.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final events = (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DiseaseEvent.fromJson)
          .where((event) => event.id.isNotEmpty && event.disease.isNotEmpty)
          .toList()
        ..sort((a, b) => (b.occurredAt ?? b.announcedAt ?? DateTime(1900))
            .compareTo(a.occurredAt ?? a.announcedAt ?? DateTime(1900)));
      final updatedAt = DateTime.tryParse('${json['updatedAt'] ?? ''}');
      final age = updatedAt == null ? null : DateTime.now().difference(updatedAt);
      final state = updatedAt == null
          ? DiseaseLoadState.unavailable
          : age != null && age > const Duration(hours: 24)
              ? DiseaseLoadState.stale
              : DiseaseLoadState.fresh;
      return DiseaseSnapshot(
        state: state,
        updatedAt: updatedAt,
        events: events,
        notice: '${json['notice'] ?? ''}',
      );
    } catch (_) {
      return const DiseaseSnapshot(
        state: DiseaseLoadState.unavailable,
        updatedAt: null,
        events: [],
        notice: '공식 발생 정보를 불러오지 못했습니다. 발생 0건으로 해석하지 마세요.',
      );
    }
  }
}
