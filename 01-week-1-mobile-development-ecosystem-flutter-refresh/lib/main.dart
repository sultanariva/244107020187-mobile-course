import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.person, size: 72),
            SizedBox(height: 16),
            Text('Sultan Nashira Ariva', style: TextStyle(fontSize: 24)),
            Text('sultannanda55@gmail.com', style: TextStyle(fontSize: 16)),
            Text('244107020187'),
            Text('Politeknik Negeri Malang'),
            Text('Pemrograman Mobile — Minggu 1'),
          ]),
        ),
      ),
    );
  }
}