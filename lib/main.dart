import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/disease_page.dart';

void main() => runApp(const DonDonHaeApp());

class DonDonHaeApp extends StatelessWidget {
  const DonDonHaeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '돈돈해',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffee7379)),
          scaffoldBackgroundColor: const Color(0xfffffaf8),
          cardTheme: CardThemeData(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xffffe5df)),
            ),
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: Color(0xffffe4e4),
            height: 68,
          ),
        ),
        home: const Dashboard(),
      );
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, dynamic>? price;
  List<Map<String, dynamic>> markets = const [];
  int tab = 0;

  Future<void> load() async {
    final p = jsonDecode(await rootBundle.loadString('assets/data/pig-price.json'))
        as Map<String, dynamic>;
    final m = jsonDecode(await rootBundle.loadString('assets/data/platform.json'))
        as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      price = p;
      markets = (m['markets'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(price: price, markets: markets, onRefresh: load),
      _MarketTab(markets: markets),
      const _TodoTab(),
      const _FarmCheckTab(),
      const _MoreTab(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '홈'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: '시황'),
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: '할 일'),
          NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check),
              label: '농장점검'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: '더보기'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? price;
  final List<Map<String, dynamic>> markets;
  final Future<void> Function() onRefresh;

  const _HomeTab(
      {required this.price, required this.markets, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final p = price;
    if (p == null) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          const _TopBar(),
          const SizedBox(height: 14),
          _HeroCard(dateText: _todayText()),
          const SizedBox(height: 14),
          _PriceCard(price: p),
          const SizedBox(height: 14),
          const _TodayWeatherRow(),
          const SizedBox(height: 22),
          const _SectionHeader(
            title: '국제 시황 & 원료 흐름',
            subtitle: '환율·유가·주요 사료원료 흐름',
          ),
          const SizedBox(height: 10),
          _MarketGrid(items: markets.take(4).toList()),
          const SizedBox(height: 22),
          const _SectionHeader(
            title: '양돈 이슈 & 공지',
            subtitle: '공식 발표와 농장 운영에 필요한 정보',
          ),
          const SizedBox(height: 10),
          _IssueCard(
            icon: Icons.coronavirus_outlined,
            bg: const Color(0xffffe9e8),
            title: '질병 정보',
            subtitle: '국내·해외 가축질병 발생 현황',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiseasePage()),
            ),
          ),
          const SizedBox(height: 10),
          const _IssueCard(
            icon: Icons.account_balance_outlined,
            bg: Color(0xffedf7ef),
            title: '지원사업 · 인증',
            subtitle: '지역별 지원사업과 인증 정보 · 연동 준비 중',
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/images/dondonhae_symbol.png',
                width: 42, height: 42, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('돈돈해',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                Text('양돈의 오늘을 든든하게',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.notifications_none_rounded),
        ],
      );
}

class _HeroCard extends StatelessWidget {
  final String dateText;
  const _HeroCard({required this.dateText});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xffffece7), Color(0xfffff7ed)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xffffdfd5)),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('오늘도 든든하게',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xffa35c57),
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 5),
                  Text('농장에 필요한 흐름을\n한눈에 확인하세요',
                      style: TextStyle(
                          fontSize: 23,
                          height: 1.25,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.wb_sunny_outlined,
                    size: 34, color: Color(0xffe98a57)),
                const SizedBox(height: 14),
                Text(dateText,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
                const Text('현재 지역 · 설정 예정',
                    style:
                        TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ],
        ),
      );
}

class _PriceCard extends StatelessWidget {
  final Map<String, dynamic> price;
  const _PriceCard({required this.price});

  @override
  Widget build(BuildContext context) {
    final change = (price['change'] as num?)?.toInt() ?? 0;
    final down = change < 0;
    final previous = price['previousPrice'];
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PriceDetailPage(price: price)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('전국 돈가',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xfffff0ed),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text('제주 제외',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xffad625e))),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_comma(price['price']),
                      style: const TextStyle(
                          fontSize: 43,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5)),
                  const Padding(
                    padding: EdgeInsets.only(left: 5, bottom: 4),
                    child: Text('원/kg',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54)),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                '전일 대비 ${change > 0 ? '+' : ''}${_comma(change)}원 (${price['changePct']}%)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: down
                      ? const Color(0xff3478c7)
                      : const Color(0xffdf5656),
                ),
              ),
              if (previous != null)
                Text('전일 ${_comma(previous)}원',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 15),
              const SizedBox(height: 68, child: _MiniTrend()),
              const SizedBox(height: 10),
              Text('${_date(price['date'])} 기준 · ${price['source']}',
                  style:
                      const TextStyle(fontSize: 11, color: Colors.black45)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTrend extends StatelessWidget {
  const _MiniTrend();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _MiniTrendPainter(), child: const SizedBox.expand());
}

class _MiniTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xffef7a83)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final grid = Paint()
      ..color = const Color(0xffffe7e2)
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final values = [.66, .47, .30, .25, .18, .29, .40, .56];
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(size.width * i / (values.length - 1),
          size.height * values[i]);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TodayWeatherRow extends StatelessWidget {
  const _TodayWeatherRow();

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          Expanded(
              child: _SmallInfoCard(
                  icon: Icons.check_circle_outline,
                  title: '오늘 할 일',
                  value: '일정 등록',
                  caption: '농장 일정 관리')),
          SizedBox(width: 10),
          Expanded(
              child: _SmallInfoCard(
                  icon: Icons.cloud_outlined,
                  title: '오늘 날씨',
                  value: '연동 준비 중',
                  caption: '기상청 데이터 연결 예정')),
        ],
      );
}

class _SmallInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String caption;

  const _SmallInfoCard(
      {required this.icon,
      required this.title,
      required this.value,
      required this.caption});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xffd96e73)),
              const SizedBox(height: 10),
              Text(title,
                  style:
                      const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 3),
              Text(value,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 10, color: Colors.black45)),
            ],
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(subtitle,
              style:
                  const TextStyle(fontSize: 11, color: Colors.black45)),
        ],
      );
}

class _MarketGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _MarketGrid({required this.items});

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 132,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (_, i) => _MarketCard(item: items[i]),
      );
}

class _MarketCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _MarketCard({required this.item});

  static const labels = {
    'usd_krw': '원/달러 환율',
    'wti': 'WTI',
    'corn': '옥수수',
    'soybean_meal': '대두박',
    'soybean': '대두',
    'wheat': '소맥'
  };

  static const icons = {
    'usd_krw': Icons.currency_exchange,
    'wti': Icons.oil_barrel_outlined,
    'corn': Icons.grass,
    'soybean_meal': Icons.eco_outlined,
    'soybean': Icons.spa_outlined,
    'wheat': Icons.agriculture_outlined
  };

  @override
  Widget build(BuildContext context) {
    final name = '${item['name'] ?? ''}';
    final pct = (item['changePct'] as num?)?.toDouble() ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Align(
                alignment: Alignment.topRight,
                child: Icon(icons[name] ?? Icons.show_chart,
                    size: 28, color: const Color(0x22d66d74))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(labels[name] ?? name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                const Spacer(),
                FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('${item['value']}',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900))),
                Text('${item['unit'] ?? ''}',
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black45)),
                const SizedBox(height: 4),
                Text('${pct > 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: pct < 0
                            ? const Color(0xff3478c7)
                            : const Color(0xffdf5656))),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _IssueCard(
      {required this.icon,
      required this.bg,
      required this.title,
      required this.subtitle,
      this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          leading: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: const Color(0xffb95d62))),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}

class _MarketTab extends StatelessWidget {
  final List<Map<String, dynamic>> markets;
  const _MarketTab({required this.markets});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('시황',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('국제 시황과 주요 사료원료 흐름',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          _MarketGrid(items: markets),
        ],
      );
}

class _TodoTab extends StatelessWidget {
  const _TodoTab();
  @override
  Widget build(BuildContext context) => const _EmptyTab(
      icon: Icons.add_task,
      title: '오늘 할 일',
      description: '사료 주문, 출하, 백신·점검 일정을 간단하게 관리하는 영역입니다.');
}

class _FarmCheckTab extends StatelessWidget {
  const _FarmCheckTab();
  @override
  Widget build(BuildContext context) => const _EmptyTab(
      icon: Icons.fact_check_outlined,
      title: '농장점검',
      description: '분만·자돈·육성·비육 구간별 점검 기능을 연결할 예정입니다.');
}

class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('더보기',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          SizedBox(height: 16),
          _IssueCard(
              icon: Icons.location_on_outlined,
              bg: Color(0xffedf7ef),
              title: '관심 지역 설정',
              subtitle: '지역 맞춤 정보 설정'),
          SizedBox(height: 10),
          _IssueCard(
              icon: Icons.notifications_outlined,
              bg: Color(0xfffff1e3),
              title: '알림 설정',
              subtitle: '돈가·질병·지원사업 알림'),
          SizedBox(height: 10),
          _IssueCard(
              icon: Icons.info_outline,
              bg: Color(0xfff0f1f5),
              title: '앱 정보',
              subtitle: '돈돈해 v1.7.0 · WORK3'),
        ],
      );
}

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyTab(
      {required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: const Color(0xffde757b)),
              const SizedBox(height: 15),
              Text(title,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, height: 1.5)),
            ],
          ),
        ),
      );
}

class PriceDetailPage extends StatelessWidget {
  final Map<String, dynamic> price;
  const PriceDetailPage({super.key, required this.price});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('전국 돈가')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PriceCard(price: price),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                    '기준: 전국 · 탕박 · 등외 제외 · 제주 제외\n새 확정 돈가가 확인되면 동일 데이터 계층에서 갱신하도록 연결합니다.'),
              ),
            ),
          ],
        ),
      );
}

String _comma(dynamic value) {
  final s = value.toString();
  final neg = s.startsWith('-');
  final raw = neg ? s.substring(1) : s;
  final b = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) b.write(',');
    b.write(raw[i]);
  }
  return '${neg ? '-' : ''}§b';
}

String _date(dynamic value) {
  final s = value.toString();
  if (s.length != 8) return s;
  return '${s.substring(0, 4)}.${s.substring(4, 6)}.${s.substring(6, 8)}';
}

String _todayText() {
  final now = DateTime.now();
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} (${weekdays[now.weekday - 1]})';
}
