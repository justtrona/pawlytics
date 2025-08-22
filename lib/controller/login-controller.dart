import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/auth/auth_service.dart';
import 'package:pawlytics/route/route.dart' as route;

class LoginController {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isHidden = true; 
  final authService = AuthService();

  void togglePasswordVisibility(VoidCallback updateState) {
    updateState();
  }

  Future<void> performLogin(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      final AuthResponse response = await authService
          .signInWithEmailAndPassword(email, password);

      if (response.user != null) {
        final user = response.user!;

        if (user.emailConfirmedAt == null) {

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please confirm your email before logging in."),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
        
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login successful!"),
              backgroundColor: Colors.green,
            ),
          );

        
          Navigator.pushReplacementNamed(context, route.adminDashboard);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login failed. Please check your credentials."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red),
      );
    }
  }

  // ================= VALIDATORS =================

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email Address is required.';
    }
    if (!RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    ).hasMatch(value)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // ================= CLEANUP =================
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
