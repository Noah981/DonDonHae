import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/disease_event.dart';

class KoreaDiseaseMap extends StatefulWidget {
  final List<DiseaseEvent> events;
  final double? userLatitude;
  final double? userLongitude;
  final ValueChanged<DiseaseEvent>? onEventTap;

  const KoreaDiseaseMap({
    super.key,
    required this.events,
    this.userLatitude,
    this.userLongitude,
    this.onEventTap,
  });

  @override
  State<KoreaDiseaseMap> createState() => _KoreaDiseaseMapState();
}

class _KoreaDiseaseMapState extends State<KoreaDiseaseMap> {
  Future<List<_RegionShape>>? _shapes;

  @override
  void initState() {
    super.initState();
    _shapes = _loadShapes();
  }

  Future<List<_RegionShape>> _loadShapes() async {
    final raw = await rootBundle.loadString('assets/data/korea_provinces.geojson');
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final features = root['features'] as List<dynamic>? ?? const [];
    return features.whereType<Map<String, dynamic>>().map(_RegionShape.fromFeature).toList();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<_RegionShape>>(
        future: _shapes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('행정경계 지도를 불러오지 못했습니다.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return LayoutBuilder(builder: (context, constraints) {
            final projector = _Projector(Size(constraints.maxWidth, constraints.maxHeight));
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (detail) => _handleTap(detail.localPosition, projector, snapshot.data!),
              child: CustomPaint(
                painter: _KoreaMapPainter(
                  shapes: snapshot.data!,
                  events: widget.events,
                  userLatitude: widget.userLatitude,
                  userLongitude: widget.userLongitude,
                  projector: projector,
                ),
              ),
            );
          });
        },
      );

  void _handleTap(Offset point, _Projector projector, List<_RegionShape> shapes) {
    DiseaseEvent? closest;
    var distance = double.infinity;
    for (final event in widget.events) {
      if (!event.isDomestic) continue;
      final marker = _eventPoint(event, shapes, projector);
      if (marker == null) continue;
      final current = (marker - point).distance;
      if (current < 24 && current < distance) {
        closest = event;
        distance = current;
      }
    }
    if (closest != null) widget.onEventTap?.call(closest);
  }
}

class _RegionShape {
  final String name;
  final List<List<Offset>> rings;

  const _RegionShape(this.name, this.rings);

  Offset? get anchor {
    if (rings.isEmpty) return null;
    List<Offset>? largest;
    var largestArea = -1.0;
    for (final ring in rings) {
      var minX = double.infinity;
      var maxX = double.negativeInfinity;
      var minY = double.infinity;
      var maxY = double.negativeInfinity;
      for (final point in ring) {
        minX = math.min(minX, point.dx);
        maxX = math.max(maxX, point.dx);
        minY = math.min(minY, point.dy);
        maxY = math.max(maxY, point.dy);
      }
      final area = (maxX - minX) * (maxY - minY);
      if (area > largestArea) {
        largestArea = area;
        largest = ring;
      }
    }
    final targetRing = largest;
    if (targetRing == null || targetRing.isEmpty) return null;
    final bounds = targetRing.fold<Rect>(
      Rect.fromLTWH(targetRing.first.dx, targetRing.first.dy, 0, 0),
      (rect, point) => rect.expandToInclude(Rect.fromLTWH(point.dx, point.dy, 0, 0)),
    );
    return bounds.center;
  }

  factory _RegionShape.fromFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>? ?? const {};
    final geometry = feature['geometry'] as Map<String, dynamic>? ?? const {};
    final type = '${geometry['type'] ?? ''}';
    final coordinates = geometry['coordinates'] as List<dynamic>? ?? const [];
    final rings = <List<Offset>>[];

    void addPolygon(List<dynamic> polygon) {
      for (final rawRing in polygon.whereType<List<dynamic>>()) {
        final ring = rawRing
            .whereType<List<dynamic>>()
            .where((point) => point.length >= 2)
            .map((point) => Offset(
                  (point[0] as num).toDouble(),
                  (point[1] as num).toDouble(),
                ))
            .toList();
        if (ring.length >= 3) rings.add(ring);
      }
    }

    if (type == 'Polygon') addPolygon(coordinates);
    if (type == 'MultiPolygon') {
      for (final polygon in coordinates.whereType<List<dynamic>>()) {
        addPolygon(polygon);
      }
    }
    return _RegionShape('${properties['name'] ?? ''}', rings);
  }
}

class _Projector {
  static const minLon = 124.45;
  static const maxLon = 132.05;
  static const minLat = 32.9;
  static const maxLat = 38.75;
  final Size size;

  const _Projector(this.size);

  Offset point(double longitude, double latitude) {
    const padding = 10.0;
    final width = math.max(1.0, size.width - padding * 2);
    final height = math.max(1.0, size.height - padding * 2);
    final x = padding + (longitude - minLon) / (maxLon - minLon) * width;
    final y = padding + (maxLat - latitude) / (maxLat - minLat) * height;
    return Offset(x, y);
  }
}

class _KoreaMapPainter extends CustomPainter {
  final List<_RegionShape> shapes;
  final List<DiseaseEvent> events;
  final double? userLatitude;
  final double? userLongitude;
  final _Projector projector;

  const _KoreaMapPainter({
    required this.shapes,
    required this.events,
    required this.userLatitude,
    required this.userLongitude,
    required this.projector,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xffe5f3ea);
    final border = Paint()
      ..color = const Color(0xff7ba68c)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;
    for (final shape in shapes) {
      for (final ring in shape.rings) {
        final path = Path()..moveTo(projector.point(ring.first.dx, ring.first.dy).dx, projector.point(ring.first.dx, ring.first.dy).dy);
        for (final coordinate in ring.skip(1)) {
          final point = projector.point(coordinate.dx, coordinate.dy);
          path.lineTo(point.dx, point.dy);
        }
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, border);
      }
    }

    for (final event in events) {
      if (!event.isDomestic) continue;
      final point = _eventPoint(event, shapes, projector);
      if (point == null) continue;
      final precise = event.latitude != null && event.longitude != null;
      final color = precise ? const Color(0xffd62f3a) : const Color(0xffdb7b00);
      canvas.drawCircle(point, 7, Paint()..color = color.withOpacity(.22));
      if (precise) {
        canvas.drawCircle(point, 3.6, Paint()..color = color);
      } else {
        final diamond = Path()
          ..moveTo(point.dx, point.dy - 4.5)
          ..lineTo(point.dx + 4.5, point.dy)
          ..lineTo(point.dx, point.dy + 4.5)
          ..lineTo(point.dx - 4.5, point.dy)
          ..close();
        canvas.drawPath(diamond, Paint()..color = color);
      }
    }

    if (userLatitude != null && userLongitude != null) {
      final point = projector.point(userLongitude!, userLatitude!);
      canvas.drawCircle(point, 8, Paint()..color = const Color(0xff2979ff).withOpacity(.18));
      canvas.drawCircle(point, 4, Paint()..color = const Color(0xff2979ff));
      final locationBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(point, 4, locationBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _KoreaMapPainter oldDelegate) =>
      oldDelegate.events != events ||
      oldDelegate.userLatitude != userLatitude ||
      oldDelegate.userLongitude != userLongitude ||
      oldDelegate.shapes != shapes;
}

Offset? _eventPoint(DiseaseEvent event, List<_RegionShape> shapes, _Projector projector) {
  if (event.latitude != null && event.longitude != null) {
    return projector.point(event.longitude!, event.latitude!);
  }
  final eventRegion = _normalizeRegion(event.province);
  for (final shape in shapes) {
    if (_normalizeRegion(shape.name) == eventRegion) {
      final anchor = shape.anchor;
      return anchor == null ? null : projector.point(anchor.dx, anchor.dy);
    }
  }
  return null;
}

String _normalizeRegion(String value) => value
    .replaceAll('특별자치도', '도')
    .replaceAll('특별자치시', '시')
    .replaceAll('특별시', '시')
    .replaceAll('광역시', '시')
    .replaceAll('전북도', '전라북도')
    .replaceAll('강원도', '강원도')
    .replaceAll('전남광주통합도', '전라남도')
    .replaceAll('전남광주통합시', '전라남도');
