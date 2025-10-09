// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pawlytics/route/route.dart' as route;
import 'package:pawlytics/views/admin/controllers/operational-expense-controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dtzfywsdjrwgarrlmprc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR0emZ5d3NkanJ3Z2FycmxtcHJjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU3Mzg1OTUsImV4cCI6MjA3MTMxNDU5NX0.dt_hTFdgVfksdjcS9cZ2xX7KtDFivF5q7Wm2fDRK3GA',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Single shared instance for the whole app
        ChangeNotifierProvider<OperationalExpenseController>(
          create: (_) => OperationalExpenseController()..loadAllocations(),
        ),
      ],
      child: MaterialApp(
        title: 'Pawlytics',
        debugShowCheckedModeBanner: false,
        onGenerateRoute: route.controller,
      ),
    );
  }
}
