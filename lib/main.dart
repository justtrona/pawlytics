import 'package:flutter/material.dart';
import 'package:pawlytics/views/get_start/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/route/route.dart' as route;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qohuvrnpnxzmmhcrtzjf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFvaHV2cm5wbnh6bW1oY3J0empmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2MzMxOTgsImV4cCI6MjA2OTIwOTE5OH0.PFEyJxReGbp8sUV0Y8PViUkRvHVUREx8Hlid3D2k3aw',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawlytics',
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      onGenerateRoute: route.controller,
      initialRoute: route.landing,
    );
  }
}
