import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dondonhae/data/korea_geometry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('official-vector snapshot resolves key Korean coordinates', () async {
    final provinceRaw =
        await rootBundle.loadString('assets/data/korea_provinces.geojson');
    final municipalityRaw =
        await rootBundle.loadString('assets/data/korea_municipalities.geojson');
    final index = KoreaGeometryIndex(
      provinces: KoreaRegionGeometry.parseGeoJson(provinceRaw),
      municipalities: KoreaRegionGeometry.parseGeoJson(municipalityRaw),
    );

    String provinceAt(double lon, double lat) =>
        index
            .regionContaining(lon, lat, preferMunicipality: false)
            ?.name ??
        '';
    String municipalityAt(double lon, double lat) =>
        index.regionContaining(lon, lat)?.name ?? '';

    expect(normalizeKoreaRegion(provinceAt(126.9780, 37.5665)),
        contains('서울'));
    expect(normalizeKoreaRegion(provinceAt(128.6014, 35.8714)),
        contains('대구'));
    expect(normalizeKoreaRegion(provinceAt(129.0756, 35.1796)),
        contains('부산'));
    expect(normalizeKoreaRegion(provinceAt(126.5312, 33.4996)),
        contains('제주'));
    expect(normalizeKoreaRegion(provinceAt(130.9057, 37.4845)),
        contains('경상북도'));
    expect(normalizeKoreaRegion(provinceAt(131.8653, 37.2411)),
        contains('경상북도'));

    expect(normalizeKoreaRegion(municipalityAt(130.9057, 37.4845)),
        contains('울릉'));
    expect(normalizeKoreaRegion(municipalityAt(131.8653, 37.2411)),
        contains('울릉'));
  });
}
