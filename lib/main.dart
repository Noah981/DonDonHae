import 'package:flutter/material.dart';

void main() => runApp(const DonDonHaeApp());

class DonDonHaeApp extends StatelessWidget {
  const DonDonHaeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '돈돈해',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFE85D75)),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('돈돈해')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('양돈의 오늘을 든든하게', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Card(child: ListTile(leading: Icon(Icons.pets), title: Text('돈돈해 WORK 3'), subtitle: Text('복구 빌드 · Android'))),
            Card(child: ListTile(leading: Icon(Icons.monitor_heart), title: Text('질병 정보'), subtitle: Text('국내·국외 양돈 질병 정보'))),
            Card(child: ListTile(leading: Icon(Icons.show_chart), title: Text('돈가 정보'), subtitle: Text('전국 돈가 흐름'))),
          ]),
        ),
      ),
    );
  }
}
