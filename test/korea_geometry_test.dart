import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dondonhae/data/korea_geometry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('official-vector snapshot places key Korean coordinates correctly',
      () async {
    final provinceRaw =
        await rootBundle.loadString('assets/data/korea_provinces.geojson');
    final municipalityRaw =
        await rootBundle.loadString('assets/data/korea_municipalities.geojson');
    final index = KoreaGeometryIndex(
      provinces: KoreaRegionGeometry.parseGeoJson(provinceRaw),
      municipalities: KoreaRegionGeometry.parseGeoJson(municipalityRaw),
    );

    String regionAt(double lon, double lat) =>
        index.regionContaining(lon, lat)?.name ?? '';

    expect(normalizeKoreaRegion(regionAt(126.9780, 37.5665)),
        contains('서울'));
    expect(normalizeKoreaRegion(regionAt(128.6014, 35.8714)),
        contains('대구'));
    expect(normalizeKoreaRegion(regionAt(129.0756, 35.1796)),
        contains('부산'));
    expect(normalizeKoreaRegion(regionAt(126.5312, 33.4996)),
        anyOf(contains('제주'), contains('제주시')));
    expect(normalizeKoreaRegion(regionAt(130.9057, 37.4845)),
        anyOf(contains('울릉'), contains('경상북도')));
    expect(normalizeKoreaRegion(regionAt(131.8653, 37.2411)),
        anyOf(contains('울릉'), contains('경상북도')));
  });
}
