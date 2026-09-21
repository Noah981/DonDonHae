import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

class KoreaRegionGeometry {
  final String code;
  final String name;
  final List<List<Offset>> rings;

  const KoreaRegionGeometry({
    required this.code,
    required this.name,
    required this.rings,
  });

  Offset? get representativePoint {
    List<Offset>? best;
    var bestArea = 0.0;
    for (final ring in rings) {
      final area = _signedArea(ring).abs();
      if (area > bestArea) {
        bestArea = area;
        best = ring;
      }
    }
    if (best == null || best!.length < 3) return null;
    final centroid = _centroid(best!);
    if (contains(centroid)) return centroid;
    return best!.first;
  }

  bool contains(Offset coordinate) {
    for (final ring in rings) {
      if (_pointInRing(coordinate, ring)) return true;
    }
    return false;
  }

  static List<KoreaRegionGeometry> parseGeoJson(String raw) {
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final features = root['features'] as List<dynamic>? ?? const [];
    return features
        .whereType<Map<String, dynamic>>()
        .map(KoreaRegionGeometry.fromFeature)
        .where((region) => region.rings.isNotEmpty)
        .toList(growable: false);
  }

  factory KoreaRegionGeometry.fromFeature(Map<String, dynamic> feature) {
    final properties =
        feature['properties'] as Map<String, dynamic>? ?? const {};
    final geometry = feature['geometry'] as Map<String, dynamic>? ?? const {};
    final type = '${geometry['type'] ?? ''}';
    final coordinates = geometry['coordinates'] as List<dynamic>? ?? const [];
    final rings = <List<Offset>>[];

    void addPolygon(List<dynamic> polygon) {
      if (polygon.isEmpty) return;
      final outer = polygon.first;
      if (outer is! List<dynamic>) return;
      final ring = outer
          .whereType<List<dynamic>>()
          .where((point) => point.length >= 2)
          .map(
            (point) => Offset(
              (point[0] as num).toDouble(),
              (point[1] as num).toDouble(),
            ),
          )
          .toList(growable: false);
      if (ring.length >= 3) rings.add(ring);
    }

    if (type == 'Polygon') addPolygon(coordinates);
    if (type == 'MultiPolygon') {
      for (final polygon in coordinates.whereType<List<dynamic>>()) {
        addPolygon(polygon);
      }
    }

    return KoreaRegionGeometry(
      code: '${properties['code'] ?? properties['adm_cd'] ?? ''}',
      name: '${properties['name'] ?? properties['adm_nm'] ?? ''}',
      rings: rings,
    );
  }
}

class KoreaGeometryIndex {
  final List<KoreaRegionGeometry> provinces;
  final List<KoreaRegionGeometry> municipalities;

  const KoreaGeometryIndex({
    required this.provinces,
    required this.municipalities,
  });

  KoreaRegionGeometry? municipalityFor({
    required String districtCode,
    required String cityCounty,
  }) {
    if (districtCode.isNotEmpty) {
      for (final region in municipalities) {
        if (region.code == districtCode ||
            region.code.startsWith(districtCode) ||
            districtCode.startsWith(region.code)) {
          return region;
        }
      }
    }
    final target = normalizeKoreaRegion(cityCounty);
    if (target.isEmpty) return null;
    for (final region in municipalities) {
      final candidate = normalizeKoreaRegion(region.name);
      if (candidate == target ||
          candidate.endsWith(target) ||
          target.endsWith(candidate)) {
        return region;
      }
    }
    return null;
  }

  KoreaRegionGeometry? provinceFor(String province) {
    final target = normalizeKoreaRegion(province);
    for (final region in provinces) {
      final candidate = normalizeKoreaRegion(region.name);
      if (candidate == target ||
          candidate.endsWith(target) ||
          target.endsWith(candidate)) {
        return region;
      }
    }
    return null;
  }

  KoreaRegionGeometry? regionContaining(
    double longitude,
    double latitude, {
    bool preferMunicipality = true,
  }) {
    final point = Offset(longitude, latitude);
    if (preferMunicipality) {
      for (final region in municipalities) {
        if (region.contains(point)) return region;
      }
    }
    for (final region in provinces) {
      if (region.contains(point)) return region;
    }
    return null;
  }
}

String normalizeKoreaRegion(String value) => value
    .replaceAll(' ', '')
    .replaceAll('특별자치도', '도')
    .replaceAll('특별자치시', '시')
    .replaceAll('특별시', '시')
    .replaceAll('광역시', '시')
    .replaceAll('전북도', '전라북도')
    .replaceAll('강원특별자치도', '강원도')
    .replaceAll('전북특별자치도', '전라북도')
    .replaceAll('제주특별자치도', '제주도');

double _signedArea(List<Offset> ring) {
  var sum = 0.0;
  for (var i = 0; i < ring.length; i++) {
    final a = ring[i];
    final b = ring[(i + 1) % ring.length];
    sum += a.dx * b.dy - b.dx * a.dy;
  }
  return sum / 2;
}

Offset _centroid(List<Offset> ring) {
  var areaTimesSix = 0.0;
  var cx = 0.0;
  var cy = 0.0;
  for (var i = 0; i < ring.length; i++) {
    final a = ring[i];
    final b = ring[(i + 1) % ring.length];
    final cross = a.dx * b.dy - b.dx * a.dy;
    areaTimesSix += cross;
    cx += (a.dx + b.dx) * cross;
    cy += (a.dy + b.dy) * cross;
  }
  if (areaTimesSix.abs() < 1e-12) {
    var x = 0.0;
    var y = 0.0;
    for (final point in ring) {
      x += point.dx;
      y += point.dy;
    }
    return Offset(x / ring.length, y / ring.length);
  }
  return Offset(
    cx / (3 * areaTimesSix),
    cy / (3 * areaTimesSix),
  );
}

bool _pointInRing(Offset point, List<Offset> ring) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final pi = ring[i];
    final pj = ring[j];
    final crosses = ((pi.dy > point.dy) != (pj.dy > point.dy)) &&
        (point.dx <
            (pj.dx - pi.dx) *
                    (point.dy - pi.dy) /
                    ((pj.dy - pi.dy).abs() < 1e-12
                        ? 1e-12
                        : (pj.dy - pi.dy)) +
                pi.dx);
    if (crosses) inside = !inside;
  }
  return inside;
}
