import 'package:flutter/material.dart';
import 'package:pawlytics/views/get_start/get_started.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawlytics',
      debugShowCheckedModeBanner: false,
      home: const GetStartedPage(),
    );
  }
}
