import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/get_start/login_page.dart';
import 'package:pawlytics/views/donors/donor navigation func/RoutePage.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final authState = snapshot.data!;
        final session = authState.session; // <-- use the stream's session

        if (session == null) {
          // signed out
          return const LoginPage();
        }

        // signed in (you can branch by role inside your landing page if needed)
        return const RoutePage();
      },
    );
  }
}
