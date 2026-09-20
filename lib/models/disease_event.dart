class DiseaseEvent {
  final String id,disease,country,region,date,sourceUrl;
  final double? latitude,longitude;
  final bool domestic;
  const DiseaseEvent({required this.id,required this.disease,required this.country,required this.region,required this.date,required this.sourceUrl,required this.domestic,this.latitude,this.longitude});
  factory DiseaseEvent.fromJson(Map<String,dynamic> j)=>DiseaseEvent(id:'${j['id']??''}',disease:'${j['disease']??''}',country:'${j['country']??''}',region:'${j['region']??''}',date:'${j['date']??''}',sourceUrl:'${j['sourceUrl']??''}',domestic:j['domestic']==true,latitude:(j['latitude'] as num?)?.toDouble(),longitude:(j['longitude'] as num?)?.toDouble());
}
