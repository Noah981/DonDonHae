import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/korea_geometry.dart';
import '../models/disease_event.dart';

class KoreaDiseaseMap extends StatefulWidget {
  final List<DiseaseEvent> events;
  final double? userLatitude;
  final double? userLongitude;
  final String? focusedEventId;
  final ValueChanged<DiseaseEvent>? onEventTap;

  const KoreaDiseaseMap({
    super.key,
    required this.events,
    this.userLatitude,
    this.userLongitude,
    this.focusedEventId,
    this.onEventTap,
  });

  @override
  State<KoreaDiseaseMap> createState() => _KoreaDiseaseMapState();
}

class _KoreaDiseaseMapState extends State<KoreaDiseaseMap> {
  late final Future<KoreaGeometryIndex> _geometry = _loadGeometry();
  final TransformationController _transform = TransformationController();
  Size? _viewport;
  KoreaGeometryIndex? _loadedGeometry;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant KoreaDiseaseMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedEventId != widget.focusedEventId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusSelected());
    }
  }

  Future<KoreaGeometryIndex> _loadGeometry() async {
    final results = await Future.wait([
      rootBundle.loadString('assets/data/korea_provinces.geojson'),
      rootBundle.loadString('assets/data/korea_municipalities.geojson'),
    ]);
    final index = KoreaGeometryIndex(
      provinces: KoreaRegionGeometry.parseGeoJson(results[0]),
      municipalities: KoreaRegionGeometry.parseGeoJson(results[1]),
    );
    _loadedGeometry = index;
    return index;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<KoreaGeometryIndex>(
        future: _geometry,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('행정경계 지도를 불러오지 못했습니다.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final size =
                  Size(constraints.maxWidth, constraints.maxHeight);
              _viewport = size;
              final projector = KoreaMapProjector(size);
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _focusSelected());
              return InteractiveViewer(
                transformationController: _transform,
                minScale: 1,
                maxScale: 7,
                boundaryMargin: const EdgeInsets.all(40),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (detail) => _handleTap(
                    detail.localPosition,
                    projector,
                    snapshot.data!,
                  ),
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: CustomPaint(
                      painter: _KoreaMapPainter(
                        geometry: snapshot.data!,
                        events: widget.events,
                        userLatitude: widget.userLatitude,
                        userLongitude: widget.userLongitude,
                        focusedEventId: widget.focusedEventId,
                        projector: projector,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

  void _focusSelected() {
    final id = widget.focusedEventId;
    final geometry = _loadedGeometry;
    final size = _viewport;
    if (id == null || geometry == null || size == null) return;
    DiseaseEvent? selected;
    for (final event in widget.events) {
      if (event.id == id) {
        selected = event;
        break;
      }
    }
    if (selected == null) return;
    final projector = KoreaMapProjector(size);
    final point = eventMapPoint(selected, geometry, projector);
    if (point == null) return;

    const scale = 2.5;
    final tx = size.width / 2 - point.dx * scale;
    final ty = size.height / 2 - point.dy * scale;
    _transform.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
  }

  void _handleTap(
    Offset point,
    KoreaMapProjector projector,
    KoreaGeometryIndex geometry,
  ) {
    DiseaseEvent? closest;
    var distance = double.infinity;
    for (final event in widget.events) {
      if (!event.isDomestic || !event.canRenderMarker) continue;
      final marker = eventMapPoint(event, geometry, projector);
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

class KoreaMapProjector {
  static const minLon = 124.3;
  static const maxLon = 132.15;
  static const minLat = 32.8;
  static const maxLat = 38.85;

  final Size size;
  const KoreaMapProjector(this.size);

  Offset point(double longitude, double latitude) {
    const padding = 10.0;
    final width = math.max(1.0, size.width - padding * 2);
    final height = math.max(1.0, size.height - padding * 2);
    return Offset(
      padding + (longitude - minLon) / (maxLon - minLon) * width,
      padding + (maxLat - latitude) / (maxLat - minLat) * height,
    );
  }
}

class _KoreaMapPainter extends CustomPainter {
  final KoreaGeometryIndex geometry;
  final List<DiseaseEvent> events;
  final double? userLatitude;
  final double? userLongitude;
  final String? focusedEventId;
  final KoreaMapProjector projector;

  const _KoreaMapPainter({
    required this.geometry,
    required this.events,
    required this.userLatitude,
    required this.userLongitude,
    required this.focusedEventId,
    required this.projector,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    final land = Paint()..color = const Color(0xffe5e7eb);
    final provinceBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final municipalityBorder = Paint()
      ..color = Colors.white.withOpacity(.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .45;

    for (final region in geometry.provinces) {
      _drawRegion(canvas, region, land, provinceBorder);
    }
    for (final region in geometry.municipalities) {
      _drawRegion(canvas, region, null, municipalityBorder);
    }

    for (final event in events) {
      if (!event.isDomestic || !event.canRenderMarker) continue;
      final point = eventMapPoint(event, geometry, projector);
      if (point == null) continue;
      final selected = event.id == focusedEventId;
      final precise = event.hasPreciseCoordinate;
      final markerColor =
          precise ? const Color(0xffd92d3a) : const Color(0xffd97706);
      canvas.drawCircle(
        point,
        selected ? 10 : 7,
        Paint()..color = markerColor.withOpacity(.20),
      );
      canvas.drawCircle(
        point,
        selected ? 5 : 3.7,
        Paint()..color = markerColor,
      );
      if (!precise) {
        final diamond = Path()
          ..moveTo(point.dx, point.dy - (selected ? 6 : 4.5))
          ..lineTo(point.dx + (selected ? 6 : 4.5), point.dy)
          ..lineTo(point.dx, point.dy + (selected ? 6 : 4.5))
          ..lineTo(point.dx - (selected ? 6 : 4.5), point.dy)
          ..close();
        canvas.drawPath(diamond, Paint()..color = markerColor);
      }
    }

    if (userLatitude != null && userLongitude != null) {
      final point = projector.point(userLongitude!, userLatitude!);
      canvas.drawCircle(
        point,
        8,
        Paint()..color = const Color(0xff2563eb).withOpacity(.18),
      );
      canvas.drawCircle(point, 4, Paint()..color = const Color(0xff2563eb));
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawRegion(
    Canvas canvas,
    KoreaRegionGeometry region,
    Paint? fill,
    Paint stroke,
  ) {
    for (final ring in region.rings) {
      if (ring.isEmpty) continue;
      final first = projector.point(ring.first.dx, ring.first.dy);
      final path = Path()..moveTo(first.dx, first.dy);
      for (final coordinate in ring.skip(1)) {
        final point = projector.point(coordinate.dx, coordinate.dy);
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      if (fill != null) canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _KoreaMapPainter oldDelegate) =>
      oldDelegate.events != events ||
      oldDelegate.userLatitude != userLatitude ||
      oldDelegate.userLongitude != userLongitude ||
      oldDelegate.focusedEventId != focusedEventId ||
      oldDelegate.geometry != geometry;
}

Offset? eventMapPoint(
  DiseaseEvent event,
  KoreaGeometryIndex geometry,
  KoreaMapProjector projector,
) {
  if (!event.canRenderMarker) return null;
  if (event.hasPreciseCoordinate) {
    return projector.point(event.longitude!, event.latitude!);
  }

  final municipality = geometry.municipalityFor(
    districtCode: event.districtCode,
    cityCounty: event.cityCounty,
  );
  final municipalAnchor = municipality?.representativePoint;
  if (municipalAnchor != null) {
    return projector.point(municipalAnchor.dx, municipalAnchor.dy);
  }

  final province = geometry.provinceFor(event.province);
  final provinceAnchor = province?.representativePoint;
  if (provinceAnchor != null) {
    return projector.point(provinceAnchor.dx, provinceAnchor.dy);
  }
  return null;
}
