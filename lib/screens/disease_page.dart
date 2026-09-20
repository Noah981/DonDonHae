import 'package:flutter/material.dart';
import '../data/disease_repository.dart';
import '../models/disease_event.dart';
class DiseasePage extends StatefulWidget{const DiseasePage({super.key});@override State<DiseasePage> createState()=>_DiseasePageState();}
class _DiseasePageState extends State<DiseasePage>{
 final repo=DiseaseRepository(); String filter='전체'; bool domestic=true;
 @override Widget build(BuildContext context){return Scaffold(appBar:AppBar(title:const Text('질병 정보')),body:FutureBuilder<List<DiseaseEvent>>(future:repo.load(),builder:(context,snapshot){
  if(snapshot.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
  if(snapshot.hasError)return const Center(child:Text('질병 정보를 불러오지 못했습니다.'));
  final events=(snapshot.data??const <DiseaseEvent>[]).where((e)=>e.domestic==domestic&&(filter=='전체'||e.disease.contains(filter))).toList();
  return ListView(padding:const EdgeInsets.all(16),children:[
   SegmentedButton<bool>(segments:const [ButtonSegment(value:true,label:Text('국내')),ButtonSegment(value:false,label:Text('해외'))],selected:{domestic},onSelectionChanged:(v)=>setState(()=>domestic=v.first)),
   const SizedBox(height:12),
   Wrap(spacing:8,children:['전체','ASF','구제역','PED','PRRS'].map((x)=>ChoiceChip(label:Text(x),selected:filter==x,onSelected:(_)=>setState(()=>filter=x))).toList()),
   const SizedBox(height:20),
   const Card(child:Padding(padding:EdgeInsets.all(24),child:Column(children:[Icon(Icons.map_outlined,size:54),SizedBox(height:10),Text('대한민국 질병 지도',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),SizedBox(height:6),Text('공식 행정경계 벡터 지도를 연결하는 영역입니다.',textAlign:TextAlign.center)]))),
   const SizedBox(height:14),Text('최근 발생 ${events.length}건',style:const TextStyle(fontWeight:FontWeight.w800)),
   if(events.isEmpty)const Padding(padding:EdgeInsets.symmetric(vertical:24),child:Center(child:Text('현재 저장된 공식 발생 데이터가 없습니다.'))),
   ...events.take(20).map((e)=>ListTile(contentPadding:EdgeInsets.zero,title:Text(e.disease),subtitle:Text('${e.region} · ${e.date}')))
  ]);
 }));}
}