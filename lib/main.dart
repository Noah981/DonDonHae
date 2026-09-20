import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
void main()=>runApp(const DonDonHaeApp());
class DonDonHaeApp extends StatelessWidget{const DonDonHaeApp({super.key});@override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'돈돈해',theme:ThemeData(useMaterial3:true,colorSchemeSeed:const Color(0xff2d8b57),scaffoldBackgroundColor:const Color(0xfff6f7f8)),home:const Dashboard());}
class Dashboard extends StatefulWidget{const Dashboard({super.key});@override State<Dashboard> createState()=>_DashboardState();}
class _DashboardState extends State<Dashboard>{
Map<String,dynamic>? price;List<dynamic> markets=[];
@override void initState(){super.initState();load();}
Future<void> load()async{final p=jsonDecode(await rootBundle.loadString('assets/data/pig-price.json')) as Map<String,dynamic>;final m=jsonDecode(await rootBundle.loadString('assets/data/platform.json')) as Map<String,dynamic>;if(mounted)setState((){price=p;markets=m['markets'] as List;});}
String label(String x)=>const{'usd_krw':'원/달러','wti':'WTI','corn':'옥수수','soybean_meal':'대두박','soybean':'대두','wheat':'소맥'}[x]??x;
IconData icon(String x)=>x=='wti'?Icons.oil_barrel_outlined:x=='usd_krw'?Icons.currency_exchange:x=='corn'?Icons.grass:x=='wheat'?Icons.agriculture_outlined:Icons.eco_outlined;
@override Widget build(BuildContext context){final p=price;return Scaffold(appBar:AppBar(title:Row(children:[Image.asset('assets/images/dondonhae_symbol.png',width:34,height:34),const SizedBox(width:9),const Text('돈돈해',style:TextStyle(fontWeight:FontWeight.w900))])),body:p==null?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.fromLTRB(16,8,16,30),children:[
const Text('양돈의 오늘을 든든하게',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:14),
Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('전국 돈가',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)),const SizedBox(height:8),Text('${p!['price']} 원/kg',style:const TextStyle(fontSize:36,fontWeight:FontWeight.w900)),Text('전일 대비 ${p['change']}원 (${p['changePct']}%)'),const SizedBox(height:6),Text('${p['date']} · ${p['source']}',style:const TextStyle(color:Colors.black54))]))),
const SizedBox(height:18),const Text('국제정세 & 원료 동향',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:10),
GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:markets.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.12),itemBuilder:(c,i){final e=markets[i] as Map<String,dynamic>;final pct=(e['changePct'] as num?)??0;return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(icon(e['name']),size:20),const Spacer(),Text(label(e['name']),style:const TextStyle(fontWeight:FontWeight.w800))]),const Spacer(),FittedBox(child:Text('${e['value']} ${e['unit']}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900))),Text('${pct>0?'+':''}${e['changePct']}%',style:TextStyle(fontWeight:FontWeight.w800,color:pct>0?Colors.red:Colors.blue)),Text('${e['date']}',style:const TextStyle(fontSize:10,color:Colors.black45))])));}),
const SizedBox(height:14),const Card(child:ListTile(leading:Icon(Icons.coronavirus_outlined),title:Text('질병 정보',style:TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('공식 발생정보와 지역별 상황을 확인하세요.'),trailing:Icon(Icons.chevron_right))),
const SizedBox(height:10),const Card(child:ListTile(leading:Icon(Icons.cloud_outlined),title:Text('날씨와 농장 대응',style:TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('지역 기상정보를 농장 관리에 맞게 확인하세요.'),trailing:Icon(Icons.chevron_right))),
]));}}
