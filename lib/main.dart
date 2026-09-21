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
      colorSchemeSeed: const Color(0xff2d8b57),
      scaffoldBackgroundColor: const Color(0xfff6f7f8),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
    ),
    home: const Dashboard(),
  );
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String,dynamic>? price;
  List<dynamic> markets=[];
  Future<void> load() async {
    final p=jsonDecode(await rootBundle.loadString('assets/data/pig-price.json')) as Map<String,dynamic>;
    final m=jsonDecode(await rootBundle.loadString('assets/data/platform.json')) as Map<String,dynamic>;
    if(mounted) setState(() {price=p; markets=(m['markets'] as List);});
  }
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext context){
    final p=price;
    return Scaffold(
      appBar: AppBar(title: Row(children:[Image.asset('assets/images/dondonhae_symbol.png',width:34,height:34),const SizedBox(width:9),const Text('돈돈해',style:TextStyle(fontWeight:FontWeight.w900))])),
      body:p==null?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,30),children:[
        const Text('양돈의 오늘을 든든하게',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
        const SizedBox(height:14),
        _PriceCard(price:p),
        const SizedBox(height:18),
        const Text('국제정세 & 원료 동향',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),
        const SizedBox(height:10),
        GridView.builder(
          shrinkWrap:true, physics:const NeverScrollableScrollPhysics(),
          gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisExtent:154,crossAxisSpacing:10,mainAxisSpacing:10),
          itemCount:markets.length,
          itemBuilder:(context,i)=>_MarketCard(item:markets[i] as Map<String,dynamic>),
        ),
        const SizedBox(height:18),
        _NavCard(icon:Icons.coronavirus_outlined,title:'질병 정보',subtitle:'국내·해외 가축질병 발생 현황',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const DiseasePage()))),
        const SizedBox(height:10),
        const _NavCard(icon:Icons.cloud_outlined,title:'날씨와 농장 대응',subtitle:'GPS 기반 기상·농장 환경 정보'),
        const SizedBox(height:10),
        const _NavCard(icon:Icons.account_balance_outlined,title:'지원사업 · 인증',subtitle:'지역별 지원사업과 인증 정보를 한곳에서'),
      ])),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final Map<String,dynamic> price;
  const _PriceCard({required this.price});
  @override Widget build(BuildContext context){
    final change=(price['change'] as num).toInt();
    final down=change<0;
    return Card(child:InkWell(borderRadius:BorderRadius.circular(12),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PriceDetailPage(price:price))),child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Row(children:[Expanded(child:Text('전국 돈가',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800))),Icon(Icons.chevron_right)]),
      const SizedBox(height:8),
      Text('${_comma(price['price'])}',style:const TextStyle(fontSize:40,height:1.05,fontWeight:FontWeight.w900)),
      const Text('원/kg',style:TextStyle(fontSize:14,color:Colors.black54)),
      const SizedBox(height:10),
      Text('전일 대비 ${change>0?'+':''}${_comma(change)}원 (${price['changePct']}%)',style:TextStyle(fontWeight:FontWeight.w700,color:down?Colors.blue:Colors.red)),
      const SizedBox(height:5),
      Text('${_date(price['date'])} · ${price['source']}',style:const TextStyle(fontSize:12,color:Colors.black54)),
    ]))));
  }
}

class PriceDetailPage extends StatelessWidget {
  final Map<String,dynamic> price;
  const PriceDetailPage({super.key,required this.price});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('전국 돈가')),body:ListView(padding:const EdgeInsets.all(16),children:[
    _PriceCard(price:price),const SizedBox(height:12),
    const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('기준: 전국 · 탕박 · 등외 제외 · 제주 제외\n새 확정 돈가가 확인되면 앱·위젯이 같은 스냅샷으로 갱신되도록 데이터 계층을 연결합니다.'))),
  ]));
}

class _MarketCard extends StatelessWidget {
  final Map<String,dynamic> item;
  const _MarketCard({required this.item});
  static const labels={'usd_krw':'원/달러 환율','wti':'WTI','corn':'옥수수','soybean_meal':'대두박','soybean':'대두','wheat':'소맥'};
  static const icons={'usd_krw':Icons.currency_exchange,'wti':Icons.oil_barrel_outlined,'corn':Icons.grass,'soybean_meal':Icons.eco_outlined,'soybean':Icons.spa_outlined,'wheat':Icons.agriculture_outlined};
  @override Widget build(BuildContext context){
    final n=item['name'] as String; final pct=(item['changePct'] as num).toDouble();
    return Card(child:Padding(padding:const EdgeInsets.all(14),child:Stack(children:[
      Align(alignment:Alignment.topRight,child:Icon(icons[n]??Icons.show_chart,size:34,color:Colors.black12)),
      Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(labels[n]??n,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w800)),const Spacer(),
        FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text('${item['value']}',style:const TextStyle(fontSize:27,fontWeight:FontWeight.w900))),
        Text('${item['unit']}',style:const TextStyle(fontSize:11,color:Colors.black54)),const SizedBox(height:5),
        Text('${pct>0?'+':''}${pct.toStringAsFixed(2)}%',style:TextStyle(fontWeight:FontWeight.w800,color:pct<0?Colors.blue:Colors.red)),
      ])
    ])));
  }
}

class _NavCard extends StatelessWidget{
  final IconData icon; final String title; final String subtitle; final VoidCallback? onTap;
  const _NavCard({required this.icon,required this.title,required this.subtitle,this.onTap});
  @override Widget build(BuildContext context)=>Card(child:ListTile(onTap:onTap,leading:Icon(icon),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right)));
}

String _comma(dynamic value){final s=value.toString(); final neg=s.startsWith('-'); final raw=neg?s.substring(1):s; final b=StringBuffer(); for(var i=0;i<raw.length;i++){if(i>0&&(raw.length-i)%3==0)b.write(',');b.write(raw[i]);}return '${neg?'-':''}$b';}
String _date(dynamic value){final s=value.toString();if(s.length!=8)return s;return '${s.substring(0,4)}.${s.substring(4,6)}.${s.substring(6,8)}';}
