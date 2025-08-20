import 'package:pawlytics/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/route/route.dart' as route;

class RegistrationCcontroller {
  final formKey = GlobalKey<FormState>();
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();
  bool isHidden = true;
  bool isHiddenConfirm = true;

  final authService = AuthService();

  Future<void> performRegistration(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      try {
        final fullName =
            "${firstnameController.text.trim()} ${lastnameController.text.trim()}";

        final AuthResponse respone = await authService
            .signUpWithEmailAndPassword(
              emailController.text.trim(),
              passwordController.text.trim(),
              fullName,
            );

        if (respone.user != null) {
          Navigator.pushNamed(context, route.login);
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed. Try Again!')),
        );
      }
    }
  }

  // validators

  String? validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required. ';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email Address is required.';
    }
    if (!RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
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

  String? validatedConfirmPasswor(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm Password is required.';
    }
    if (value != passwordController.text) {
      return 'Password do not match.';
    }
    return null;
  }

  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmpasswordController.dispose();
  }
}
