import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/disease_repository.dart';
import '../models/disease_event.dart';
import '../widgets/korea_disease_map.dart';

class DiseasePage extends StatefulWidget {
  const DiseasePage({super.key});

  @override
  State<DiseasePage> createState() => _DiseasePageState();
}

class _DiseasePageState extends State<DiseasePage> {
  static const filters = ['ASF', '구제역', 'PED', 'PRRS'];
  final repository = const DiseaseRepository();
  late Future<DiseaseSnapshot> snapshot;
  String selected = 'ASF';
  bool domestic = true;
  Position? position;

  @override
  void initState() {
    super.initState();
    snapshot = repository.load();
    _loadLocation();
  }

  Future<void> _refresh() async {
    setState(() => snapshot = repository.load());
    await snapshot;
  }

  Future<void> _loadLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
    final current = await Geolocator.getCurrentPosition();
    if (mounted) setState(() => position = current);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('질병 정보')),
        body: FutureBuilder<DiseaseSnapshot>(
          future: snapshot,
          builder: (context, result) {
            final data = result.data;
            final allEvents = data?.events ?? const <DiseaseEvent>[];
            final events = allEvents
                .where((event) => event.disease == selected)
                .where((event) => domestic ? event.isDomestic : !event.isDomestic)
                .toList();
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  const Text('공식 발표 기준으로 가축질병 상황을 확인하세요', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 14),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('국내')),
                      ButtonSegment(value: false, label: Text('해외')),
                    ],
                    selected: {domestic},
                    onSelectionChanged: (value) => setState(() => domestic = value.first),
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      segments: filters.map((value) => ButtonSegment(value: value, label: Text(value))).toList(),
                      selected: {selected},
                      onSelectionChanged: (value) => setState(() => selected = value.first),
                      showSelectedIcon: false,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (domestic)
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: AspectRatio(
                        aspectRatio: .82,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: KoreaDiseaseMap(
                                  events: events,
                                  userLatitude: position?.latitude,
                                  userLongitude: position?.longitude,
                                  onEventTap: _showEvent,
                                ),
                              ),
                            ),
                            const Positioned(
                              left: 10,
                              bottom: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: Color(0xeefafafa), borderRadius: BorderRadius.all(Radius.circular(8))),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  child: Text('SGIS 행정경계 기반 · ● 실제 좌표  ◆ 행정구역', style: TextStyle(fontSize: 10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!domestic)
                    const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('해외 발생은 국가·지역 목록으로 구분해 표시합니다. 국내 지도에는 표시하지 않습니다.'))),
                  const SizedBox(height: 12),
                  _StatusCard(snapshot: data, loading: result.connectionState == ConnectionState.waiting),
                  const SizedBox(height: 12),
                  if (events.isEmpty && result.connectionState != ConnectionState.waiting)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(data?.state == DiseaseLoadState.unavailable
                            ? '현재 공식 발생정보를 확인하지 못했습니다. 이는 발생 0건을 뜻하지 않습니다.'
                            : '선택한 조건에 표시할 공식 발생정보가 없습니다.'),
                      ),
                    ),
                  ...events.map((event) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            onTap: () => _showEvent(event),
                            title: Text('${event.province} ${event.district}'.trim(), style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(_eventSubtitle(event)),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                  const Text('앱은 공식 발표 원문을 전달하며 이동제한·살처분·법적 방역구역 또는 의무를 임의로 판단하지 않습니다.', style: TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            );
          },
        ),
      );

  String _eventSubtitle(DiseaseEvent event) {
    final date = event.occurredAt ?? event.announcedAt;
    final dateText = date == null ? '발생일 확인 필요' : '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return '$dateText · ${event.sourceName}';
  }

  void _showEvent(DiseaseEvent event) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${event.disease} · ${event.province} ${event.district}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Text(event.summary.isEmpty ? '공식 발표 원문에서 세부 정보를 확인하세요.' : event.summary),
                const SizedBox(height: 12),
                Text('출처: ${event.sourceName}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                if (event.sourceUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => launchUrl(Uri.parse(event.sourceUrl), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('공식 원문 확인'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class _StatusCard extends StatelessWidget {
  final DiseaseSnapshot? snapshot;
  final bool loading;

  const _StatusCard({required this.snapshot, required this.loading});

  @override
  Widget build(BuildContext context) {
    final state = snapshot?.state;
    final label = loading
        ? '불러오는 중'
        : state == DiseaseLoadState.fresh
            ? '최신 확인'
            : state == DiseaseLoadState.stale
                ? '업데이트 지연'
                : '확인 중';
    final color = state == DiseaseLoadState.fresh
        ? const Color(0xff247a4c)
        : state == DiseaseLoadState.stale
            ? const Color(0xffaa6c00)
            : const Color(0xff666666);
    return Card(
      child: ListTile(
        leading: Icon(Icons.verified_outlined, color: color),
        title: const Text('공식 질병정보 상태', style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(snapshot?.notice.isNotEmpty == true ? snapshot!.notice : '공식 자료를 확인하고 있습니다.'),
        trailing: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
